"""Private face-analysis sidecar. Expose only to the Laravel backend."""

import base64
import os
import tempfile

import cv2
import mediapipe as mp
import numpy as np
from deepface import DeepFace
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel

app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)
MODEL = "Facenet512"
MODEL_VERSION = "Facenet512-v1"
MAX_IMAGE_BYTES = 2_000_000
MAX_VIDEO_BYTES = 5_000_000
# Conservative starting threshold; validate against the actual employee/device set.
MAX_COSINE_DISTANCE = 0.25


class FaceRequest(BaseModel):
    image_b64: str
    reference_embedding: list[float] | None = None
    model_version: str | None = None


class VideoRequest(BaseModel):
    video_b64: str
    reference_embedding: list[float] | list[list[float]] | None = None
    model_version: str | None = None
    side: str | None = None


class AnglesRequest(BaseModel):
    images_b64: list[str]


def _video_frames(encoded: str, step: float = .28) -> list[tuple[float, np.ndarray]]:
    try:
        raw = base64.b64decode(encoded, validate=True)
        if not raw or len(raw) > MAX_VIDEO_BYTES:
            raise ValueError('invalid video size')
    except (ValueError, TypeError) as exc:
        raise HTTPException(422, 'Vidéo invalide ou trop volumineuse.') from exc
    path = None
    try:
        with tempfile.NamedTemporaryFile(suffix='.mp4', delete=False) as file:
            path = file.name
            file.write(raw)
        capture = cv2.VideoCapture(path)
        if not capture.isOpened():
            raise ValueError('invalid video')
        fps = capture.get(cv2.CAP_PROP_FPS)
        count = capture.get(cv2.CAP_PROP_FRAME_COUNT)
        duration = count / fps if fps > 0 else 0
        if duration < 3.5 or duration > 10 or count > 600:
            raise ValueError('invalid duration')
        frames = []
        for second in np.arange(.35, duration - .2, step):
            capture.set(cv2.CAP_PROP_POS_MSEC, float(second * 1000))
            ok, frame = capture.read()
            if ok and min(frame.shape[:2]) >= 240:
                frames.append((float(second / duration), frame))
        capture.release()
        if len(frames) < 10:
            raise ValueError('insufficient frames')
        return frames
    except ValueError as exc:
        raise HTTPException(422, 'Séquence vidéo trop courte ou invalide.') from exc
    finally:
        if path:
            os.unlink(path)


def _decoded_image(encoded: str) -> np.ndarray:
    try:
        raw = base64.b64decode(encoded, validate=True)
        if not raw or len(raw) > MAX_IMAGE_BYTES:
            raise ValueError('invalid size')
        image = cv2.imdecode(np.frombuffer(raw, dtype=np.uint8), cv2.IMREAD_COLOR)
        if image is None or min(image.shape[:2]) < 240:
            raise ValueError('invalid image')
        return image
    except (ValueError, TypeError) as exc:
        raise HTTPException(422, 'Image illisible ou trop volumineuse.') from exc


def _landmarker(blendshapes: bool = False):
    return mp.tasks.vision.FaceLandmarker.create_from_options(
        mp.tasks.vision.FaceLandmarkerOptions(
            base_options=mp.tasks.BaseOptions(model_asset_path='/app/face_landmarker.task'),
            running_mode=mp.tasks.vision.RunningMode.IMAGE, num_faces=2,
            output_face_blendshapes=blendshapes))


def _face_geometry(detector, frame: np.ndarray):
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    found = detector.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb))
    if len(found.face_landmarks) != 1:
        raise HTTPException(422, 'Un seul visage doit être visible dans la caméra.')
    marks = found.face_landmarks[0]
    left, right, nose = marks[33].x, marks[263].x, marks[1].x
    width = abs(right - left)
    if width < .04:
        raise HTTPException(422, 'Rapprochez votre visage de la caméra.')
    yaw = (nose - (left + right) / 2) / width
    blink = 0.0
    if found.face_blendshapes:
        scores = {item.category_name: item.score for item in found.face_blendshapes[0]}
        blink = (scores.get('eyeBlinkLeft', 0.0) + scores.get('eyeBlinkRight', 0.0)) / 2
    return yaw, blink


