<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AttendanceDeviceController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'device_id' => ['required', 'uuid'],
            'secret' => ['required', 'regex:/^[0-9a-f]{64}$/'],
        ]);
        abort_unless($request->user()->attendanceEnrollment()->where('status', 'pending')->exists(),
            403, 'Un responsable doit autoriser le changement de téléphone.');
        abort_if($request->user()->deleted, 403, 'Compte archivé.');
        DB::transaction(function () use ($request, $data) {
            $user = DB::table('users')->where('id', $request->user()->id)->lockForUpdate()->first();
            abort_unless($user, 403);
            $existing = DB::table('attendance_devices')->where('user_id', $user->id)->first();
            if ($existing) {
                abort_unless($existing->device_id === $data['device_id']
                    && hash_equals(Crypt::decryptString($existing->encrypted_secret), $data['secret']),
                    409, 'Ce compte est déjà lié à un téléphone.');
                return;
            }
            DB::table('attendance_devices')->insert([
                'user_id' => $user->id, 'device_id' => $data['device_id'],
                'encrypted_secret' => Crypt::encryptString($data['secret']),
                'created_at' => now(), 'updated_at' => now(),
            ]);
        });
        return response()->json(['device_registered' => true]);
    }

    public function challenge(Request $request)
    {
        $data = $request->validate([
            'device_id' => ['required', 'uuid'], 'request_id' => ['required', 'uuid'],
            'purpose' => ['required', 'in:arrival,departure'],
        ]);
        abort_unless($request->user()->is_enabled && !$request->user()->deleted
            && $request->user()->attendanceEnrollment()->where('status', 'approved')->exists(),
            403, 'Inscription Pointage non approuvée.');
        abort_unless(DB::table('attendance_devices')->where('user_id', $request->user()->id)
            ->where('device_id', $data['device_id'])->exists(), 403, 'Téléphone non autorisé.');
        $id = (string) Str::uuid();
        DB::table('attendance_device_challenges')->insert([
            'id' => $id, 'user_id' => $request->user()->id,
            'device_id' => $data['device_id'], 'request_id' => $data['request_id'],
            'purpose' => $data['purpose'], 'expires_at' => now()->addMinutes(2),
            'created_at' => now(), 'updated_at' => now(),
        ]);
        return response()->json(['challenge_id' => $id]);
    }
}
