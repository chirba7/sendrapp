<div id="sidebar" class="sl-flex sl-overflow-y-auto sl-flex-col sl-sticky sl-inset-y-0 sl-pt-8 sl-bg-canvas-100 sl-border-r"
     style="width: calc((100% - 1800px) / 2 + 300px); padding-left: calc((100% - 1800px) / 2); min-width: 300px; max-height: 100vh">
    <div class="sl-flex sl-items-center sl-mb-5 sl-ml-4">
        <?php if($metadata['logo'] != false): ?>
            <div class="sl-inline sl-overflow-x-hidden sl-overflow-y-hidden sl-mr-3 sl-rounded-lg"
                 style="background-color: transparent;">
                <img src="<?php echo e($metadata['logo']); ?>" height="30px" width="30px" alt="logo">
            </div>
        <?php endif; ?>
        <h4 class="sl-text-paragraph sl-leading-snug sl-font-prose sl-font-semibold sl-text-heading">
            <?php echo e($metadata['title']); ?>

        </h4>
    </div>

    <div class="sl-flex sl-overflow-y-auto sl-flex-col sl-flex-grow sl-flex-shrink">
        <div class="sl-overflow-y-auto sl-w-full sl-bg-canvas-100">
            <div class="sl-my-3">
                <?php $__currentLoopData = $headings; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $h1): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                    <div class="expandable">
                        <div title="<?php echo $h1['name']; ?>" id="toc-item-<?php echo $h1['slug']; ?>"
                             class="sl-flex sl-items-center sl-h-md sl-pr-4 sl-pl-4 sl-bg-canvas-100 hover:sl-bg-canvas-200 sl-cursor-pointer sl-select-none">
                            <a href="#<?php echo $h1['slug']; ?>"
                               class="sl-flex-1 sl-items-center sl-truncate sl-mr-1.5 sl-p-0"><?php echo $h1['name']; ?></a>
                            <?php if(count($h1['subheadings']) > 0): ?>
                                <div class="sl-flex sl-items-center sl-text-xs expansion-chevrons">
                                    <svg aria-hidden="true" focusable="false" data-prefix="fas"
                                         data-icon="chevron-right"
                                         class="svg-inline--fa fa-chevron-right fa-fw sl-icon sl-text-muted"
                                         xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
                                        <path fill="currentColor"
                                              d="M96 480c-8.188 0-16.38-3.125-22.62-9.375c-12.5-12.5-12.5-32.75 0-45.25L242.8 256L73.38 86.63c-12.5-12.5-12.5-32.75 0-45.25s32.75-12.5 45.25 0l192 192c12.5 12.5 12.5 32.75 0 45.25l-192 192C112.4 476.9 104.2 480 96 480z"></path>
                                    </svg>
                                </div>
                            <?php endif; ?>
                        </div>

                        <?php if(count($h1['subheadings']) > 0): ?>
                            <div class="children" style="display: none;">
                                <?php $__currentLoopData = $h1['subheadings']; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $h2): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                    <div class="expandable">
                                        <div class="sl-flex sl-items-center sl-h-md sl-pr-4 sl-pl-8 sl-bg-canvas-100 hover:sl-bg-canvas-200 sl-cursor-pointer sl-select-none"
                                             id="toc-item-<?php echo $h2['slug']; ?>">
                                            <div class="sl-flex-1 sl-items-center sl-truncate sl-mr-1.5 sl-p-0" title="<?php echo $h2['name']; ?>">
                                                <a class="ElementsTableOfContentsItem sl-block sl-no-underline"
                                                   href="#<?php echo $h2['slug']; ?>">
                                                    <?php echo $h2['name']; ?>

                                                </a>
                                            </div>
                                            <?php if(count($h2['subheadings']) > 0): ?>
                                                <div class="sl-flex sl-items-center sl-text-xs expansion-chevrons">
                                                    <svg aria-hidden="true" focusable="false" data-prefix="fas"
                                                         data-icon="chevron-right"
                                                         class="svg-inline--fa fa-chevron-right fa-fw sl-icon sl-text-muted"
                                                         xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
                                                        <path fill="currentColor"
                                                              d="M96 480c-8.188 0-16.38-3.125-22.62-9.375c-12.5-12.5-12.5-32.75 0-45.25L242.8 256L73.38 86.63c-12.5-12.5-12.5-32.75 0-45.25s32.75-12.5 45.25 0l192 192c12.5 12.5 12.5 32.75 0 45.25l-192 192C112.4 476.9 104.2 480 96 480z"></path>
                                                    </svg>
                                                </div>
                                            <?php endif; ?>
                                        </div>

                                        <?php if(count($h2['subheadings']) > 0): ?>
                                            <div class="children" style="display: none;">
                                                <?php $__currentLoopData = $h2['subheadings']; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $h3): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                                    <a class="ElementsTableOfContentsItem sl-block sl-no-underline"
                                                       href="#<?php echo $h3['slug']; ?>">
                                                        <div title="<?php echo $h3['name']; ?>" id="toc-item-<?php echo $h3['slug']; ?>"
                                                             class="sl-flex sl-items-center sl-h-md sl-pr-4 sl-pl-12 sl-bg-canvas-100 hover:sl-bg-canvas-200 sl-cursor-pointer sl-select-none">
                                                            <?php echo $h3['name']; ?>

                                                        </div>
                                                    </a>
                                                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                                            </div>
                                        <?php endif; ?>
                                    </div>
                                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                            </div>
                        <?php endif; ?>
                    </div>
                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
            </div>

        </div>
        <div class="sl-flex sl-items-center sl-px-4 sl-py-3 sl-border-t">
            <?php echo e($metadata['last_updated']); ?>

        </div>

        <div class="sl-flex sl-items-center sl-px-4 sl-py-3 sl-border-t">
            <a href="http://github.com/knuckleswtf/scribe">Documentation powered by Scribe ✍</a>
        </div>
    </div>
</div>
<?php /**PATH /var/www/html/vendor/knuckleswtf/scribe/resources/views/themes/elements/sidebar.blade.php ENDPATH**/ ?>