def _cosine_distance(a: list[float], b: list[float]) -> float:
    first, second = np.asarray(a, dtype=np.float64), np.asarray(b, dtype=np.float64)
    if first.shape != second.shape or not np.isfinite(first).all() or not np.isfinite(second).all():
        raise HTTPException(422, 'Profil facial invalide.')
    norm = float(np.linalg.norm(first) * np.linalg.norm(second))
    if norm <= 0:
        raise HTTPException(422, 'Profil facial invalide.')
    return 1.0 - float(np.dot(first, second) / norm)


def _embedding_from_landmarks(image: np.ndarray) -> list[float]:
    """Use the same landmark crop at enrollment and verification.

    Enrollment is approved in person; video blink detection is performed at
    every punch. A passive single-photo spoof score is not used as a gate here.
    """
    with _landmarker() as detector:
        rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        found = detector.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb))
    if len(found.face_landmarks) != 1:
        raise HTTPException(422, 'Un seul visage doit être visible dans la caméra.')
    marks = found.face_landmarks[0]
    height, width = image.shape[:2]
    xs = [point.x * width for point in marks]
    ys = [point.y * height for point in marks]
    left, right, top, bottom = min(xs), max(xs), min(ys), max(ys)
    span = max(right - left, bottom - top) * 1.35
    cx, cy = (left + right) / 2, (top + bottom) / 2
    x1, y1 = max(0, int(cx - span / 2)), max(0, int(cy - span / 2))
    x2, y2 = min(width, int(cx + span / 2)), min(height, int(cy + span / 2))
    crop = image[y1:y2, x1:x2]
    if min(crop.shape[:2]) < 160:
        raise HTTPException(422, 'Rapprochez votre visage de la caméra.')
    try:
        result = DeepFace.represent(img_path=crop, model_name=MODEL,
                                    detector_backend='skip', enforce_detection=False,
                                    align=False)
        if len(result) != 1 or len(result[0]['embedding']) < 100:
            raise ValueError('invalid embedding')
        return result[0]['embedding']
    except Exception as exc:
        raise HTTPException(422, 'Profil du visage illisible. Réessayez avec un meilleur éclairage.') from exc


def _poses(frames: list[tuple[float, np.ndarray]]) -> list[tuple[float, float, np.ndarray]]:
    options = mp.tasks.vision.FaceLandmarkerOptions(
        base_options=mp.tasks.BaseOptions(model_asset_path='/app/face_landmarker.task'),
        running_mode=mp.tasks.vision.RunningMode.IMAGE, num_faces=2)
    results = []
    with mp.tasks.vision.FaceLandmarker.create_from_options(options) as detector:
        for time, frame in frames:
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            found = detector.detect(mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb))
            if len(found.face_landmarks) != 1:
                raise HTTPException(422, 'Gardez un seul visage visible pendant toute la séquence.')
            marks = found.face_landmarks[0]
            # Nose position relative to the outer eye corners is a simple pose cue.
            left, right, nose = marks[33].x, marks[263].x, marks[1].x
            width = abs(right - left)
            if width < .04:
                raise HTTPException(422, 'Visage trop petit dans la caméra.')
            yaw = (nose - (left + right) / 2) / width
            results.append((time, yaw, frame))
    return results


