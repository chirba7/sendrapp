<?php $__env->startSection('session'); ?>
<?php ($statuses = ['early'=>'En avance', 'on_time'=>'À l’heure', 'late'=>'En retard']); ?>
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><h2 class="text-success">Pointage des employés</h2></div>
    <?php echo $__env->make('attendance.nav', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?>
    <form class="card-style mb-4" method="GET" action="<?php echo e(route('attendance.index')); ?>"><div class="row g-3 align-items-end">
        <div class="col-md-3"><label for="date" class="form-label">Date de début du service</label><input type="date" id="date" name="date" class="form-control" value="<?php echo e($date); ?>" required></div>
        <div class="col-md-3"><label for="site_id" class="form-label">Site</label><select id="site_id" name="site_id" class="form-select"><option value="">Tous les sites</option><?php $__currentLoopData = $sites; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $site): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?><option value="<?php echo e($site->id); ?>" <?php if(request('site_id') == $site->id): echo 'selected'; endif; ?>><?php echo e($site->name); ?></option><?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?></select></div>
        <div class="col-md-3"><label for="status" class="form-label">Statut</label><select id="status" name="status" class="form-select"><option value="">Tous les statuts</option><?php $__currentLoopData = $statuses + ['incomplete'=>'Sans départ']; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $key => $label): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?><option value="<?php echo e($key); ?>" <?php if(request('status') === $key): echo 'selected'; endif; ?>><?php echo e($label); ?></option><?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?></select></div>
        <div class="col-md-3"><button class="btn btn-success">Afficher</button></div>
    </div></form>
    <div class="card-style table-responsive"><table class="table"><thead><tr><th>Employé / site</th><th>Service prévu</th><th>Arrivée</th><th>Statut</th><th>Départ</th><th>Départ anticipé</th></tr></thead><tbody>
    <?php $__empty_1 = true; $__currentLoopData = $sessions; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $session): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
    <tr>
        <td><?php echo e($session->user->first_name); ?> <?php echo e($session->user->last_name); ?><br><small><?php echo e($session->schedule_snapshot['name']); ?></small></td>
        <td><?php echo e($session->scheduled_start->setTimezone($session->timezone)->format('d/m H:i')); ?> – <?php echo e($session->scheduled_end->setTimezone($session->timezone)->format('d/m H:i')); ?><br><small><?php echo e($session->timezone); ?></small></td>
        <td><?php echo e($session->arrived_at->setTimezone($session->timezone)->format('d/m H:i:s')); ?><br><small>Distance : <?php echo e($session->arrival_position['distance_meters']); ?> m</small></td>
        <td><span class="badge <?php echo e($session->arrival_status === 'late' ? 'bg-warning text-dark' : 'bg-success'); ?>"><?php echo e($statuses[$session->arrival_status]); ?></span><?php if($session->late_minutes > 0): ?><br><small>Écart réel : <?php echo e($session->late_minutes); ?> min</small><?php endif; ?></td>
        <td><?php if($session->departed_at): ?><?php echo e($session->departed_at->setTimezone($session->timezone)->format('d/m H:i:s')); ?><?php else: ?><span class="text-muted">Sans départ</span><?php endif; ?></td>
        <td><?php echo e($session->early_departure_minutes ? $session->early_departure_minutes.' min' : '—'); ?></td>
    </tr>
    <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?><tr><td colspan="6">Aucun pointage pour ces critères. L’absence d’un pointage ne constitue pas à elle seule une absence validée.</td></tr><?php endif; ?>
    </tbody></table><?php echo e($sessions->links()); ?></div>
</div></section>
<?php $__env->stopSection(); ?>

<?php echo $__env->make('layouts.master', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH C:\Projets\sendrapp\sendra\sendraApp\resources\views/attendance/index.blade.php ENDPATH**/ ?>