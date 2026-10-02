"""Manual staging smoke test: a still face replayed as video must fail motion checks."""

import base64
import urllib.request

import cv2
import numpy as np
from fastapi import HTTPException

from main import _sequence, verify_front_video, VideoRequest
import os

url = 'https://raw.githubusercontent.com/serengil/deepface/refs/heads/master/tests/unit/dataset/img1.jpg'
image = cv2.imdecode(np.frombuffer(urllib.request.urlopen(url, timeout=15).read(), np.uint8), cv2.IMREAD_COLOR)
if image is None:
    raise RuntimeError('Sample image unavailable')
image = cv2.resize(image, (480, 480))
path = '/tmp/static-replay.mp4'
writer = cv2.VideoWriter(path, cv2.VideoWriter_fourcc(*'mp4v'), 8, (480, 480))
for _ in range(48):
    writer.write(image)
writer.release()
with open(path, 'rb') as file:
    video = base64.b64encode(file.read()).decode()
try:
    _sequence(video, enrollment=False, side='left')
except HTTPException as error:
    if error.status_code != 422:
        raise
    print('static_replay_rejected', error.detail)
else:
    raise AssertionError('Static replay was accepted')

try:
    verify_front_video(VideoRequest(video_b64=video, reference_embedding=[0.1] * 512,
                                    model_version='Facenet512-v1'),
                       x_face_token=os.environ['FACE_SERVICE_TOKEN'])
except HTTPException as error:
    if error.status_code != 422:
        raise
    print('static_replay_front_rejected', error.detail)
else:
    raise AssertionError('Static frontal replay was accepted')
