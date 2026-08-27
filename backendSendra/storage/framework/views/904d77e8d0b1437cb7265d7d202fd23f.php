<?php
    $level ??= 0;
    $levelNestingClass = match($level) {
        0 => "sl-ml-px",
        default => "sl-ml-7"
    };
    $expandable ??= !isset($fields["[]"]);
?>

<?php $__currentLoopData = $fields; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $name => $field): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
    <div class="<?php echo e($expandable ? 'expandable' : ''); ?> sl-text-sm sl-border-l <?php echo e($levelNestingClass); ?>">
        <?php $__env->startComponent('scribe::themes.elements.components.field-details', [
          'name' => $name,
          'type' => $field['type'] ?? 'string',
          'required' => $field['required'] ?? false,
          'description' => $field['description'] ?? '',
          'example' => $field['example'] ?? '',
          'enumValues' => $field['enumValues'] ?? null,
          'endpointId' => $endpointId,
          'hasChildren' => !empty($field['__fields']),
          'component' => 'body',
        ]); ?>
        <?php echo $__env->renderComponent(); ?>

        <?php if(!empty($field['__fields'])): ?>
            <div class="children" style="<?php echo e($expandable ? 'display: none;' : ''); ?>">
                <?php $__env->startComponent('scribe::themes.elements.components.nested-fields', [
                  'fields' => $field['__fields'],
                  'endpointId' => $endpointId,
                  'level' => $level + 1,
                  'expandable'=> $expandable,
                ]); ?>
                <?php echo $__env->renderComponent(); ?>
            </div>
        <?php endif; ?>
    </div>
<?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
<?php /**PATH /var/www/html/vendor/knuckleswtf/scribe/resources/views/themes/elements/components/nested-fields.blade.php ENDPATH**/ ?>