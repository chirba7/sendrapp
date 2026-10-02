<nav class="d-flex flex-wrap gap-2 my-3" aria-label="Gestion du pointage">
    <a class="btn <?php echo e(request()->routeIs('attendance.index') ? 'btn-success' : 'btn-outline-success'); ?>" href="<?php echo e(route('attendance.index')); ?>">Présences</a>
    <a class="btn <?php echo e(request()->routeIs('attendance.sites*') ? 'btn-success' : 'btn-outline-success'); ?>" href="<?php echo e(route('attendance.sites')); ?>">Sites de pointage</a>
    <a class="btn <?php echo e(request()->routeIs('attendance.assignments*') ? 'btn-success' : 'btn-outline-success'); ?>" href="<?php echo e(route('attendance.assignments')); ?>">Horaires et affectations</a>
</nav>
<?php if(session('success')): ?><div class="alert alert-success" role="status"><?php echo e(session('success')); ?></div><?php endif; ?>
<?php if($errors->any()): ?><div class="alert alert-danger" role="alert"><ul class="mb-0"><?php $__currentLoopData = $errors->all(); $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $error): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?><li><?php echo e($error); ?></li><?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?></ul></div><?php endif; ?>
<?php /**PATH C:\Projets\sendrapp\sendra\sendraApp\resources\views/attendance/nav.blade.php ENDPATH**/ ?>