def _sequence(video: str, enrollment: bool, side: str | None = None):
    poses = _poses(_video_frames(video))
    front = [frame for t, yaw, frame in poses if t < .30 and abs(yaw) < .14]
    if not front:
        raise HTTPException(422, 'Commencez la séquence de face.')
    middle = [yaw for t, yaw, _ in poses if .38 < t < .63]
    if not middle:
        raise HTTPException(422, 'Mouvement de tête non détecté.')
    if enrollment:
        end = [yaw for t, yaw, _ in poses if t > .72]
        if not end or not any(y > .20 for y in middle + end) or not any(y < -.20 for y in middle + end):
            raise HTTPException(422, 'Tournez la tête des deux côtés pendant l’inscription.')
        if np.median(middle) * np.median(end) >= 0:
            raise HTTPException(422, 'Montrez les deux profils dans l’ordre demandé.')
    else:
        # In an unmirrored front-camera recording, turning toward one's left
        # moves the nose toward the image's right side.
        expected = 1 if side == 'left' else -1
        final = [yaw for t, yaw, _ in poses if t > .72]
        if not any(y * expected > .20 for y in middle) or not any(abs(y) < .14 for y in final):
            raise HTTPException(422, 'Mouvement demandé non détecté. Réessayez.')
    # Passive presentation-attack detection and identity matching use a frontal frame.
    chosen = front[len(front) // 2]
    ok, jpeg = cv2.imencode('.jpg', chosen, [cv2.IMWRITE_JPEG_QUALITY, 88])
    if not ok:
        raise HTTPException(422, 'Image du visage illisible.')
    frontal = _embedding(base64.b64encode(jpeg).decode())
    if not enrollment:
        return frontal
    embeddings = [frontal]
    for sign in (-1, 1):
        candidates = [(abs(abs(yaw) - .19), frame) for _, yaw, frame in poses
                      if .13 < yaw * sign < .32]
        if not candidates:
            raise HTTPException(422, 'Profil gauche ou droit insuffisant. Réessayez.')
        side_frame = min(candidates, key=lambda item: item[0])[1]
        ok, jpeg = cv2.imencode('.jpg', side_frame, [cv2.IMWRITE_JPEG_QUALITY, 88])
        if not ok:
            raise HTTPException(422, 'Profil illisible.')
        embeddings.append(_embedding(base64.b64encode(jpeg).decode(), passive_check=False))
    return embeddings


def _authorized(token: str | None) -> None:
    import hmac

    expected = os.environ.get("FACE_SERVICE_TOKEN", "")
    if not expected or not token or not hmac.compare_digest(token, expected):
        raise HTTPException(401, "Unauthorized")


def _embedding(encoded: str, passive_check: bool = True) -> list[float]:
    try:
        raw = base64.b64decode(encoded, validate=True)
        if not raw or len(raw) > MAX_IMAGE_BYTES:
            raise ValueError("invalid image size")
        image = cv2.imdecode(np.frombuffer(raw, dtype=np.uint8), cv2.IMREAD_COLOR)
        if image is None or min(image.shape[:2]) < 240:
            raise ValueError("invalid image")
        faces = DeepFace.extract_faces(img_path=image, detector_backend="opencv",
                                       enforce_detection=True, anti_spoofing=passive_check)
        if len(faces) != 1 or (passive_check and not faces[0].get("is_real", False)):
            raise ValueError("one live face is required")
        result = DeepFace.represent(img_path=image, model_name=MODEL,
                                    detector_backend="opencv", enforce_detection=True,
                                    anti_spoofing=passive_check, max_faces=2)
        if len(result) != 1:
            raise ValueError("one face is required")
        return result[0]["embedding"]
    except (ValueError, TypeError) as exc:
        raise HTTPException(422, "Visage unique et vivant non détecté.") from exc
    except Exception as exc:
        # Never expose raw model or image data in the API response.
        raise HTTPException(422, "Analyse du visage impossible.") from exc


@app.post("/enroll")
def enroll(data: FaceRequest, x_face_token: str | None = Header(default=None)):
    _authorized(x_face_token)
    return {"embedding": _embedding(data.image_b64), "model_version": MODEL_VERSION}


@app.post("/verify")
def verify(data: FaceRequest, x_face_token: str | None = Header(default=None)):
    _authorized(x_face_token)
    if data.model_version != MODEL_VERSION or not data.reference_embedding:
        raise HTTPException(422, "Profil facial incompatible.")
    current = np.asarray(_embedding(data.image_b64), dtype=np.float64)
    reference = np.asarray(data.reference_embedding, dtype=np.float64)
    if current.shape != reference.shape or not np.isfinite(reference).all():
        raise HTTPException(422, "Profil facial invalide.")
    norm = float(np.linalg.norm(current) * np.linalg.norm(reference))
    if norm <= 0:
        raise HTTPException(422, "Profil facial invalide.")
    distance = 1.0 - float(np.dot(current, reference) / norm)
    return {"matched": distance <= MAX_COSINE_DISTANCE,
            "model_version": MODEL_VERSION}


@app.post('/enroll-video')
def enroll_video(data: VideoRequest, x_face_token: str | None = Header(default=None)):
    _authorized(x_face_token)
    return {'embeddings': _sequence(data.video_b64, enrollment=True),
            'model_version': 'Facenet512-video-v1'}


@app.post('/verify-video')
def verify_video(data: VideoRequest, x_face_token: str | None = Header(default=None)):
    _authorized(x_face_token)
    if data.side not in ('left', 'right') or data.model_version not in (MODEL_VERSION, 'Facenet512-video-v1'):
        raise HTTPException(422, 'Défi ou profil facial incompatible.')
    current = np.asarray(_sequence(data.video_b64, enrollment=False, side=data.side), dtype=np.float64)
    references = data.reference_embedding
    if not isinstance(references, list) or not references:
        raise HTTPException(422, 'Profil facial invalide.')
    if isinstance(references[0], (int, float)):
        references = [references]
    distances = []
    for item in references:
        reference = np.asarray(item, dtype=np.float64)
        if current.shape != reference.shape or not np.isfinite(reference).all():
            raise HTTPException(422, 'Profil facial invalide.')
        norm = float(np.linalg.norm(current) * np.linalg.norm(reference))
        if norm <= 0:
            raise HTTPException(422, 'Profil facial invalide.')
        distances.append(1.0 - float(np.dot(current, reference) / norm))
    return {'matched': min(distances) <= MAX_COSINE_DISTANCE,
            'model_version': data.model_version}


@app.post('/enroll-angles')
def enroll_angles(data: AnglesRequest, x_face_token: str | None = Header(default=None)):
    _authorized(x_face_token)
    if len(data.images_b64) != 3:
        raise HTTPException(422, 'Capturez une image de face et une de chaque profil.')
    images = [_decoded_image(item) for item in data.images_b64]
    with _landmarker() as detector:
        yaw = [_face_geometry(detector, image)[0] for image in images]
    if abs(yaw[0]) > .16:
        raise HTTPException(422, 'Regardez la caméra pour la première capture.')
    if abs(yaw[1]) < .12 or abs(yaw[2]) < .12 or yaw[1] * yaw[2] >= 0:
        raise HTTPException(422, 'Tournez légèrement la tête de chaque côté et reprenez les profils.')
    embeddings = [_embedding_from_landmarks(images[0])]
    for image in images[1:]:
        embedding = _embedding_from_landmarks(image)
        if _cosine_distance(embeddings[0], embedding) > .40:
            raise HTTPException(422, 'Les trois captures doivent montrer la même personne.')
        embeddings.append(embedding)
    return {'embeddings': embeddings, 'model_version': 'Facenet512-angles-v2'}


@app.post('/verify-front-video')
def verify_front_video(data: VideoRequest, x_face_token: str | None = Header(default=None)):
    _authorized(x_face_token)
    if data.model_version not in (MODEL_VERSION, 'Facenet512-video-v1',
                                  'Facenet512-angles-v1', 'Facenet512-angles-v2'):
        raise HTTPException(422, 'Profil facial incompatible.')
    frames = _video_frames(data.video_b64, step=.10)
    with _landmarker(blendshapes=True) as detector:
        observations = []
        for _, frame in frames:
            pose, blink = _face_geometry(detector, frame)
            observations.append((abs(pose), blink, frame))
    frontal = [(pose, blink, frame) for pose, blink, frame in observations if pose < .22]
    if len(frontal) < len(observations) * .7:
        raise HTTPException(422, 'Regardez la caméra pendant le pointage.')
    blinks = [blink for _, blink, _ in frontal]
    peak = max(range(len(blinks)), key=lambda index: blinks[index])
    if not (blinks[peak] > .38 and peak > 0 and peak < len(blinks) - 1
            and min(blinks[:peak]) < .23 and min(blinks[peak + 1:]) < .23):
        raise HTTPException(422, 'Clignement des yeux non détecté. Réessayez face à la caméra.')
    chosen = min(frontal, key=lambda item: item[0] + item[1])[2]
    ok, jpeg = cv2.imencode('.jpg', chosen, [cv2.IMWRITE_JPEG_QUALITY, 88])
    if not ok:
        raise HTTPException(422, 'Image du visage illisible.')
    if data.model_version == 'Facenet512-angles-v2':
        current = _embedding_from_landmarks(chosen)
    else:
        current = _embedding(base64.b64encode(jpeg).decode(), passive_check=False)
    references = data.reference_embedding
    if not isinstance(references, list) or not references:
        raise HTTPException(422, 'Profil facial invalide.')
    if isinstance(references[0], (int, float)):
        references = [references]
    return {'matched': min(_cosine_distance(current, item) for item in references) <= MAX_COSINE_DISTANCE,
            'model_version': data.model_version}
