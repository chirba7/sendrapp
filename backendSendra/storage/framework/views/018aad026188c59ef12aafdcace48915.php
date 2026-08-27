<!-- See https://rapidocweb.com/api.html for options -->
<!doctype html> <!-- Important: must specify -->
<html>
<head>
    <meta charset="utf-8"> <!-- Important: rapi-doc uses utf8 characters -->
    <script type="module" src="https://unpkg.com/rapidoc/dist/rapidoc-min.js"></script>
</head>
<body>
<rapi-doc
<?php $__currentLoopData = $htmlAttributes; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $attribute => $value): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
    
    <?php echo $attribute; ?>="<?php echo $value; ?>"
<?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
    spec-url="<?php echo $metadata['openapi_spec_url']; ?>"
    render-style="read"
    allow-try="<?php echo ($tryItOut['enabled'] ?? true) ? 'true' : 'false'; ?>"
>
    <?php if($metadata['logo']): ?>
        <img slot="logo" src="<?php echo $metadata['logo']; ?>"/>
    <?php endif; ?>
</rapi-doc>
</body>
</html>
<?php /**PATH /var/www/html/vendor/knuckleswtf/scribe/resources/views/external/rapidoc.blade.php ENDPATH**/ ?>