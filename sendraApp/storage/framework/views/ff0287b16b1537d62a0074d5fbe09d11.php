<?php $__env->startSection('contenu'); ?>
<section class="signin-section">
    <div class="container mt-5">
        <div class="title-wrapper pt-30">
            <div class="col-md-12">
                <?php if(session('success')): ?> <div class="alert-box success-alert pl-100">
                    <div class="alert">
                        <p class="text-medium">
                            <?php echo e(session('success')); ?>

                        </p>
                    </div>
                </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
    <div class="row g-0 auth-row">
        <div class="col-lg-6">
            <div class="auth-cover-wrapper bg-success-100">
                <div class="auth-cover">
                    <div class="title text-center">
                        <h1 class="text-success mb-10">Bienvenue</h1>
                        <p class="text-medium">
                            Connectez-vous à votre compte existant pour continuer.
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
                        <img src="<?php echo e(asset('img/EPAVIE.png')); ?>" alt="" width="50%" height="50%">
                    </div>
                    <h2 class="mb-25 text-center">Connexion</h2>
                    <form method="POST" action="<?php echo e(route('login')); ?>">
                        <?php echo csrf_field(); ?>
                        <div class="row">
                            <div class="col-12">
                                <div class="input-style-1">
                                    <label>Email</label>
                                    <input type="email" name="email" :value="old('email')" class="form-control" placeholder="Enter your email">
                                    <?php $__errorArgs = ['email'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                    <div class="text-danger"><?php echo e($message); ?></div>
                                    <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                </div>
                            </div>
                            <!-- end col -->
                            <div class="col-12">
                                <div class="input-style-1">
                                    <label>Mot de passe</label>
                                    <input type="password" name="password" class="form-control" placeholder="Password">
                                    <?php $__errorArgs = ['password'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                    <div class="text-danger"><?php echo e($message); ?></div>
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
                                        Connexion
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
<?php echo $__env->make('layouts.base', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /var/www/html/resources/views/auth/login.blade.php ENDPATH**/ ?>