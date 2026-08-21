<?php $__env->startSection('session'); ?>
<section class="section ">
    <div class="container-fluid ">
        <!-- ========== title-wrapper start ========== -->
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <div class="title tesu">
                        <h2 class="text-success">Dashboard</h2>
                    </div>
                </div>
            </div>
            <!-- end row -->
        </div>
        <!-- ========== title-wrapper end ========== -->
        <div class="row">
            <div class="col-xl-3 col-lg-4 col-sm-6">
                <div class="icon-card mb-30">
                    <div class="icon ">
                        <i class="lni lni-car"></i>
                    </div>
                    <div class="content">
                        <h6 class="mb-10">Signalements</h6>
                        <h3 class="text-bold mb-10"><?php echo e($signalements); ?></h3>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-lg-4 col-sm-6">
                <div class="icon-card mb-30">
                    <div class="icon red">
                        <i class="lni lni-car"></i>
                    </div>
                    <div class="content">
                        <h6 class="mb-10">Pas résolus</h6>
                        <h3 class="text-bold mb-10"><?php echo e($signales); ?></h3>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-lg-4 col-sm-6">
                <div class="icon-card mb-30">
                    <div class="icon orange">
                        <i class="lni lni-car"></i>
                    </div>
                    <div class="content">
                        <h6 class="mb-10">En cours</h6>
                        <h3 class="text-bold mb-10"><?php echo e($encours); ?></h3>
                    </div>
                </div>
            </div>
            <div class="col-xl-3 col-lg-4 col-sm-6">
                <div class="icon-card mb-30">
                    <div class="icon success ">
                        <i class="lni lni-car"></i>
                    </div>
                    <div class="content">
                        <h6 class="mb-10">Enlévements</h6>
                        <h3 class="text-bold mb-10"><?php echo e($enleves); ?></h3>
                    </div>
                </div>
            </div>
        </div>


        <div class="row">
            <div class="col-lg-12">
                <div class="card-style mb-30">
                    <div class="title d-flex flex-wrap align-items-center justify-content-between">
                        <div class="left">
                            <h6 class="text-medium mb-30">Liste des signalements</h6>
                        </div>
                    </div>
                    <!-- End Title -->
                    <div class="table-responsive">
                        <table class="table top-selling-table">
                            <thead>
                                <tr>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Image
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Titre
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Secteur
                                        </h6>
                                    </th>
                                    <th class="min-width">
                                        <h6 class="text-sm text-medium">
                                            Date Signalement
                                        </h6>
                                    </th>
                                    <th>
                                        <h6 class="text-sm text-medium text-start">
                                            Etat
                                        </h6>
                                    </th>
                                    <th>
                                        <h6 class="text-sm text-medium text-end">
                                            Constatation
                                        </h6>
                                    </th>
                            <tbody>
                                <?php $__currentLoopData = $signalement; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $key => $signalement): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                <tr>
                                    <td>
                                        <div class="employee-image">
                                            
                                            <img src="<?php echo e($signalement->photo->isNotEmpty() ? config('services.backend.storage_url') . '/' . $signalement->photo[0]->filepath : ''); ?>" alt="" />
                                        </div>
                                    </td>
                                    <td>
                                        <p class="text-sm"><?php echo e($signalement->title); ?></p>
                                    </td>
                                    <td>
                                        <p class="text-sm"><?php echo e($signalement->commune); ?></p>
                                    </td>
                                    <td>
                                        <p class="text-sm"><?php echo e($signalement->created_at->format('d F Y \à H\hi')); ?></p>
                                    </td>
                                    <?php if($signalement->etat == "SIGNALE"): ?>
                                    <td>
                                        <span class="status-btn close-btn"><?php echo e($signalement->etat); ?></span>
                                    </td>
                                    <?php endif; ?>
                                    <?php if($signalement->etat == "EN COURS"): ?>
                                    <td>
                                        <span class="status-btn warning-btn"><?php echo e($signalement->etat); ?></span>
                                    </td>
                                    <?php endif; ?>
                                    <?php if($signalement->etat == "ENLEVE"): ?>
                                    <td>
                                        <span class="status-btn success-btn"><?php echo e($signalement->etat); ?></span>
                                    </td>
                                    <?php endif; ?>
                                    <td>
                                        <div class="action justify-content-center">
                                            <a href="<?php echo e(route('details', [$signalement->id])); ?>" class="edit text-success ">
                                                <i class="lni lni-eye"></i>
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- end container -->
</section>
<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.master', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /var/www/html/resources/views/welcome.blade.php ENDPATH**/ ?>