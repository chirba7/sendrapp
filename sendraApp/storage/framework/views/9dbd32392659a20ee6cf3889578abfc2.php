<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link href="<?php echo e(asset('img/sendra.ico')); ?>" rel="icon">
    <title>SENDRA APP</title>

    <!-- ========== All CSS files linkup ========= -->
    <link rel="stylesheet" href="<?php echo e(asset('assets/css/lineicons.css')); ?>" rel="stylesheet" type="text/css" />
    <link rel="stylesheet" href="<?php echo e(asset('assets/css/materialdesignicons.min.css')); ?>" rel="stylesheet" type="text/css" />
    <link rel="stylesheet" href="<?php echo e(asset('assets/css/bootstrap.min.css')); ?>" />
    <link rel="stylesheet" href="<?php echo e(asset('assets/css/fullcalendar.css')); ?>" />
    <link rel="stylesheet" href="<?php echo e(asset('assets/css/fullcalendar.css')); ?>" />
    <link rel="stylesheet" href="<?php echo e(asset('assets/css/main.css')); ?>" />
    
    <link rel="stylesheet" href="<?php echo e(asset('assets/css/sendra-refresh.css')); ?>?v=1" />
    <meta name="csrf-token" content="<?php echo e(csrf_token()); ?>">
    <style>
        #signature-pad {
            text-align: center;
            margin-bottom: 20px;
        }

        #signature-canvas {
            border: 1px solid #000;
            background-color: #fff;
            cursor: crosshair;
        }
    </style>
</head>

<body>
    <!-- ======== Preloader =========== -->
    <div id="preloader">
        <div class="spinner"></div>
    </div>
    <!-- ======== Preloader =========== -->
    <?php echo $__env->yieldContent('contenu'); ?>


    <!-- ========= All Javascript files linkup ======== -->
    <script src="<?php echo e(asset('assets/js/bootstrap.bundle.min.js')); ?>"></script>
    <script src="<?php echo e(asset('assets/js/Chart.min.js')); ?>"></script>
    <script src="<?php echo e(asset('assets/js/dynamic-pie-chart.js')); ?>"></script>
    <script src="<?php echo e(asset('assets/js/moment.min.js')); ?>"></script>
    <script src="<?php echo e(asset('assets/js/fullcalendar.js')); ?>"></script>
    <script src="<?php echo e(asset('assets/js/jvectormap.min.js')); ?>"></script>
    <script src="<?php echo e(asset('assets/js/world-merc.js')); ?>"></script>
    <script src="<?php echo e(asset('assets/js/polyfill.js')); ?>"></script>
    <script src="<?php echo e(asset('assets/js/main.js')); ?>"></script>

</body>

</html><?php /**PATH C:\Projets\sendrapp\sendra\sendraApp\resources\views/layouts/base.blade.php ENDPATH**/ ?>