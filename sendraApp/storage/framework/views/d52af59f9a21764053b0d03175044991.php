<?php $__env->startSection('contenu'); ?>
<section class="signin-section">
    <div class="container mt-5">
        <div class="row g-0 auth-row">
            <div class="col-lg-6">
                <div class="auth-cover-wrapper bg-success-100">
                    <div class="auth-cover">
                        <div class="title text-center">
                            <h1 class="text-success mb-10">Bienvenue, <?php echo e(Auth::user()->first_name); ?></h1>
                            <p class="text-medium">
                                Nous sommes ravis de vous avoir parmi nous. Pour tirer le meilleur parti de la plateform, Choisissez un nouveau mot de passe pour des raisons de sécurité :
                            </p>
                        </div>

                    </div>
                </div>
            </div>
            <!-- end col -->
            <div class="col-lg-6">
                <div class="signin-wrapper">
                    <div class="form-wrapper ">
                        <div class="shape-image mb-25 d-flex justify-content-center flex-wrap">
                            <img src="<?php echo e(asset('img/logoSendra.png')); ?>" alt="">
                        </div>
                        <h2 class="mb-25 text-center">Modifier votre mot de passe</h2>
                        <form method="POST" action="<?php echo e(route('motDePasse')); ?>">
                            <?php echo csrf_field(); ?>
                            <?php echo method_field('PATCH'); ?>
                            <div class="row">
                                <div class="col-12">
                                    <div class="input-style-1">
                                        <label>Mot de passe</label>
                                        <input type="password" name="password" class="form-control" placeholder="Entre votre mot de passe">
                                        <?php $__errorArgs = ['password'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                        <span class="text-danger"><?php echo e($message); ?></span>
                                        <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                    </div>
                                </div>
                                <div class="col-12">
                                    <div class="input-style-1">
                                        <label>Confirmation Mot de passe</label>
                                        <input type="password" name="password_confirmation" class="form-control" placeholder="Confirmer votre mot de passe">
                                        <?php $__errorArgs = ['password_confirmation'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                        <span class="text-danger"><?php echo e($message); ?></span>
                                        <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                    </div>
                                </div>
                                <!-- end col -->

                                <!-- end col -->
                                <div class="col-12">
                                    <div class="button-group d-flex justify-content-center flex-wrap">
                                        <button class="main-btn success-btn btn-hover w-100 text-center">
                                            VALIDER
                                        </button>
                                    </div>
                                </div>
                            </div>
                            <!-- end row -->
                        </form>

                    </div>
                </div>
            </div>
            <!-- end col -->
        </div>
        <!-- end row -->
    </div>
</section>
<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.base', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /var/www/html/resources/views/comptes/modifierMotDePasse.blade.php ENDPATH**/ ?>