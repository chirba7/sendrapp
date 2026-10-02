<?php

namespace App\Http\Controllers;

use App\Models\AttendanceAssignment;
use App\Models\AttendanceEnrollment;
use App\Models\AttendanceSession;
use App\Models\AttendanceSite;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AttendanceController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->validate([
            'date' => ['nullable', 'date_format:Y-m-d'],
            'site_id' => ['nullable', 'integer', 'exists:attendance_sites,id'],
            'status' => ['nullable', Rule::in(['early', 'on_time', 'late', 'incomplete'])],
        ]);
        $date = $filters['date'] ?? now('Africa/Dakar')->toDateString();
        $sessions = AttendanceSession::with(['user', 'site'])->whereDate('work_date', $date)
            ->when($filters['site_id'] ?? null, fn ($q, $id) => $q->where('attendance_site_id', $id))
            ->when($filters['status'] ?? null, fn ($q, $status) => $status === 'incomplete'
                ? $q->whereNull('departed_at') : $q->where('arrival_status', $status))
            ->orderByDesc('arrived_at')->paginate(30)->withQueryString();
        $sites = AttendanceSite::orderBy('name')->get();
        return view('attendance.index', compact('sessions', 'sites', 'date'));
    }

    public function sites()
    {
        $sites = AttendanceSite::withCount('assignments')->orderBy('name')->paginate(20);
        return view('attendance.sites', compact('sites'));
    }

    public function createSite()
    {
        return view('attendance.site-form', ['site' => new AttendanceSite([
            'radius_meters' => 100, 'max_accuracy_meters' => 50, 'timezone' => 'Africa/Dakar', 'active' => true,
        ])]);
    }

    public function editSite(AttendanceSite $site)
    {
        return view('attendance.site-form', compact('site'));
    }

    public function storeSite(Request $request)
    {
        AttendanceSite::create($this->siteData($request));
        return redirect()->route('attendance.sites')->with('success', 'Site de pointage créé.');
    }

    public function updateSite(Request $request, AttendanceSite $site)
    {
        $site->update($this->siteData($request));
        return redirect()->route('attendance.sites')->with('success', 'Site de pointage modifié.');
    }

    private function siteData(Request $request): array
    {
        return $request->validate([
            'name' => ['required', 'string', 'max:255'], 'address' => ['nullable', 'string', 'max:255'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'radius_meters' => ['required', 'integer', 'between:10,5000'],
            'max_accuracy_meters' => ['required', 'integer', 'between:1,500', 'lte:radius_meters'],
            'timezone' => ['required', 'timezone'], 'active' => ['required', 'boolean'],
        ]);
    }

    public function assignments()
    {
        $assignments = AttendanceAssignment::with(['user', 'site'])
            ->whereHas('user', fn ($q) => $q->nonArchives())->latest()->paginate(20);
        $sites = AttendanceSite::where('active', true)->orderBy('name')->get();
        $employees = User::nonArchives()->where('is_enabled', true)
            ->whereHas('attendanceEnrollment', fn ($q) => $q->where('status', 'approved'))
            ->orderBy('last_name')->get(['id', 'first_name', 'last_name', 'telephone']);
        $enrollments = AttendanceEnrollment::with('user')->whereHas('user', fn ($q) => $q->nonArchives())
            ->latest()->paginate(20, ['*'], 'inscriptions');
        return view('attendance.assignments', compact('assignments', 'sites', 'employees', 'enrollments'));
    }

    public function storeAssignment(Request $request)
    {
        $data = $request->validate([
            'user_id' => ['required', 'integer', Rule::exists('users', 'id')->where(fn ($q) => $q
                ->where('is_enabled', true)
                ->where(fn ($q) => $q->whereNull('deleted')->orWhere('deleted', false))
                ->whereIn('id', AttendanceEnrollment::where('status', 'approved')->select('user_id')))],
            'attendance_site_id' => ['required', 'integer', Rule::exists('attendance_sites', 'id')->where('active', true)],
            'weekdays' => ['required', 'array', 'min:1', 'max:7'],
            'weekdays.*' => ['required', 'integer', 'between:1,7', 'distinct'],
            'starts_at' => ['required', 'date_format:H:i'],
            'ends_at' => ['required', 'date_format:H:i', 'different:starts_at'],
            'late_tolerance_minutes' => ['required', 'integer', 'between:0,120'],
        ]);
        $data['weekdays'] = array_map('intval', $data['weekdays']);
        $data['active'] = true;
        DB::transaction(function () use ($data) {
            User::whereKey($data['user_id'])->lockForUpdate()->firstOrFail();
            AttendanceAssignment::updateOrCreate(['user_id' => $data['user_id']], $data);
        });
        return redirect()->route('attendance.assignments')->with('success', 'Planning enregistré. Il s’appliquera à la prochaine arrivée.');
    }

    public function disableAssignment(AttendanceAssignment $assignment)
    {
        DB::transaction(function () use ($assignment) {
            User::whereKey($assignment->user_id)->lockForUpdate()->firstOrFail();
            $assignment->update(['active' => false]);
        });
        return redirect()->route('attendance.assignments')->with('success', 'Affectation désactivée. Une journée ouverte peut toujours être clôturée.');
    }

    public function approveEnrollment(Request $request, AttendanceEnrollment $enrollment)
    {
        $request->validate(['identity_checked' => ['accepted']]);
        DB::transaction(function () use ($request, $enrollment) {
            $user = User::whereKey($enrollment->user_id)->lockForUpdate()->firstOrFail();
            abort_if($user->deleted, 422, 'Compte archivé.');
            abort_unless(DB::table('attendance_devices')->where('user_id', $user->id)->exists(),
                422, 'Le téléphone doit être lié avant la validation du compte.');
            $enrollment->update(['status' => 'approved', 'approved_by' => $request->user()->id, 'approved_at' => now()]);
            // Les nouveaux comptes Pointage attendent l'approbation pour être actifs.
            if ($user->role()->where('nomRole', 'Employe pointage')->exists()) {
                $user->is_enabled = true;
                $user->save();
            }
        });
        return redirect()->route('attendance.assignments')->with('success', 'Inscription Pointage validée. L’employé peut être affecté.');
    }

    public function resetDevice(AttendanceEnrollment $enrollment)
    {
        DB::transaction(function () use ($enrollment) {
            User::whereKey($enrollment->user_id)->lockForUpdate()->firstOrFail();
            DB::table('attendance_device_challenges')->where('user_id', $enrollment->user_id)->delete();
            DB::table('attendance_devices')->where('user_id', $enrollment->user_id)->delete();
            $enrollment->update(['status' => 'pending', 'approved_by' => null, 'approved_at' => null]);
            AttendanceAssignment::where('user_id', $enrollment->user_id)->update(['active' => false]);
        });
        return redirect()->route('attendance.assignments')->with('success',
            'Téléphone dissocié. L’employé doit lier son nouveau téléphone avant validation.');
    }

    public function disableEnrollment(AttendanceEnrollment $enrollment)
    {
        DB::transaction(function () use ($enrollment) {
            User::whereKey($enrollment->user_id)->lockForUpdate()->firstOrFail();
            $enrollment->update(['status' => 'disabled']);
            AttendanceAssignment::where('user_id', $enrollment->user_id)->update(['active' => false]);
        });
        return redirect()->route('attendance.assignments')->with('success', 'Accès Pointage désactivé.');
    }

    public function destroyEnrollment(AttendanceEnrollment $enrollment)
    {
        DB::transaction(function () use ($enrollment) {
            $user = User::whereKey($enrollment->user_id)->lockForUpdate()->firstOrFail();
            abort_unless($user->role()->where('nomRole', 'Employe pointage')->exists(), 422,
                'Ce compte est partagé avec Sendra. Désactivez son accès Pointage sans supprimer le compte principal.');
            abort_if($user->deleted, 422, 'Compte déjà supprimé.');
            DB::table('attendance_face_proofs')->where('user_id', $user->id)->delete();
            DB::table('attendance_face_profiles')->where('user_id', $user->id)->delete();
            DB::table('attendance_device_challenges')->where('user_id', $user->id)->delete();
            DB::table('attendance_devices')->where('user_id', $user->id)->delete();
            $enrollment->update(['status' => 'disabled']);
            AttendanceAssignment::where('user_id', $user->id)->update(['active' => false]);
            $user->deleted = true;
            $user->is_enabled = false;
            $user->save();
        });
        return redirect()->route('attendance.assignments')->with('success',
            'Compte Pointage supprimé. Son historique reste conservé.');
    }
}
