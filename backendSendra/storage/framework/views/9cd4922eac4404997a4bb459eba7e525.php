<?php $__currentLoopData = $groupedEndpoints; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $group): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
    <h1 id="<?php echo Str::slug($group['name']); ?>"
        class="sl-text-5xl sl-leading-tight sl-font-prose sl-text-heading"
    >
        <?php echo $group['name']; ?>

    </h1>

    <?php echo Parsedown::instance()->text($group['description']); ?>


    <?php $__currentLoopData = $group['subgroups']; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $subgroupName => $subgroup): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
        <?php if($subgroupName !== ""): ?>
            <h2 id="<?php echo Str::slug($group['name']); ?>-<?php echo Str::slug($subgroupName); ?>"
                class="sl-text-3xl sl-leading-tight sl-font-prose sl-text-heading sl-mt-5 sl-mb-3"
            >
                <?php echo e($subgroupName); ?>

            </h2>
            <?php ($subgroupDescription = collect($subgroup)->first(fn ($e) => $e->metadata->subgroupDescription)?->metadata?->subgroupDescription); ?>
            <?php if($subgroupDescription): ?>
                <?php echo Parsedown::instance()->text($subgroupDescription); ?>

            <?php endif; ?>
            <br>
        <?php endif; ?>
        <?php $__currentLoopData = $subgroup; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $endpoint): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
            <?php echo $__env->make("scribe::themes.elements.endpoint", \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?>
        <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
    <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
<?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>

<?php /**PATH /var/www/html/vendor/knuckleswtf/scribe/resources/views/themes/elements/groups.blade.php ENDPATH**/ ?>