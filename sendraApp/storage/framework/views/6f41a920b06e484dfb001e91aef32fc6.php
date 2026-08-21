<?php $__env->startSection('session'); ?>
<section class="section ">
    <div class="container-fluid ">
        <!-- ========== title-wrapper start ========== -->
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <div class="title">
                        
                        <h2 class="text-success">Comptes Autorité préfecture</h2>
                    </div>
                </div>
            </div>
            <!-- end row -->
        </div>
        <?php if(session('success')): ?>
        <div class="row alert-box success-alert">
            <div class="col-12 alert">
                <p class="text-medium">
                    <?php echo e(session('success')); ?>

                </p>
            </div>
        </div>
        <?php endif; ?>

        <!-- End Row -->
        <div class="row">
            <div class="col-lg-12">
                <div class="card-style mb-30">
                    <div class="title d-flex flex-wrap align-items-center justify-content-between">
                        <div class="left">
                            <h6 class="text-medium mb-30">Liste des comptes Utilisateur</h6>
                        </div>
                    </div>
                    <!-- End Title -->
                    <div class="table-responsive">
                        <table class="table top-selling-table">
                            <thead>
                                <tr>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Nom
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Prénom
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            email
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Téléphone
                                        </h6>
                                    </th>
                                    <th>
                                        <h6 class="text-sm text-medium text-start">
                                            Role
                                        </h6>
                                    </th>
                                    <th>
                                        <h6 class="text-sm text-medium text-end">
                                            Modifier
                                        </h6>
                                    </th>
                            <tbody>
                                <?php $__currentLoopData = $users; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $key => $user): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                <tr>
                                    <td>
                                        <p class="text-sm"><?php echo e($user->first_name); ?></p>
                                    </td>
                                    <td>
                                        <p class="text-sm"><?php echo e($user->last_name); ?></p>
                                    </td>
                                    <td>
                                        <p class="text-sm"><?php echo e($user->email); ?></p>
                                    </td>
                                    <td>
                                        <p class="text-sm"><?php echo e($user->telephone); ?></p>
                                    </td>
                                    <td>
                                        <p class="text-sm"><?php echo e($user->role->nomRole); ?></p>
                                    </td>
                                    <td>
                                        <div class="action d-flex justify-content-end">
                                            <a href="<?php echo e(route('modifier', [$user->id])); ?>" class="edit text-success ">
                                                <i class="lni lni-pencil"></i>
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                            </tbody>
                        </table>
                        <div class="d-flex justify-content-end mt-4">
                            <?php echo $users->links(); ?>

                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.master', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /var/www/html/resources/views/comptes/utilisateurs.blade.php ENDPATH**/ ?>