<?php
    use Knuckles\Scribe\Tools\Utils as u;
    /** @var \Knuckles\Camel\Output\OutputEndpointData $endpoint */
?>

<div class="sl-inverted">
    <div class="sl-overflow-y-hidden sl-rounded-lg">
        <form class="TryItPanel sl-bg-canvas-100 sl-rounded-lg"
              data-method="<?php echo e($endpoint->httpMethods[0]); ?>"
              data-path="<?php echo e($endpoint->uri); ?>"
              data-hasfiles="<?php echo e($endpoint->hasFiles() ? 1 : 0); ?>"
              data-hasjsonbody="<?php echo e($endpoint->hasJsonBody() ? 1 : 0); ?>">
            <?php if($endpoint->isAuthed() && $metadata['auth']['location'] !== 'body'): ?>
                <div class="sl-panel sl-outline-none sl-w-full expandable">
                    <div class="sl-panel__titlebar sl-flex sl-items-center sl-relative focus:sl-z-10 sl-text-base sl-leading-none sl-pr-4 sl-pl-3 sl-bg-canvas-200 sl-text-body sl-border-input focus:sl-border-primary sl-cursor-pointer sl-select-none"
                         role="button">
                        <div class="sl-flex sl-flex-1 sl-items-center sl-h-lg">
                            <div class="sl-flex sl-items-center sl-mr-1.5 expansion-chevrons expansion-chevrons-solid expanded">
                                <svg aria-hidden="true" focusable="false" data-prefix="fas"
                                     data-icon="caret-down"
                                     class="svg-inline--fa fa-caret-down fa-fw sl-icon" role="img"
                                     xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
                                    <path fill="currentColor"
                                          d="M310.6 246.6l-127.1 128C176.4 380.9 168.2 384 160 384s-16.38-3.125-22.63-9.375l-127.1-128C.2244 237.5-2.516 223.7 2.438 211.8S19.07 192 32 192h255.1c12.94 0 24.62 7.781 29.58 19.75S319.8 237.5 310.6 246.6z"></path>
                                </svg>
                            </div>
                            Auth
                        </div>
                    </div>
                    <div class="sl-panel__content-wrapper sl-bg-canvas-100 children" role="region">
                        <div class="ParameterGrid sl-p-4">
                            <label aria-hidden="true"
                                   for="auth-<?php echo e($endpoint->endpointId()); ?>"><?php echo e($metadata['auth']['name']); ?></label>
                            <span class="sl-mx-3">:</span>
                            <div class="sl-flex sl-flex-1">
                                <div class="sl-input sl-flex-1 sl-relative">
                                    <code><?php echo e($metadata['auth']['prefix']); ?></code>
                                    <input aria-label="<?php echo e($metadata['auth']['name']); ?>"
                                           id="auth-<?php echo e($endpoint->endpointId()); ?>"
                                           data-component="<?php echo e($metadata['auth']['location']); ?>"
                                           data-prefix="<?php echo e($metadata['auth']['prefix']); ?>"
                                           name="<?php echo e($metadata['auth']['name']); ?>"
                                           placeholder="<?php echo e($metadata['auth']['placeholder']); ?>"
                                           class="auth-value sl-relative <?php echo e($metadata['auth']['prefix'] ? 'sl-w-3/5' : 'sl-w-full sl-pr-2.5 sl-pl-2.5'); ?> sl-h-md sl-text-base sl-rounded sl-border-transparent hover:sl-border-input focus:sl-border-primary sl-border">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            <?php endif; ?>

            <?php if(count($endpoint->headers)): ?>
                <div class="sl-panel sl-outline-none sl-w-full expandable">
                    <div class="sl-panel__titlebar sl-flex sl-items-center sl-relative focus:sl-z-10 sl-text-base sl-leading-none sl-pr-4 sl-pl-3 sl-bg-canvas-200 sl-text-body sl-border-input focus:sl-border-primary sl-cursor-pointer sl-select-none"
                         role="button">
                        <div class="sl-flex sl-flex-1 sl-items-center sl-h-lg">
                            <div class="sl-flex sl-items-center sl-mr-1.5 expansion-chevrons expansion-chevrons-solid expanded">
                                <svg aria-hidden="true" focusable="false" data-prefix="fas"
                                     data-icon="caret-down"
                                     class="svg-inline--fa fa-caret-down fa-fw sl-icon" role="img"
                                     xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
                                    <path fill="currentColor"
                                          d="M310.6 246.6l-127.1 128C176.4 380.9 168.2 384 160 384s-16.38-3.125-22.63-9.375l-127.1-128C.2244 237.5-2.516 223.7 2.438 211.8S19.07 192 32 192h255.1c12.94 0 24.62 7.781 29.58 19.75S319.8 237.5 310.6 246.6z"></path>
                                </svg>
                            </div>
                            Headers
                        </div>
                    </div>
                    <div class="sl-panel__content-wrapper sl-bg-canvas-100 children" role="region">
                        <div class="ParameterGrid sl-p-4">
                            <?php $__currentLoopData = $endpoint->headers; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $name => $example): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                <?php
                                    if($endpoint->isAuthed() && $metadata['auth']['location'] === 'header' && $name === $metadata['auth']['name']) continue;
                                ?>
                                <label aria-hidden="true"
                                       for="header-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"><?php echo e($name); ?></label>
                                <span class="sl-mx-3">:</span>
                                <div class="sl-flex sl-flex-1">
                                    <div class="sl-input sl-flex-1 sl-relative">
                                        <input aria-label="<?php echo e($name); ?>" name="<?php echo e($name); ?>"
                                               id="header-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"
                                               value="<?php echo e($example); ?>" data-component="header"
                                               class="sl-relative sl-w-full sl-h-md sl-text-base sl-pr-2.5 sl-pl-2.5 sl-rounded sl-border-transparent hover:sl-border-input focus:sl-border-primary sl-border">
                                    </div>
                                </div>
                            <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                        </div>
                    </div>
                </div>
            <?php endif; ?>

            <?php if(count($endpoint->urlParameters)): ?>
                <div class="sl-panel sl-outline-none sl-w-full expandable">
                    <div class="sl-panel__titlebar sl-flex sl-items-center sl-relative focus:sl-z-10 sl-text-base sl-leading-none sl-pr-4 sl-pl-3 sl-bg-canvas-200 sl-text-body sl-border-input focus:sl-border-primary sl-cursor-pointer sl-select-none"
                         role="button">
                        <div class="sl-flex sl-flex-1 sl-items-center sl-h-lg">
                            <div class="sl-flex sl-items-center sl-mr-1.5 expansion-chevrons expansion-chevrons-solid expanded">
                                <svg aria-hidden="true" focusable="false" data-prefix="fas"
                                     data-icon="caret-down"
                                     class="svg-inline--fa fa-caret-down fa-fw sl-icon" role="img"
                                     xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
                                    <path fill="currentColor"
                                          d="M310.6 246.6l-127.1 128C176.4 380.9 168.2 384 160 384s-16.38-3.125-22.63-9.375l-127.1-128C.2244 237.5-2.516 223.7 2.438 211.8S19.07 192 32 192h255.1c12.94 0 24.62 7.781 29.58 19.75S319.8 237.5 310.6 246.6z"></path>
                                </svg>
                            </div>
                            URL Parameters
                        </div>
                    </div>
                    <div class="sl-panel__content-wrapper sl-bg-canvas-100 children" role="region">
                        <div class="ParameterGrid sl-p-4">
                            <?php $__currentLoopData = $endpoint->urlParameters; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $name => $parameter): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                <label aria-hidden="true"
                                       for="urlparam-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"><?php echo e($name); ?></label>
                                <span class="sl-mx-3">:</span>
                                <div class="sl-flex sl-flex-1">
                                    <div class="sl-input sl-flex-1 sl-relative">
                                        <input aria-label="<?php echo e($name); ?>" name="<?php echo e($name); ?>"
                                               id="urlparam-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"
                                               placeholder="<?php echo e($parameter->description); ?>"
                                               value="<?php echo e($parameter->example); ?>" data-component="url"
                                               class="sl-relative sl-w-full sl-h-md sl-text-base sl-pr-2.5 sl-pl-2.5 sl-rounded sl-border-transparent hover:sl-border-input focus:sl-border-primary sl-border">
                                    </div>
                                </div>
                            <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                        </div>
                    </div>
                </div>
            <?php endif; ?>

            <?php if(count($endpoint->queryParameters)): ?>
                <div class="sl-panel sl-outline-none sl-w-full expandable">
                    <div class="sl-panel__titlebar sl-flex sl-items-center sl-relative focus:sl-z-10 sl-text-base sl-leading-none sl-pr-4 sl-pl-3 sl-bg-canvas-200 sl-text-body sl-border-input focus:sl-border-primary sl-cursor-pointer sl-select-none"
                         role="button">
                        <div class="sl-flex sl-flex-1 sl-items-center sl-h-lg">
                            <div class="sl-flex sl-items-center sl-mr-1.5 expansion-chevrons expansion-chevrons-solid expanded">
                                <svg aria-hidden="true" focusable="false" data-prefix="fas"
                                     data-icon="caret-down"
                                     class="svg-inline--fa fa-caret-down fa-fw sl-icon" role="img"
                                     xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
                                    <path fill="currentColor"
                                          d="M310.6 246.6l-127.1 128C176.4 380.9 168.2 384 160 384s-16.38-3.125-22.63-9.375l-127.1-128C.2244 237.5-2.516 223.7 2.438 211.8S19.07 192 32 192h255.1c12.94 0 24.62 7.781 29.58 19.75S319.8 237.5 310.6 246.6z"></path>
                                </svg>
                            </div>
                            Query Parameters
                        </div>
                    </div>
                    <div class="sl-panel__content-wrapper sl-bg-canvas-100 children" role="region">
                        <div class="ParameterGrid sl-p-4">
                            <?php $__currentLoopData = $endpoint->queryParameters; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $name => $parameter): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                <?php
                                    /** @var \Knuckles\Camel\Output\Parameter $parameter */
                                    if ($parameter->type == 'object') // Skip; individual object children are listed
                                        continue;
                                    if (str_contains($name, "[]"))
                                        // This likely belongs to an obj-array (eg objs[].a); we only show the parent (objs[]), so skip
                                        continue;
                                    if($endpoint->isAuthed() && $metadata['auth']['location'] === 'query'
                                    && $name === $metadata['auth']['name']) continue;
                                ?>
                                <label aria-hidden="true"
                                       for="queryparam-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"><?php echo e($name); ?></label>
                                <span class="sl-mx-3">:</span>
                                <div class="sl-flex sl-flex-1">
                                    <div class="sl-input sl-flex-1 sl-relative">
                                        <?php if(str_ends_with($parameter->type, '[]')): ?>
                                            <input aria-label="<?php echo e($name); ?>" name="<?php echo e($name); ?>"
                                                   id="queryparam-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"
                                                   placeholder="<?php echo e($parameter->description); ?>"
                                                   value="<?php echo e(json_encode($parameter->example)); ?>" data-component="query"
                                                   class="sl-relative sl-w-full sl-h-md sl-text-base sl-pr-2.5 sl-pl-2.5 sl-rounded sl-border-transparent hover:sl-border-input focus:sl-border-primary sl-border"
                                            >
                                        <?php else: ?>
                                            <input aria-label="<?php echo e($name); ?>" name="<?php echo e($name); ?>"
                                                   id="queryparam-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"
                                                   placeholder="<?php echo e($parameter->description); ?>"
                                                   value="<?php echo e($parameter->example); ?>" data-component="query"
                                                   class="sl-relative sl-w-full sl-h-md sl-text-base sl-pr-2.5 sl-pl-2.5 sl-rounded sl-border-transparent hover:sl-border-input focus:sl-border-primary sl-border"
                                            >
                                        <?php endif; ?>
                                    </div>
                                </div>
                            <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                        </div>
                    </div>
                </div>
            <?php endif; ?>

            <?php if(count($endpoint->bodyParameters)): ?>
                <div class="sl-panel sl-outline-none sl-w-full expandable">
                    <div class="sl-panel__titlebar sl-flex sl-items-center sl-relative focus:sl-z-10 sl-text-base sl-leading-none sl-pr-4 sl-pl-3 sl-bg-canvas-200 sl-text-body sl-border-input focus:sl-border-primary sl-cursor-pointer sl-select-none"
                         role="button">
                        <div class="sl-flex sl-flex-1 sl-items-center sl-h-lg">
                            <div class="sl-flex sl-items-center sl-mr-1.5 expansion-chevrons expansion-chevrons-solid expanded">
                                <svg aria-hidden="true" focusable="false" data-prefix="fas"
                                     data-icon="caret-down"
                                     class="svg-inline--fa fa-caret-down fa-fw sl-icon" role="img"
                                     xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
                                    <path fill="currentColor"
                                          d="M310.6 246.6l-127.1 128C176.4 380.9 168.2 384 160 384s-16.38-3.125-22.63-9.375l-127.1-128C.2244 237.5-2.516 223.7 2.438 211.8S19.07 192 32 192h255.1c12.94 0 24.62 7.781 29.58 19.75S319.8 237.5 310.6 246.6z"></path>
                                </svg>
                            </div>
                            Body
                        </div>
                    </div>
                    <div class="sl-panel__content-wrapper sl-bg-canvas-100 children" role="region">
                        <?php if($endpoint->hasJsonBody()): ?>
                            <div class="TextRequestBody sl-p-4">
                                <div class="code-editor language-json"
                                     id="json-body-<?php echo e($endpoint->endpointId()); ?>"
                                     style="font-family: var(--font-code); font-size: 12px; line-height: var(--lh-code);"
                                ><?php echo json_encode($endpoint->getSampleBody(), JSON_PRETTY_PRINT); ?></div>
                            </div>
                        <?php else: ?>
                            <div class="ParameterGrid sl-p-4">
                                <?php $__currentLoopData = $endpoint->bodyParameters; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $name => $parameter): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                    <?php
                                        /** @var \Knuckles\Camel\Output\Parameter $parameter */
                                        if ($parameter->type == 'object') // Skip; individual object children are listed
                                            continue;
                                        if (str_contains($name, "[]"))
                                            // This likely belongs to an obj-array (eg objs[].a); we only show the parent (objs[]), so skip
                                            continue;
                                    ?>
                                    <label aria-hidden="true"
                                           for="bodyparam-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"><?php echo e($name); ?></label>
                                    <span class="sl-mx-3">:</span>
                                    <div class="sl-flex sl-flex-1">
                                        <div class="sl-input sl-flex-1 sl-relative">
                                            <?php if($parameter->type == 'file'): ?>
                                                <input aria-label="<?php echo e($name); ?>" name="<?php echo e($name); ?>"
                                                       id="bodyparam-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"
                                                       type="file" data-component="body"
                                                       class="sl-relative sl-w-full sl-h-md sl-text-base sl-pr-2.5 sl-pl-2.5 sl-rounded sl-border-transparent hover:sl-border-input focus:sl-border-primary sl-border"
                                                >
                                            <?php elseif(str_ends_with($parameter->type, '[]')): ?>
                                                <input aria-label="<?php echo e($name); ?>" name="<?php echo e($name); ?>"
                                                       id="bodyparam-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"
                                                       placeholder="<?php echo e($parameter->description); ?>"
                                                       value="<?php echo e(json_encode($parameter->example)); ?>" data-component="body"
                                                       class="sl-relative sl-w-full sl-h-md sl-text-base sl-pr-2.5 sl-pl-2.5 sl-rounded sl-border-transparent hover:sl-border-input focus:sl-border-primary sl-border"
                                                >
                                            <?php else: ?>
                                                <input aria-label="<?php echo e($name); ?>" name="<?php echo e($name); ?>"
                                                       id="bodyparam-<?php echo e($endpoint->endpointId()); ?>-<?php echo e($name); ?>"
                                                       placeholder="<?php echo e($parameter->description); ?>"
                                                       value="<?php echo e($parameter->example); ?>" data-component="body"
                                                       class="sl-relative sl-w-full sl-h-md sl-text-base sl-pr-2.5 sl-pl-2.5 sl-rounded sl-border-transparent hover:sl-border-input focus:sl-border-primary sl-border"
                                                >
                                            <?php endif; ?>
                                        </div>
                                    </div>
                                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                            </div>
                        <?php endif; ?>
                    </div>
                </div>
            <?php endif; ?>

            <div class="SendButtonHolder sl-mt-4 sl-p-4 sl-pt-0">
                <div class="sl-stack sl-stack--horizontal sl-stack--2 sl-flex sl-flex-row sl-items-center">
                    <button type="button" data-endpoint="<?php echo e($endpoint->endpointId()); ?>"
                            class="tryItOut-btn sl-button sl-h-sm sl-text-base sl-font-medium sl-px-1.5 sl-bg-primary hover:sl-bg-primary-dark active:sl-bg-primary-darker disabled:sl-bg-canvas-100 sl-text-on-primary disabled:sl-text-body sl-rounded sl-border-transparent sl-border disabled:sl-opacity-70"
                    >
                        <?php echo e(u::trans("scribe::try_it_out.send")); ?>

                    </button>
                </div>
            </div>

            <div data-endpoint="<?php echo e($endpoint->endpointId()); ?>"
                 class="tryItOut-error expandable sl-panel sl-outline-none sl-w-full" hidden>
                <div class="sl-panel__titlebar sl-flex sl-items-center sl-relative focus:sl-z-10 sl-text-base sl-leading-none sl-pr-4 sl-pl-3 sl-bg-canvas-200 sl-text-body sl-border-input focus:sl-border-primary sl-cursor-pointer sl-select-none"
                     role="button">
                    <div class="sl-flex sl-flex-1 sl-items-center sl-h-lg">
                        <div class="sl-flex sl-items-center sl-mr-1.5 expansion-chevrons expansion-chevrons-solid expanded">
                            <svg aria-hidden="true" focusable="false" data-prefix="fas"
                                 data-icon="caret-down"
                                 class="svg-inline--fa fa-caret-down fa-fw sl-icon" role="img"
                                 xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
                                <path fill="currentColor"
                                      d="M310.6 246.6l-127.1 128C176.4 380.9 168.2 384 160 384s-16.38-3.125-22.63-9.375l-127.1-128C.2244 237.5-2.516 223.7 2.438 211.8S19.07 192 32 192h255.1c12.94 0 24.62 7.781 29.58 19.75S319.8 237.5 310.6 246.6z"></path>
                            </svg>
                        </div>
                        <?php echo e(u::trans("scribe::try_it_out.request_failed")); ?>

                    </div>
                </div>
                <div class="sl-panel__content-wrapper sl-bg-canvas-100 children" role="region">
                    <div class="sl-panel__content sl-p-4">
                        <p class="sl-pb-2"><strong class="error-message"></strong></p>
                        <p class="sl-pb-2"><?php echo e(u::trans("scribe::try_it_out.error_help")); ?></p>
                    </div>
                </div>
            </div>

                <div data-endpoint="<?php echo e($endpoint->endpointId()); ?>"
                     class="tryItOut-response expandable sl-panel sl-outline-none sl-w-full" hidden>
                    <div class="sl-panel__titlebar sl-flex sl-items-center sl-relative focus:sl-z-10 sl-text-base sl-leading-none sl-pr-4 sl-pl-3 sl-bg-canvas-200 sl-text-body sl-border-input focus:sl-border-primary sl-cursor-pointer sl-select-none"
                         role="button">
                        <div class="sl-flex sl-flex-1 sl-items-center sl-h-lg">
                            <div class="sl-flex sl-items-center sl-mr-1.5 expansion-chevrons expansion-chevrons-solid expanded">
                                <svg aria-hidden="true" focusable="false" data-prefix="fas"
                                     data-icon="caret-down"
                                     class="svg-inline--fa fa-caret-down fa-fw sl-icon" role="img"
                                     xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 512">
                                    <path fill="currentColor"
                                          d="M310.6 246.6l-127.1 128C176.4 380.9 168.2 384 160 384s-16.38-3.125-22.63-9.375l-127.1-128C.2244 237.5-2.516 223.7 2.438 211.8S19.07 192 32 192h255.1c12.94 0 24.62 7.781 29.58 19.75S319.8 237.5 310.6 246.6z"></path>
                                </svg>
                            </div>
                            <?php echo e(u::trans("scribe::try_it_out.received_response")); ?>

                        </div>
                    </div>
                    <div class="sl-panel__content-wrapper sl-bg-canvas-100 children" role="region">
                        <div class="sl-panel__content sl-p-4">
                            <p class="sl-pb-2 response-status"></p>
                            <pre><code class="sl-pb-2 response-content language-json"
                                       data-empty-response-text="<<?php echo e(u::trans("scribe::endpoint.responses.empty")); ?>>"
                                       style="max-height: 300px;"></code></pre>
                        </div>
                    </div>
                </div>
        </form>
    </div>
</div>
<?php /**PATH /var/www/html/vendor/knuckleswtf/scribe/resources/views/themes/elements/try_it_out.blade.php ENDPATH**/ ?>