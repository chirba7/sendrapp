<?php $__env->startSection('session'); ?>
<?php ($days = [1=>'Lundi', 2=>'Mardi', 3=>'Mercredi', 4=>'Jeudi', 5=>'Vendredi', 6=>'Samedi', 7=>'Dimanche']); ?>
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><h2 class="text-success">Horaires et affectations</h2></div>
    <?php echo $__env->make('attendance.nav', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?>
    <div class="card-style mb-4 table-responsive"><h3 class="mb-3">Inscriptions depuis l’application Pointage</h3>
        <p>Seuls les comptes validés et actifs apparaissent dans la liste des employés à affecter.</p>
        <table class="table"><thead><tr><th>Employé</th><th>Téléphone</th><th>Inscrit le</th><th>État</th><th>Action</th></tr></thead><tbody>
        <?php $__empty_1 = true; $__currentLoopData = $enrollments; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $enrollment): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
            <tr><td><?php echo e($enrollment->user->first_name); ?> <?php echo e($enrollment->user->last_name); ?></td><td><?php echo e($enrollment->user->telephone); ?></td><td><?php echo e($enrollment->created_at->timezone('Africa/Dakar')->format('d/m/Y H:i')); ?></td><td><?php echo e(['pending'=>'En attente', 'approved'=>'Validé', 'disabled'=>'Désactivé'][$enrollment->status] ?? $enrollment->status); ?></td><td class="d-flex gap-2">
                <?php if($enrollment->status !== 'approved' && !$enrollment->user->deleted): ?><form method="POST" action="<?php echo e(route('attendance.enrollments.approve', $enrollment)); ?>"><?php echo csrf_field(); ?> <?php echo method_field('PATCH'); ?><button class="btn btn-success btn-sm">Valider</button></form><?php endif; ?>
                <?php if($enrollment->status !== 'disabled'): ?><form method="POST" action="<?php echo e(route('attendance.enrollments.disable', $enrollment)); ?>"><?php echo csrf_field(); ?> <?php echo method_field('PATCH'); ?><button class="btn btn-outline-danger btn-sm">Désactiver</button></form><?php endif; ?>
                <?php if($enrollment->user->role?->nomRole === 'Employe pointage'): ?>
                    <form method="POST" action="<?php echo e(route('attendance.enrollments.destroy', $enrollment)); ?>" onsubmit="return confirm('Supprimer ce compte Pointage ? Il ne pourra plus se connecter. Son historique de pointage sera conservé.')"><?php echo csrf_field(); ?> <?php echo method_field('DELETE'); ?><button class="btn btn-danger btn-sm">Supprimer le compte</button></form>
                <?php endif; ?>
            </td></tr>
        <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?><tr><td colspan="5">Aucune inscription depuis l’application Pointage.</td></tr><?php endif; ?>
        </tbody></table><?php echo e($enrollments->links()); ?>

    </div>
    <form class="card-style mb-4" method="POST" action="<?php echo e(route('attendance.assignments.store')); ?>">
        <?php echo csrf_field(); ?>
        <h3 class="mb-3">Affecter un employé ou remplacer son planning</h3>
        <p class="mb-3">Un site et un planning hebdomadaire par employé. Une fin antérieure au début correspond à un service de nuit, terminé le lendemain. Les jours cochés sont les jours de début du service.</p>
        <div class="row g-3">
            <div class="col-md-6"><label for="user_id" class="form-label">Employé inscrit et validé depuis Pointage</label><select id="user_id" name="user_id" class="form-select" required><option value="">Choisir un employé</option><?php $__currentLoopData = $employees; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $employee): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?><option value="<?php echo e($employee->id); ?>" <?php if(old('user_id') == $employee->id): echo 'selected'; endif; ?>><?php echo e($employee->first_name); ?> <?php echo e($employee->last_name); ?> — <?php echo e($employee->telephone); ?></option><?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?></select></div>
            <div class="col-md-6"><label for="attendance_site_id" class="form-label">Site actif</label><select id="attendance_site_id" name="attendance_site_id" class="form-select" required><option value="">Choisir un site</option><?php $__currentLoopData = $sites; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $site): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?><option value="<?php echo e($site->id); ?>" <?php if(old('attendance_site_id') == $site->id): echo 'selected'; endif; ?>><?php echo e($site->name); ?></option><?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?></select></div>
            <div class="col-md-4"><label for="starts_at" class="form-label">Début du travail</label><input type="time" id="starts_at" name="starts_at" class="form-control" value="<?php echo e(old('starts_at', '08:00')); ?>" required></div>
            <div class="col-md-4"><label for="ends_at" class="form-label">Fin du travail</label><input type="time" id="ends_at" name="ends_at" class="form-control" value="<?php echo e(old('ends_at', '17:00')); ?>" required></div>
            <div class="col-md-4"><label for="late_tolerance_minutes" class="form-label">Tolérance de retard (minutes)</label><input type="number" min="0" max="120" id="late_tolerance_minutes" name="late_tolerance_minutes" class="form-control" value="<?php echo e(old('late_tolerance_minutes', 5)); ?>" required></div>
            <fieldset class="col-12"><legend class="fs-6">Jours travaillés</legend><?php $__currentLoopData = $days; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $number => $label): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?><label class="me-3"><input type="checkbox" name="weekdays[]" value="<?php echo e($number); ?>" <?php if(in_array($number, old('weekdays', [1,2,3,4,5]))): echo 'checked'; endif; ?>> <?php echo e($label); ?></label><?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?></fieldset>
            <div class="col-12 text-end"><button class="btn btn-success" <?php if($employees->isEmpty() || $sites->isEmpty()): echo 'disabled'; endif; ?>>Enregistrer le planning</button></div>
        </div>
        <?php if($sites->isEmpty()): ?><p class="text-muted">Créez d’abord un site de pointage actif.</p><?php endif; ?>
    </form>
    <div class="card-style table-responsive"><table class="table"><thead><tr><th>Employé</th><th>Site</th><th>Jours</th><th>Horaires</th><th>Tolérance</th><th>État</th><th>Action</th></tr></thead><tbody>
    <?php $__empty_1 = true; $__currentLoopData = $assignments; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $assignment): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
        <tr><td><?php echo e($assignment->user->first_name); ?> <?php echo e($assignment->user->last_name); ?></td><td><?php echo e($assignment->site->name); ?></td><td><?php echo e(collect($assignment->weekdays)->map(fn ($day) => $days[$day])->join(', ')); ?></td><td><?php echo e(substr($assignment->starts_at, 0, 5)); ?> – <?php echo e(substr($assignment->ends_at, 0, 5)); ?><br><small><?php echo e($assignment->site->timezone); ?></small></td><td><?php echo e($assignment->late_tolerance_minutes); ?> min</td><td><?php echo e($assignment->active ? 'Active' : 'Désactivée'); ?></td><td><?php if($assignment->active): ?><form method="POST" action="<?php echo e(route('attendance.assignments.disable', $assignment)); ?>"><?php echo csrf_field(); ?> <?php echo method_field('PATCH'); ?><button class="btn btn-outline-danger btn-sm">Désactiver</button></form><?php endif; ?></td></tr>
    <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?><tr><td colspan="7">Aucun employé affecté.</td></tr><?php endif; ?>
    </tbody></table><?php echo e($assignments->links()); ?></div>
</div></section>
<?php $__env->stopSection(); ?>

<?php echo $__env->make('layouts.master', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH C:\Projets\sendrapp\sendra\sendraApp\resources\views/attendance/assignments.blade.php ENDPATH**/ ?>