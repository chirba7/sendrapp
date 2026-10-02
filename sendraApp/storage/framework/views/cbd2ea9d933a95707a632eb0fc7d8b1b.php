<?php $__env->startSection('session'); ?>
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30 d-flex flex-wrap justify-content-between gap-3"><h2 class="text-success">Sites de pointage</h2><a class="main-btn success-btn" href="<?php echo e(route('attendance.sites.create')); ?>">Créer un site</a></div>
    <?php echo $__env->make('attendance.nav', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?>
    <div class="card-style table-responsive"><table class="table"><thead><tr><th>Site</th><th>Rayon autorisé</th><th>Précision GPS maximale</th><th>Affectations</th><th>État</th><th>Action</th></tr></thead><tbody>
    <?php $__empty_1 = true; $__currentLoopData = $sites; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $site): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); $__empty_1 = false; ?>
    <tr><td><strong><?php echo e($site->name); ?></strong><br><small><?php echo e($site->address); ?></small></td><td><?php echo e($site->radius_meters); ?> m</td><td><?php echo e($site->max_accuracy_meters); ?> m</td><td><?php echo e($site->assignments_count); ?></td><td><?php echo e($site->active ? 'Actif' : 'Désactivé'); ?></td><td><a class="btn btn-outline-success btn-sm" href="<?php echo e(route('attendance.sites.edit', $site)); ?>">Modifier</a></td></tr>
    <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); if ($__empty_1): ?><tr><td colspan="6">Aucun site. Créez un site puis affectez les employés et leurs horaires.</td></tr><?php endif; ?>
    </tbody></table><?php echo e($sites->links()); ?></div>
</div></section>
<?php $__env->stopSection(); ?>

<?php echo $__env->make('layouts.master', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH C:\Projets\sendrapp\sendra\sendraApp\resources\views/attendance/sites.blade.php ENDPATH**/ ?>