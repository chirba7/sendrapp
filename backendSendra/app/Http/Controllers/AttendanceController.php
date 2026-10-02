<?php

namespace App\Http\Controllers;

use App\Models\AttendanceAssignment;
use App\Models\AttendanceSession;
use App\Services\AttendanceService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Crypt;

class AttendanceController extends Controller
{
    private function authorizeEmployee(Request $request): void
    {
        abort_unless($request->user()->is_enabled && !$request->user()->deleted
            && $request->user()->attendanceEnrollment()->where('status', 'approved')->exists(),
            403, 'Inscription Pointage non approuvée.');
    }

    public function configuration(Request $request)
    {
        $this->authorizeEmployee($request);
        return response()->json([
            'assignment' => AttendanceAssignment::with('site')->where('user_id', $request->user()->id)
                ->where('active', true)->whereHas('site', fn ($q) => $q->where('active', true))->first(),
            'open_session' => AttendanceSession::with('site')->where('user_id', $request->user()->id)->whereNull('departed_at')->first(),
            'server_time' => now('UTC')->toIso8601String(),
        ]);
    }

    public function history(Request $request)
    {
        $this->authorizeEmployee($request);
        return AttendanceSession::with('site')->where('user_id', $request->user()->id)->orderByDesc('arrived_at')->paginate(30);
    }

    public function store(Request $request, AttendanceService $service)
    {
        $this->authorizeEmployee($request);
        $data = $request->validate([
            'request_id' => ['required', 'uuid'], 'type' => ['required', 'in:arrival,departure'],
            'device_id' => ['required', 'uuid'], 'challenge_id' => ['required', 'uuid'],
            'device_signature' => ['required', 'regex:/^[0-9a-f]{64}$/'],
            'site_id' => ['required', 'integer', 'exists:attendance_sites,id'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'accuracy_meters' => ['required', 'numeric', 'gt:0', 'max:10000'],
            'measured_at' => ['required', 'date', 'regex:/^\d{4}-\d{2}-\d{2}T.+(?:Z|[+-]\d{2}:\d{2})$/'],
        ]);
        return DB::transaction(function () use ($request, $service, $data) {
            $user = DB::table('users')->where('id', $request->user()->id)->lockForUpdate()->first();
            abort_unless($user && $user->is_enabled && !$user->deleted
                && DB::table('attendance_enrollments')->where('user_id', $user->id)
                    ->where('status', 'approved')->exists(), 403, 'Inscription Pointage non approuvée.');
            $device = DB::table('attendance_devices')->where('user_id', $request->user()->id)->first();
            abort_unless($device && $device->device_id === $data['device_id'], 403, 'Téléphone non autorisé.');
            $challenge = DB::table('attendance_device_challenges')->where('id', $data['challenge_id'])
                ->lockForUpdate()->first();
            abort_unless($challenge && (int) $challenge->user_id === (int) $request->user()->id
                && $challenge->device_id === $data['device_id']
                && $challenge->purpose === $data['type'] && $challenge->request_id === $data['request_id'],
                403, 'Défi du téléphone absent ou invalide.');
            $message = implode('|', [$challenge->id, $challenge->request_id, $challenge->purpose]);
            $expected = hash_hmac('sha256', $message, hex2bin(Crypt::decryptString($device->encrypted_secret)));
            abort_unless(hash_equals($expected, $data['device_signature']), 403, 'Signature du téléphone invalide.');
            if ($challenge->consumed_at) {
                $previous = AttendanceSession::where('user_id', $request->user()->id)
                    ->where(fn ($query) => $query->where('arrival_request_id', $data['request_id'])
                        ->orWhere('departure_request_id', $data['request_id']))->first();
                abort_unless($previous && $previous->attendance_site_id == $data['site_id'],
                    403, 'Défi du téléphone déjà utilisé.');
                return response()->json(['success' => true, 'session' => $previous]);
            }
            abort_unless(now()->lessThan($challenge->expires_at), 403, 'Défi du téléphone expiré.');
            $session = $service->record($request->user(), $data);
            DB::table('attendance_device_challenges')->where('id', $challenge->id)
                ->update(['consumed_at' => now(), 'updated_at' => now()]);
            return response()->json(['success' => true, 'session' => $session]);
        });
    }
}
