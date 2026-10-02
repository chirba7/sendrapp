<?php

namespace App\Http\Controllers;

use App\Models\AttendanceFaceProfile;
use App\Models\AttendanceFaceProof;
use App\Services\AttendanceFaceService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

class AttendanceFaceController extends Controller
{
    public function challenge(Request $request)
    {
        $user = $request->user();
        abort_unless($user->is_enabled && !$user->deleted
            && $user->attendanceEnrollment()->where('status', 'approved')->exists(), 403);
        abort_unless(AttendanceFaceProfile::where('user_id', $user->id)->exists(), 403);
        $id = (string) Str::uuid();
        $side = random_int(0, 1) === 0 ? 'left' : 'right';
        Cache::put('attendance-face-challenge:'.$user->id.':'.$id, $side, now()->addMinutes(2));
        return response()->json(['challenge_id' => $id, 'side' => $side]);
    }

    public function enrollAngles(Request $request, AttendanceFaceService $faces)
    {
        set_time_limit(120);
        $user = $request->user();
        abort_if($user->deleted, 403, 'Compte archivé.');
        abort_unless($user->attendanceEnrollment?->status === 'pending', 403);
        abort_if(AttendanceFaceProfile::where('user_id', $user->id)->exists(), 409,
            'Un visage est déjà associé à ce compte.');
        $data = $request->validate([
            'images_b64' => ['required', 'array', 'size:3'],
            'images_b64.*' => ['required', 'string', 'max:2700000'],
        ]);
        $result = $faces->analyze('enroll-angles', $data);
        $embeddings = $result['embeddings'] ?? null;
        abort_unless(is_array($embeddings) && count($embeddings) === 3
            && collect($embeddings)->every(fn ($v) => is_array($v) && count($v) > 100)
            && ($result['model_version'] ?? null) === 'Facenet512-angles-v2',
            503, 'Réponse du service facial invalide.');
        AttendanceFaceProfile::create([
            'user_id' => $user->id,
            'encrypted_embedding' => Crypt::encryptString(json_encode($embeddings)),
            'model_version' => $result['model_version'],
        ]);
        return response()->json(['face_enrolled' => true]);
    }

    public function verifyFrontVideo(Request $request, AttendanceFaceService $faces)
    {
        set_time_limit(120);
        $user = $request->user();
        abort_unless($user->is_enabled && !$user->deleted
            && $user->attendanceEnrollment()->where('status', 'approved')->exists(), 403);
        $data = $request->validate([
            'video_b64' => ['required', 'string', 'max:7000000'],
            'challenge_id' => ['required', 'uuid'],
            'purpose' => ['required', 'in:arrival,departure'],
            'request_id' => ['required', 'uuid'],
        ]);
        $profile = AttendanceFaceProfile::where('user_id', $user->id)->first();
        abort_unless($profile, 403, 'Enregistrez votre visage avec votre responsable.');
        abort_if(AttendanceFaceProof::where('user_id', $user->id)
            ->where('request_id', $data['request_id'])->exists(), 409);
        $challenge = Cache::pull('attendance-face-challenge:'.$user->id.':'.$data['challenge_id']);
        abort_unless(in_array($challenge, ['left', 'right'], true), 422,
            'Défi expiré. Recommencez la capture.');
        $result = $faces->analyze('verify-front-video', [
            'video_b64' => $data['video_b64'],
            'reference_embedding' => json_decode(Crypt::decryptString($profile->encrypted_embedding), true),
            'model_version' => $profile->model_version,
        ]);
        abort_unless(($result['matched'] ?? false) === true, 403,
            'Le visage ne correspond pas au compte connecté.');
        $proof = AttendanceFaceProof::create([
            'id' => (string) Str::uuid(), 'user_id' => $user->id,
            'purpose' => $data['purpose'], 'request_id' => $data['request_id'],
            'expires_at' => now()->addMinutes(2),
        ]);
        return response()->json(['face_proof_id' => $proof->id, 'expires_at' => $proof->expires_at]);
    }

    public function enrollVideo(Request $request, AttendanceFaceService $faces)
    {
        abort_if(config('attendance_face.angles_required'), 410,
            'Mettez à jour l’application pour capturer chaque angle à votre rythme.');
        set_time_limit(120);
        $user = $request->user();
        abort_if($user->deleted, 403, 'Compte archivé.');
        abort_unless($user->attendanceEnrollment?->status === 'pending', 403);
        abort_if(AttendanceFaceProfile::where('user_id', $user->id)->exists(), 409,
            'Un visage est déjà associé à ce compte.');
        $data = $request->validate(['video_b64' => ['required', 'string', 'max:7000000']]);
        $result = $faces->analyze('enroll-video', $data);
        $embeddings = $result['embeddings'] ?? null;
        abort_unless(is_array($embeddings) && count($embeddings) === 3
            && collect($embeddings)->every(fn ($v) => is_array($v) && count($v) > 100)
            && ($result['model_version'] ?? null) === 'Facenet512-video-v1',
            503, 'Réponse du service facial invalide.');
        AttendanceFaceProfile::create([
            'user_id' => $user->id,
            'encrypted_embedding' => Crypt::encryptString(json_encode($embeddings)),
            'model_version' => $result['model_version'],
        ]);
        return response()->json(['face_enrolled' => true]);
    }

