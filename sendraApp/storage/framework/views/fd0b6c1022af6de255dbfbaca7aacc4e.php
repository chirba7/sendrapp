<?php $__env->startSection('session'); ?>
<section class="section ">
    <div class="container-fluid ">
        <!-- ========== title-wrapper start ========== -->
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <div class="title">
                        <h2 class="text-success">Signalements</h2>
                    </div>
                </div>
            </div>
            <!-- end row -->
        </div>


        <!-- End Row -->
        <div class="row">
            <div class="col-lg-12">
                <div class="card-style mb-30">
                    <div class="title d-flex flex-wrap align-items-center justify-content-between">
                        <div class="left">
                            <h6 class="text-medium mb-30">Liste des signalements qui ne pas résolus</h6>
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
                                <?php $__currentLoopData = $signalements; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $key => $signalement): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
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
                                    <td>
                                        <span class="status-btn close-btn"><?php echo e($signalement->etat); ?></span>
                                    </td>
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
                        <div class="d-flex justify-content-end mt-4">
                            <?php echo $signalements->links(); ?>

                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>


<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.master', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /var/www/html/resources/views/carPosition/signales.blade.php ENDPATH**/ ?>