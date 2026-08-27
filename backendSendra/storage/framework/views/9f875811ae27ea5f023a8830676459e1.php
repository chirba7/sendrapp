<!-- See https://github.com/stoplightio/elements/blob/main/docs/getting-started/elements/elements-options.md for config -->
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title><?php echo $metadata['title']; ?></title>
    <!-- Embed elements Elements via Web Component -->
    <script src="https://unpkg.com/@stoplight/elements/web-components.min.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/@stoplight/elements/styles.min.css">
    <style>
        body {
            height: 100vh;
        }
    </style>
</head>
<body>

<elements-api
<?php $__currentLoopData = $htmlAttributes; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $attribute => $value): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
    
    <?php echo $attribute; ?>="<?php echo $value; ?>"
<?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
    apiDescriptionUrl="<?php echo $metadata['openapi_spec_url']; ?>"
    router="hash"
    layout="sidebar"
    hideTryIt="<?php echo ($tryItOut['enabled'] ?? true) ? '' : 'true'; ?>"
<?php if(!empty($metadata['logo'])): ?>
    logo="<?php echo $metadata['logo']; ?>"
<?php endif; ?>
/>

</body>
</html>
<?php /**PATH /var/www/html/vendor/knuckleswtf/scribe/resources/views/external/elements.blade.php ENDPATH**/ ?>