    public function verifyVideo(Request $request, AttendanceFaceService $faces)
    {
        abort_if(config('attendance_face.angles_required'), 410,
            'Mettez à jour l’application pour pointer de face.');
        set_time_limit(120);
        $user = $request->user();
        abort_unless($user->is_enabled && !$user->deleted
            && $user->attendanceEnrollment()->where('status', 'approved')->exists(), 403);
        $data = $request->validate([
            'video_b64' => ['required', 'string', 'max:7000000'],
            'challenge_id' => ['required', 'uuid'],
            'purpose' => ['required', 'in:arrival,departure'],
            'request_id' => ['required', 'uuid'],
        ]);
        $profile = AttendanceFaceProfile::where('user_id', $user->id)->first();
        abort_unless($profile, 403, 'Enregistrez votre visage avec votre responsable.');
        abort_if(AttendanceFaceProof::where('user_id', $user->id)
            ->where('request_id', $data['request_id'])->exists(), 409);
        $side = Cache::pull('attendance-face-challenge:'.$user->id.':'.$data['challenge_id']);
        abort_unless(in_array($side, ['left', 'right'], true), 422,
            'Défi expiré. Recommencez la capture.');
        $result = $faces->analyze('verify-video', [
            'video_b64' => $data['video_b64'],
            'side' => $side,
            'reference_embedding' => json_decode(Crypt::decryptString($profile->encrypted_embedding), true),
            'model_version' => $profile->model_version,
        ]);
        abort_unless(($result['matched'] ?? false) === true, 403,
            'Le visage ne correspond pas au compte connecté.');
        $proof = AttendanceFaceProof::create([
            'id' => (string) Str::uuid(), 'user_id' => $user->id,
            'purpose' => $data['purpose'], 'request_id' => $data['request_id'],
            'expires_at' => now()->addMinutes(2),
        ]);
        return response()->json(['face_proof_id' => $proof->id, 'expires_at' => $proof->expires_at]);
    }

    public function enroll(Request $request, AttendanceFaceService $faces)
    {
        abort_if(config('attendance_face.video_required'), 410,
            'Mettez à jour l’application pour enregistrer votre visage sous plusieurs angles.');
        $user = $request->user();
        abort_if($user->deleted, 403, 'Compte archivé.');
        $enrollment = $user->attendanceEnrollment;
        abort_unless($enrollment && $enrollment->status === 'pending', 403,
            'Un visage validé ne peut être remplacé que par un responsable.');
        abort_if(AttendanceFaceProfile::where('user_id', $user->id)->exists(), 409,
            'Un visage est déjà associé à ce compte.');
        $data = $request->validate(['image_b64' => ['required', 'string', 'max:2700000']]);
        $result = $faces->analyze('enroll', $data);
        abort_unless(is_array($result['embedding'] ?? null)
            && count($result['embedding']) > 100 && is_string($result['model_version'] ?? null),
            503, 'Réponse du service facial invalide.');
        AttendanceFaceProfile::create([
            'user_id' => $user->id,
            'encrypted_embedding' => Crypt::encryptString(json_encode($result['embedding'])),
            'model_version' => $result['model_version'],
        ]);
        return response()->json(['face_enrolled' => true]);
    }

    public function verify(Request $request, AttendanceFaceService $faces)
    {
        abort_if(config('attendance_face.video_required'), 410,
            'Mettez à jour l’application pour la vérification de vie.');
        $user = $request->user();
        abort_unless($user->is_enabled && !$user->deleted
            && $user->attendanceEnrollment()->where('status', 'approved')->exists(), 403);
        $data = $request->validate([
            'image_b64' => ['required', 'string', 'max:2700000'],
            'purpose' => ['required', 'in:arrival,departure'],
            'request_id' => ['required', 'uuid'],
        ]);
        $profile = AttendanceFaceProfile::where('user_id', $user->id)->first();
        abort_unless($profile, 403, 'Enregistrez votre visage avec votre responsable.');
        abort_if(AttendanceFaceProof::where('user_id', $user->id)
            ->where('request_id', $data['request_id'])->exists(), 409,
            'Cette tentative a déjà été vérifiée.');
        $result = $faces->analyze('verify', [
            'image_b64' => $data['image_b64'],
            'reference_embedding' => json_decode(Crypt::decryptString($profile->encrypted_embedding), true),
            'model_version' => $profile->model_version,
        ]);
        abort_unless(($result['matched'] ?? false) === true, 403,
            'Le visage ne correspond pas au compte connecté.');
        $proof = AttendanceFaceProof::create([
            'id' => (string) Str::uuid(), 'user_id' => $user->id,
            'purpose' => $data['purpose'], 'request_id' => $data['request_id'],
            'expires_at' => now()->addMinutes(2),
        ]);
        return response()->json(['face_proof_id' => $proof->id, 'expires_at' => $proof->expires_at]);
    }
}
