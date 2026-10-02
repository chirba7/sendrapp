<?php

namespace App\Http\Controllers;

use App\Models\AttendanceEnrollment;
use App\Models\User;
use App\Models\UserVerificationCode;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class AttendanceEnrollmentController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'first_name' => ['required', 'string', 'max:50'],
            'last_name' => ['required', 'string', 'max:50'],
            // Un numéro d'un compte archivé peut servir à une réinscription.
            'telephone' => ['required', 'regex:/^\d{9}$/', Rule::unique('users', 'telephone')->where(
                fn ($q) => $q->where(fn ($w) => $w->whereNull('deleted')->orWhere('deleted', false))
            )],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $user = DB::transaction(function () use ($data) {
            $verification = UserVerificationCode::where('phone', $data['telephone'])->lockForUpdate()->first();
            if (!$verification || $verification->isExpired() || !$verification->verified_at) {
                throw ValidationException::withMessages(['telephone' => 'Vérifiez d’abord ce numéro avec le code SMS.']);
            }
            $roleId = DB::table('roles')->where('nomRole', 'Employe pointage')->value('id');
            abort_if(!$roleId, 503, 'Le module Pointage doit être migré avant toute inscription.');
            // Conserver l'historique du compte archivé réactivé après vérification SMS.
            $user = User::where('telephone', $data['telephone'])->first() ?? new User();
            $user->first_name = $data['first_name'];
            $user->last_name = $data['last_name'];
            $user->telephone = $data['telephone'];
            $user->password = Hash::make($data['password']);
            $user->role_id = $roleId;
            $user->deleted = null;
            $user->is_enabled = false;
            $user->save();
            AttendanceEnrollment::updateOrCreate(
                ['user_id' => $user->id],
                ['status' => 'pending', 'approved_by' => null]
            );
            $verification->delete();
            return $user;
        });

        return response()->json(['message' => 'Inscription reçue. Un administrateur doit la valider.',
            'user_id' => $user->id, 'status' => 'pending'], 201);
    }

    public function join(Request $request)
    {
        $user = $request->user();
        abort_if($user->deleted, 403, 'Compte archivé.');
        $enrollment = AttendanceEnrollment::firstOrCreate(['user_id' => $user->id], ['status' => 'pending']);
        return response()->json(['status' => $enrollment->status]);
    }

    public function status(Request $request)
    {
        $user = $request->user();
        abort_if($user->deleted, 403, 'Compte archivé.');
        return response()->json([
            'user' => ['id' => $user->id, 'first_name' => $user->first_name,
                'last_name' => $user->last_name, 'telephone' => $user->telephone],
            'status' => $user->attendanceEnrollment?->status ?? 'not_registered',
            'device_registered' => DB::table('attendance_devices')->where('user_id', $user->id)->exists(),
            'registered_device_id' => DB::table('attendance_devices')->where('user_id', $user->id)->value('device_id'),
            'pointage_available' => true,
        ]);
    }
}
