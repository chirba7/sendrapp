<!doctype html>
<html>
<head>
    <title><?php echo $metadata['title']; ?></title>
    <meta charset="utf-8"/>
    <meta
        name="viewport"
        content="width=device-width, initial-scale=1"/>
    <style>
        body {
            margin: 0;
        }
    </style>
</head>
<body>

<script
    id="api-reference"
<?php $__currentLoopData = $htmlAttributes; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $attribute => $value): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
    
    <?php echo $attribute; ?>="<?php echo $value; ?>"
<?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
    data-url="<?php echo $metadata['openapi_spec_url']; ?>">
</script>
<script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
</body>
</html>
<?php /**PATH /var/www/html/vendor/knuckleswtf/scribe/resources/views/external/scalar.blade.php ENDPATH**/ ?>