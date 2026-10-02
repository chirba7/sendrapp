<?php $__env->startSection('session'); ?>
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<section class="section"><div class="container-fluid">
    <div class="title-wrapper pt-30"><h2 class="text-success"><?php echo e($site->exists ? 'Modifier le site' : 'Créer un site de pointage'); ?></h2></div>
    <?php echo $__env->make('attendance.nav', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?>
    <form class="card-style" method="POST" action="<?php echo e($site->exists ? route('attendance.sites.update', $site) : route('attendance.sites.store')); ?>">
        <?php echo csrf_field(); ?> <?php if($site->exists): ?> <?php echo method_field('PUT'); ?> <?php endif; ?>
        <div class="row g-3">
            <div class="col-md-6"><label for="name" class="form-label">Nom du site</label><input id="name" name="name" class="form-control" value="<?php echo e(old('name', $site->name)); ?>" maxlength="255" required></div>
            <div class="col-md-6"><label for="address" class="form-label">Adresse</label><input id="address" name="address" class="form-control" value="<?php echo e(old('address', $site->address)); ?>" maxlength="255"></div>
            <div class="col-12"><p>Cliquez sur la carte pour placer le point de référence, ou saisissez ses coordonnées. Le cercle représente le rayon autorisé lors du pointage.</p><div id="attendance-map" style="height:360px;border-radius:12px" aria-label="Position du site"></div><p id="map-message" class="text-muted" role="status"></p></div>
            <div class="col-md-3"><label for="latitude" class="form-label">Latitude</label><input type="number" step="0.0000001" min="-90" max="90" id="latitude" name="latitude" class="form-control" value="<?php echo e(old('latitude', $site->latitude)); ?>" required></div>
            <div class="col-md-3"><label for="longitude" class="form-label">Longitude</label><input type="number" step="0.0000001" min="-180" max="180" id="longitude" name="longitude" class="form-control" value="<?php echo e(old('longitude', $site->longitude)); ?>" required></div>
            <div class="col-md-3"><label for="radius_meters" class="form-label">Rayon autorisé (m)</label><input type="number" min="10" max="5000" id="radius_meters" name="radius_meters" class="form-control" value="<?php echo e(old('radius_meters', $site->radius_meters)); ?>" required></div>
            <div class="col-md-3"><label for="max_accuracy_meters" class="form-label">Imprécision GPS maximale (m)</label><input type="number" min="1" max="500" id="max_accuracy_meters" name="max_accuracy_meters" class="form-control" value="<?php echo e(old('max_accuracy_meters', $site->max_accuracy_meters)); ?>" required></div>
            <div class="col-md-6"><label for="timezone" class="form-label">Fuseau horaire</label><input id="timezone" name="timezone" class="form-control" value="<?php echo e(old('timezone', $site->timezone)); ?>" placeholder="Africa/Dakar" required></div>
            <div class="col-md-6"><label for="active" class="form-label">État du site</label><select id="active" name="active" class="form-select"><option value="1" <?php if(old('active', $site->active) == 1): echo 'selected'; endif; ?>>Actif</option><option value="0" <?php if(old('active', $site->active) == 0): echo 'selected'; endif; ?>>Désactivé</option></select></div>
            <div class="col-12"><p class="text-muted">La désactivation bloque les nouvelles arrivées. Les journées déjà ouvertes restent clôturables avec leur configuration d’origine.</p></div>
            <div class="col-12 text-end"><a class="btn btn-outline-secondary" href="<?php echo e(route('attendance.sites')); ?>">Annuler</a> <button class="btn btn-success">Enregistrer le site</button></div>
        </div>
    </form>
</div></section>
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="<?php echo e(asset('js/attendance-site.js')); ?>" defer></script>
<?php $__env->stopSection(); ?>

<?php echo $__env->make('layouts.master', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH C:\Projets\sendrapp\sendra\sendraApp\resources\views/attendance/site-form.blade.php ENDPATH**/ ?>