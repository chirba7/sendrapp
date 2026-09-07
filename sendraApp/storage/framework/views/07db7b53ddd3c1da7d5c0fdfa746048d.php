<?php $__env->startSection('session'); ?>
<style>
    .sendra-choice-grid { display:grid; grid-template-columns:repeat(2,minmax(130px,1fr)); gap:12px; max-width:520px; }
    .sendra-choice-input { position:absolute; opacity:0; pointer-events:none; }
    .sendra-choice-card { min-height:76px; border:2px solid #dce5df; border-radius:16px; display:flex; align-items:center; justify-content:center; gap:10px; cursor:pointer; font-weight:700; transition:.18s ease; }
    .sendra-choice-input:checked + .sendra-choice-card { border-color:#198754; box-shadow:0 5px 14px rgba(25,135,84,.2); }
    .sendra-day { background:#62b8ed; color:#fff; }
    .sendra-night { background:#101722; color:#fff; position:relative; overflow:hidden; }
    .sendra-night::before { content:'•  ·  •'; position:absolute; color:#fff; top:5px; right:15px; letter-spacing:5px; }
    .sendra-rain { background:#4a6572; color:#fff; }
    .sendra-color-grid { display:flex; flex-wrap:wrap; gap:9px; }
    .sendra-color-card { width:62px; padding:8px 4px; border:2px solid #dce5df; border-radius:14px; text-align:center; cursor:pointer; background:#fff; }
    .sendra-color-input { position:absolute; opacity:0; pointer-events:none; }
    .sendra-color-input:checked + .sendra-color-card { border-color:#198754; background:#e8f5ed; }
    .sendra-color-dot { width:30px; height:30px; margin:0 auto 5px; border-radius:50%; border:1px solid rgba(0,0,0,.25); display:block; }
    .sendra-damage-wrap { max-width:900px; }
    #signature-canvas { display:block; width:100%; max-width:760px; height:auto; border:1px solid #dce5df; border-radius:14px; touch-action:none; }
    @media(max-width:767px) { .sendra-choice-grid{grid-template-columns:1fr 1fr}.sendra-choice-card{min-height:68px}.sendra-actions{gap:10px}.sendra-actions>div{text-align:left!important} }
</style>
<section class="tab-components">
    <div class="container-fluid">
        <div class="title-wrapper pt-30">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <a class="main-btn success-btn btn-hover mb-4" href="<?php echo e(route('locatlisation', [$carPosition->id])); ?>">
                        <i class="lni lni-map-marker"></i> Localisation
                    </a>
                </div>
            </div>
            <?php if(session('success')): ?>
            <div class="row alert-box success-alert">
                <div class="col-12 alert">
                    <p class="text-medium"><?php echo e(session('success')); ?></p>
                </div>
            </div>
            <?php endif; ?>
            <?php if(count($errors) > 0): ?>
            <div class="row alert-box danger-alert">
                <div class="col-12 alert">
                    <p class="text-medium">Une erreur s'est produite !!</p>
                </div>
            </div>
            <?php endif; ?>
        </div>

        <div class="form-elements-wrapper">
            <div class="card-style">
                <div class="card-header">
                    <ul class="nav nav-pills card-header-pills" id="myTab" role="tablist">
                        <li class="nav-item" role="presentation">
                            <a class="nav-link active" id="info-tab" data-bs-toggle="tab" href="#info" role="tab" aria-controls="info" aria-selected="true">Informations de base</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="vehicule-tab" data-bs-toggle="tab" href="#vehicule" role="tab" aria-controls="vehicule" aria-selected="false">Vehicule</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="infraction-tab" data-bs-toggle="tab" href="#infraction" role="tab" aria-controls="infraction" aria-selected="false">Infraction</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="dommages-tab" data-bs-toggle="tab" href="#dommages" role="tab" aria-controls="dommages" aria-selected="false">Dommages</a>
                        </li>
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="approval-tab" data-bs-toggle="tab" href="#approval" role="tab" aria-controls="approval" aria-selected="false">Approbation</a>
                        </li>
                        <?php if($carPosition->is_approve): ?>
                        <li class="nav-item" role="presentation">
                            <a class="nav-link" id="removal-tab" data-bs-toggle="tab" href="#removal" role="tab" aria-controls="removal" aria-selected="false">Enlévement</a>
                        </li>
                        <?php endif; ?>
                    </ul>
                </div>
                <hr>
                <div class="tab-content" id="myTabContent">
                    <!-- Informations de base form -->
                    <div class="tab-pane fade show active" id="info" role="tabpanel" aria-labelledby="info-tab">
                        <div class="card-body">
                            <div class="white_card_body">
                                <div class="box_header ">
                                    <div class="main-title">
                                        <h2 class="m-0 mb-1">Informations de base</h2>
                                    </div>
                                </div>
                                <div class="card-body">
                                    <div class="row justify-content-center align-items-center g-2">
                                        <div class="col-md-6">
                                            <div class="profile_card_5 mb-1">
                                                <img class="circle-rounded" src="<?php echo e(config('services.backend.storage_url') . '/' . $photo->filepath); ?>" alt="" width="90%" height="90%">
                                            </div>
                                        </div>
                                        <div class="col-md-6">
                                            <div class="row mb-3">
                                                <div class="col-md-12">
                                                    <label class="form-label" for="inputEmail4">Titre</label>
                                                    <input type="email" class="form-control" id="inputEmail4" value="<?php echo e($carPosition->title); ?>" readonly>
                                                </div>
                                                <div class=" col-md-6">
                                                    <label class="form-label" for="inputPassword4">Date de Signalement</label>
                                                    <input type="text" class="form-control" id="inputPassword4" value="<?php echo e($carPosition->created_at->format('d F Y')); ?>" readonly>
                                                </div>
                                                <div class=" col-md-6">
                                                    <label class="form-label" for="inputPassword4">heure de Signalement</label>
                                                    <input type="text" class="form-control" id="inputPassword4" value="<?php echo e($carPosition->created_at->format('H\hi')); ?>" readonly>
                                                </div>
                                            </div>
                                            <div class="row mb-3">
                                                <div class="col-md-12">
                                                    <label class="form-label" for="inputEmail4">Nom Auteur</label>
                                                    <input type="email" class="form-control" id="inputEmail4" value="<?php echo e($carPosition->user->first_name); ?>" readonly>
                                                </div>
                                                <div class=" col-md-12">
                                                    <label class="form-label" for="inputPassword4">Prenom Auteur</label>
                                                    <input type="text" class="form-control" id="inputPassword4" value="<?php echo e($carPosition->user->last_name); ?>" readonly>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- infraction form -->
                    <div class="tab-pane fade  " id="infraction" role="tabpanel" aria-labelledby="infraction-tab">
                        <div class="card-body">
                            <div class="white_card_body">
                                <div class="box_header ">
                                    <div class="main-title">
                                        <h2 class="m-0 mb-1">infraction</h2>
                                    </div>
                                </div>
                                <div class="card-body">
                                    <form action="<?php echo e(route('infraction', $carPosition->id)); ?>" method="post">
                                        <?php echo method_field('patch'); ?>
                                        <?php echo csrf_field(); ?>
                                        <div class="table-responsive">
                                            <table class="table top-selling-table">
                                                <tbody>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Addresse precise</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control <?php $__errorArgs = ['adresse_precise'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" id="inputPassword4" name="adresse_precise" value="<?php echo e($carPosition->adresse_precise); ?>">
                                                            <?php $__errorArgs = ['adresse_precise'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Motif Infraction</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control <?php $__errorArgs = ['motif_infraction'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" id="inputPassword4" value="<?php echo e(old('motif_infraction', $carPosition->motif_infraction)); ?>" name="motif_infraction">
                                                            <?php $__errorArgs = ['motif_infraction'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Moment du constat</h6>
                                                        </td>
                                                        <td>
                                                            <?php
                                                                $momentDefault = $carPosition->pluie ? 'pluie' : ($carPosition->nuit ? 'nuit' : 'jour');
                                                                $momentValue = old('moment', $momentDefault);
                                                            ?>
                                                            <div class="sendra-choice-grid" style="grid-template-columns:repeat(3,minmax(100px,1fr))">
                                                                <div>
                                                                    <input class="sendra-choice-input" type="radio" name="moment" id="moment-jour" value="jour" <?php echo e($momentValue === 'jour' ? 'checked' : ''); ?>>
                                                                    <label class="sendra-choice-card sendra-day" for="moment-jour"><span style="font-size:28px">☀️</span> Jour</label>
                                                                </div>
                                                                <div>
                                                                    <input class="sendra-choice-input" type="radio" name="moment" id="moment-nuit" value="nuit" <?php echo e($momentValue === 'nuit' ? 'checked' : ''); ?>>
                                                                    <label class="sendra-choice-card sendra-night" for="moment-nuit"><span style="font-size:28px;color:#fff">☾</span> Nuit</label>
                                                                </div>
                                                                <div>
                                                                    <input class="sendra-choice-input" type="radio" name="moment" id="moment-pluie" value="pluie" <?php echo e($momentValue === 'pluie' ? 'checked' : ''); ?>>
                                                                    <label class="sendra-choice-card sendra-rain" for="moment-pluie"><span style="font-size:28px">🌧️</span> Pluie</label>
                                                                </div>
                                                            </div>
                                                            <?php $__errorArgs = ['moment'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Lieu</h6>
                                                        </td>
                                                        <td>
                                                            <div class="d-flex align-items-center">
                                                                <div class="form-check me-3">
                                                                    <input class="form-check-input <?php $__errorArgs = ['lieu'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="radio" name="lieu" id="lieu1" value="PUBLIC" <?php echo e(old('lieu', $carPosition->lieu) == 'PUBLIC' ? 'checked' : ''); ?>>
                                                                    <label class="form-label form-check-label" for="lieu1">🏛️ PUBLIC</label>
                                                                </div>
                                                                <div class="form-check">
                                                                    <input class="form-check-input <?php $__errorArgs = ['lieu'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="radio" name="lieu" id="lieu2" value="PRIVE" <?php echo e(old('lieu', $carPosition->lieu) == 'PRIVE' ? 'checked' : ''); ?>>
                                                                    <label class="form-label form-check-label" for="lieu2">🔒 PRIVÉ</label>
                                                                </div>
                                                            </div>
                                                            <?php $__errorArgs = ['lieu'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td colspan="4">
                                                            <div class="row justify-content-center align-items-center g-2">
                                                                <div class="col-md-6">
                                                                    <?php if(Auth::user()->role->nomRole != 'Autorite commune' || Auth::user()->role->nomRole != 'Autorite prefecture'): ?>
                                                                    <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                                                        <i class="lni lni-checkmark"></i> Enregistrer
                                                                    </button>
                                                                    <?php endif; ?>
                                                                </div>
                                                                <div class="col-md-6 text-end">
                                                                    <?php if($carPosition->etat == "EN COURS"): ?>
                                                                    <a href="<?php echo e(route('pdf_constation', [$carPosition->id])); ?>" class="main-btn success-btn-light btn-hover " target="_blank">
                                                                        <i class="lni lni-empty-file"></i> Imprimer le PV
                                                                    </a>
                                                                    <?php endif; ?>
                                                                </div>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                        </div>
                                    </form>

                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- vehicule form -->
                    <div class="tab-pane fade  " id="vehicule" role="tabpanel" aria-labelledby="vehicule-tab">
                        <div class="card-body">
                            <div class="white_card_body">
                                <div class="box_header ">
                                    <div class="main-title">
                                        <h2 class="m-0 mb-1">vehicule</h2>
                                    </div>
                                </div>
                                <div class="card-body">
                                    <?php
                                        $vehicleBrands = config('vehicle_brands');
                                    ?>
                                    <div class="mb-4">
                                        <h6 class="text-sm text-medium mb-2">Type de véhicule</h6>
                                        <div class="sendra-choice-grid" style="max-width:340px">
                                            <div>
                                                <input class="sendra-choice-input vehicle-kind-choice" type="radio" name="vehicule_kind_ui" id="kind-voiture" value="voiture" checked>
                                                <label class="sendra-choice-card" for="kind-voiture">🚗 Voiture</label>
                                            </div>
                                            <div>
                                                <input class="sendra-choice-input vehicle-kind-choice" type="radio" name="vehicule_kind_ui" id="kind-moto" value="moto">
                                                <label class="sendra-choice-card" for="kind-moto">🏍️ Moto</label>
                                            </div>
                                        </div>
                                        <p class="text-sm text-muted mt-2 mb-0">Filtre seulement les marques suggérées ci-dessous — pas enregistré séparément.</p>
                                    </div>
                                    <form action="<?php echo e(route('vehicule', [$carPosition->id])); ?>" method="post">
                                        <?php echo method_field('patch'); ?>
                                        <?php echo csrf_field(); ?>
                                        <div class="table-responsive">
                                            <table class="table top-selling-table">
                                                <tbody>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Numéro du véhicule</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control <?php $__errorArgs = ['numero_vehicule'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" id="numero_vehicule" placeholder="AB-0000-KO" pattern="[A-Z]{2}-\d{4}-[A-Z]{2}" value="<?php echo e(old('numero_vehicule', strtoupper($carPosition->numero_vehicule))); ?>" name="numero_vehicule" style="text-transform:uppercase">
                                                            <?php $__errorArgs = ['numero_vehicule'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Marque</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control <?php $__errorArgs = ['marque'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" id="marque" list="marque-options" value="<?php echo e(old('marque', $carPosition->marque)); ?>" name="marque" placeholder="Choisissez ou saisissez une marque">
                                                            <datalist id="marque-options"></datalist>
                                                            <?php $__errorArgs = ['marque'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Type</h6>
                                                        </td>
                                                        <td>
                                                            <select id="type" class="form-control <?php $__errorArgs = ['type'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" name="type">
                                                                <option value="" <?php echo e($carPosition->type_car == '' ? 'selected' : ''); ?>>Sélectionnez le type</option>
                                                                <option value="Berline" <?php echo e($carPosition->type_car == 'Berline' ? 'selected' : ''); ?>>Berline</option>
                                                                <option value="VUS" <?php echo e($carPosition->type_car == 'VUS' ? 'selected' : ''); ?>>VUS</option>
                                                                <option value="SUV" <?php echo e($carPosition->type_car == 'SUV' ? 'selected' : ''); ?>>SUV</option>
                                                                <option value="Hayon" <?php echo e($carPosition->type_car == 'Hayon' ? 'selected' : ''); ?>>Hayon</option>
                                                                <option value="Camion" <?php echo e($carPosition->type_car == 'Camion' ? 'selected' : ''); ?>>Camion</option>
                                                                <option value="Electrique" <?php echo e($carPosition->type_car == 'Electrique' ? 'selected' : ''); ?>>Electrique</option>
                                                            </select>
                                                            <?php $__errorArgs = ['type'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Modèle</h6>
                                                        </td>
                                                        <td>
                                                            <input type="text" class="form-control <?php $__errorArgs = ['model'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" id="model" value="<?php echo e(old('model', $carPosition->model)); ?>" name="model">
                                                            <?php $__errorArgs = ['model'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Catégorie de Véhicule</h6>
                                                        </td>
                                                        <td>
                                                            <select id="categorie" class="form-control <?php $__errorArgs = ['categorie'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" name="categorie">
                                                                <option value="">Choisissez une catégorie</option>
                                                                <option value="VPP" <?php echo e($carPosition->categorie == 'VPP' ? 'selected' : ''); ?>>VPP</option>
                                                                <option value="VUS" <?php echo e($carPosition->categorie == 'VUS' ? 'selected' : ''); ?>>VUS</option>
                                                                <option value="VUL" <?php echo e($carPosition->categorie == 'VUL' ? 'selected' : ''); ?>>VUL</option>
                                                                <option value="VTM" <?php echo e($carPosition->categorie == 'VTM' ? 'selected' : ''); ?>>VTM</option>
                                                                <option value="CYCL" <?php echo e($carPosition->categorie == 'CYCL' ? 'selected' : ''); ?>>CYCL</option>
                                                            </select>
                                                            <?php $__errorArgs = ['categorie'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Couleur</h6>
                                                        </td>
                                                        <td>
                                                            <?php
                                                                $vehicleColors = [
                                                                    'Blanc'=>'#f5f5f5','Noir'=>'#202124','Gris'=>'#8b9298','Argent'=>'#c5cbd0',
                                                                    'Rouge'=>'#d93636','Bleu'=>'#2767c5','Vert'=>'#278652','Jaune'=>'#f2c230',
                                                                    'Orange'=>'#e87924','Marron'=>'#795548','Violet'=>'#7e57c2'
                                                                ];
                                                            ?>
                                                            <div class="sendra-color-grid">
                                                                <?php $__currentLoopData = $vehicleColors; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $colorName => $colorHex): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                                                    <div>
                                                                        <input class="sendra-color-input" type="radio" name="couleur" id="color-<?php echo e(Str::slug($colorName)); ?>" value="<?php echo e($colorName); ?>" <?php echo e(old('couleur', $carPosition->couleur) === $colorName ? 'checked' : ''); ?>>
                                                                        <label class="sendra-color-card" for="color-<?php echo e(Str::slug($colorName)); ?>">
                                                                            <span class="sendra-color-dot" style="background:<?php echo e($colorHex); ?>"></span>
                                                                            <small><?php echo e($colorName); ?></small>
                                                                        </label>
                                                                    </div>
                                                                <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
                                                            </div>
                                                            <?php $__errorArgs = ['couleur'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Etat Général</h6>
                                                        </td>
                                                        <td>
                                                            <div class="d-flex align-items-center align-content-center">
                                                                <div class="form-check me-3">
                                                                    <input class="form-check-input <?php $__errorArgs = ['entretien'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="radio" name="entretien" id="entretien1" value="BON" <?php echo e(old('entretien', $carPosition->entretien) == 'BON' ? 'checked' : ''); ?>>
                                                                    <label class="form-label form-check-label" for="entretien1">✅ BON</label>
                                                                </div>
                                                                <div class="form-check me-3">
                                                                    <input class="form-check-input <?php $__errorArgs = ['entretien'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="radio" name="entretien" id="entretien2" value="MOYEN" <?php echo e(old('entretien', $carPosition->entretien) == 'MOYEN' ? 'checked' : ''); ?>>
                                                                    <label class="form-label form-check-label" for="entretien2">🟠 MOYEN</label>
                                                                </div>
                                                                <div class="form-check">
                                                                    <input class="form-check-input <?php $__errorArgs = ['entretien'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="radio" name="entretien" id="entretien3" value="DEGRADE" <?php echo e(old('entretien', $carPosition->entretien) == 'DEGRADE' ? 'checked' : ''); ?>>
                                                                    <label class="form-label form-check-label" for="entretien3">🛠️ DÉGRADÉ</label>
                                                                </div>
                                                            </div>
                                                            <?php $__errorArgs = ['entretien'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Pays étranger</h6>
                                                        </td>
                                                        <td>
                                                            <div class="d-flex align-items-center align-content-center">
                                                                <div class="form-check me-3">
                                                                    <input class="form-check-input <?php $__errorArgs = ['pays_etranger'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="radio" name="pays_etranger" id="pays_etranger1" value="OUI" <?php echo e(old('pays_etranger', $carPosition->pays_etranger) == 'OUI' ? 'checked' : ''); ?>>
                                                                    <label class="form-label form-check-label" for="pays_etranger1">🌍 OUI</label>
                                                                </div>
                                                                <div class="form-check">
                                                                    <input class="form-check-input <?php $__errorArgs = ['pays_etranger'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="radio" name="pays_etranger" id="pays_etranger2" value="NON" <?php echo e(old('pays_etranger', $carPosition->pays_etranger) == 'NON' ? 'checked' : ''); ?>>
                                                                    <label class="form-label form-check-label" for="pays_etranger2">🇸🇳 NON</label>
                                                                </div>
                                                            </div>
                                                            <?php $__errorArgs = ['pays_etranger'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Défaut de Contrôle technique</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid <?php $__errorArgs = ['defaut_controle_technique'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="checkbox" name="defaut_controle_technique" id="defaut_controle_technique" <?php echo e($carPosition->defaut_controle_technique ? 'checked' : ''); ?>>
                                                            </div>
                                                            <?php $__errorArgs = ['defaut_controle_technique'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Pneumatiques manquantes</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid <?php $__errorArgs = ['pneumatiques_manquantes'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="checkbox" name="pneumatiques_manquantes" id="pneumatiques_manquantes" <?php echo e($carPosition->pneumatiques_manquantes ? 'checked' : ''); ?>>
                                                            </div>
                                                            <?php $__errorArgs = ['pneumatiques_manquantes'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Véhicule immergé audessus du tableau de bord</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid <?php $__errorArgs = ['vehicule_immerge'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="checkbox" name="vehicule_immerge" id="vehicule_immerge" <?php echo e($carPosition->vehicule_immerge ? 'checked' : ''); ?>>
                                                            </div>
                                                            <?php $__errorArgs = ['vehicule_immerge'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Défauts techniques irréversibles et non remplaçables</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid <?php $__errorArgs = ['defauts_techniques_irreversibles'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="checkbox" name="defauts_techniques_irreversibles" id="defauts_techniques_irreversibles" <?php echo e($carPosition->defauts_techniques_irreversibles ? 'checked' : ''); ?>>
                                                            </div>
                                                            <?php $__errorArgs = ['defauts_techniques_irreversibles'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Véhicule définitivement non identifiable</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid <?php $__errorArgs = ['vehicule_non_identifiable'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="checkbox" name="vehicule_non_identifiable" id="vehicule_non_identifiable" <?php echo e($carPosition->vehicule_non_identifiable ? 'checked' : ''); ?>>
                                                            </div>
                                                            <?php $__errorArgs = ['vehicule_non_identifiable'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Véhicule complètement brûlé</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid <?php $__errorArgs = ['vehicule_brule'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="checkbox" name="vehicule_brule" id="vehicule_brule" <?php echo e($carPosition->vehicule_brule ? 'checked' : ''); ?>>
                                                            </div>
                                                            <?php $__errorArgs = ['vehicule_brule'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <h6 class="text-sm text-medium">Coque ou Chassis ni réparable ni remplaçable</h6>
                                                        </td>
                                                        <td>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid <?php $__errorArgs = ['chassis_non_reparable'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" type="checkbox" name="chassis_non_reparable" id="chassis_non_reparable" <?php echo e($carPosition->chassis_non_reparable ? 'checked' : ''); ?>>
                                                            </div>
                                                            <?php $__errorArgs = ['chassis_non_reparable'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                            <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                            <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                        </td>
                                                        <td></td>
                                                        <td></td>
                                                    </tr>
                                                    <tr>
                                                        <td colspan="4">
                                                            <div class="row justify-content-center align-items-center g-2">
                                                                <div class="col-md-6">
                                                                    <?php if(Auth::user()->role->nomRole != 'Autorite commune' || Auth::user()->role->nomRole != 'Autorite prefecture'): ?>
                                                                    <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                                                        <i class="lni lni-checkmark"></i> Enregistrer
                                                                    </button>
                                                                    <?php endif; ?>
                                                                </div>
                                                                <div class="col-md-6 text-end">
                                                                    <?php if($carPosition->etat == "EN COURS"): ?>
                                                                    <a href="<?php echo e(route('pdf_constation', [$carPosition->id])); ?>" class="main-btn success-btn-light btn-hover " target="_blank">
                                                                        <i class="lni lni-empty-file"></i> Imprimer le PV
                                                                    </a>
                                                                    <?php endif; ?>
                                                                </div>
                                                            </div>
                                                        </td>
                                                    </tr>
                                                </tbody>
                                            </table>
                                        </div>
                                    </form>
                                    <script>
                                        (function () {
                                            const brands = <?php echo json_encode($vehicleBrands, 15, 512) ?>;
                                            const marqueInput = document.getElementById('marque');
                                            const marqueList = document.getElementById('marque-options');
                                            const numeroInput = document.getElementById('numero_vehicule');

                                            function fillBrandOptions(kind) {
                                                if (!marqueList) return;
                                                marqueList.innerHTML = '';
                                                (brands[kind] || []).forEach((brand) => {
                                                    const option = document.createElement('option');
                                                    option.value = brand;
                                                    marqueList.appendChild(option);
                                                });
                                            }

                                            document.querySelectorAll('.vehicle-kind-choice').forEach((choice) => {
                                                choice.addEventListener('change', (event) => fillBrandOptions(event.target.value));
                                            });
                                            fillBrandOptions('voiture');

                                            // Plaque : AA-0000-AA — majuscules et tirets automatiques,
                                            // pas de blocage strict de caractère par caractère (l'utilisateur
                                            // peut coller/corriger librement), la validation stricte se fait
                                            // à la soumission (attribut pattern + contrôle serveur).
                                            if (numeroInput) {
                                                numeroInput.addEventListener('input', () => {
                                                    const raw = numeroInput.value.toUpperCase().replace(/[^A-Z0-9]/g, '');
                                                    const letters1 = raw.slice(0, 2).replace(/[^A-Z]/g, '');
                                                    const digits = raw.slice(2, 6).replace(/[^0-9]/g, '');
                                                    const letters2 = raw.slice(6, 8).replace(/[^A-Z]/g, '');
                                                    let formatted = letters1;
                                                    if (letters1.length === 2) formatted += '-' + digits;
                                                    if (digits.length === 4) formatted += '-' + letters2;
                                                    numeroInput.value = formatted;
                                                });
                                            }
                                        })();
                                    </script>

                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- Enlévement form -->
                    <?php if($carPosition->is_approve): ?>
                    <div class="tab-pane fade" id="removal" role="tabpanel" aria-labelledby="removal-tab">
                        <div class="card-body">
                            <div class="box_header">
                                <div class="main-title">
                                    <h2 class="m-0 mb-1">Enlévement</h2>
                                </div>
                            </div>
                            <form action="<?php echo e(route('enlevement', [$carPosition->id])); ?>" method="post">
                                <?php echo method_field('patch'); ?>
                                <?php echo csrf_field(); ?>
                                <div class="table-responsive">
                                    <table class="table top-selling-table">
                                        <tbody>
                                            <tr>
                                                <td>
                                                    <h6 class="text-sm text-medium">Enlevé par propriétaire</h6>
                                                </td>
                                                <td>
                                                    <div class="d-flex align-items-center">
                                                        <div class="d-flex align-items-center align-content-center">
                                                            <div class="form-check">
                                                                <input class="form-check-input is-valid me-3" type="checkbox" value="oui" <?php echo e($carPosition->oui ? 'checked' : ''); ?>>
                                                                <label class="form-label form-check-label" for="oui">oui</label>
                                                            </div>
                                                            <div class="form-check">
                                                                <input class="form-check-input is-invalid me-3" type="checkbox" value="non" <?php echo e($carPosition->non ? 'checked' : ''); ?>>
                                                                <label class="form-label form-check-label" for="non">non</label>
                                                            </div>
                                                        </div>
                                                    </div>
                                                    <?php $__errorArgs = ['meteo'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                                    <div class="invalid-feedback"><?php echo e($message); ?></div>
                                                    <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                                </td>
                                            </tr>
                                        </tbody>
                                    </table>
                                </div>
                                <hr class="text-success">
                                <div class="row mb-3">
                                    <div class="col-md-12">
                                        <label class="form-label" for="inputEmail4">Motif enlévement</label>
                                        <textarea class="form-control <?php $__errorArgs = ['motif_enlevement'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" maxlength="225" rows="3" name="motif_enlevement" id="maxlength-textarea" placeholder="Entrez le motif d'enlévement."><?php echo e($carPosition->motif_enlevement); ?></textarea>
                                        <?php $__errorArgs = ['motif_enlevement'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                        <div class="invalid-feedback"><?php echo e($message); ?></div>
                                        <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                    </div>
                                </div>
                                <div class="row mb-2">
                                    <div class="col-md-6">
                                        <label class="form-label" for="inputtest4">Date enlévement</label>
                                        <input type="date" class="form-control <?php $__errorArgs = ['date_enlevement'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" id="inputtest4" value="<?php echo e(!empty($carPosition->date_enlevement) ? date('Y-m-d', strtotime($carPosition->date_enlevement)) : date('Y-m-d')); ?>" name="date_enlevement">
                                        <?php $__errorArgs = ['date_enlevement'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                        <div class="invalid-feedback"><?php echo e($message); ?></div>
                                        <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label" for="inputtest4">Lieu enlévement</label>
                                        <input type="test" class="form-control <?php $__errorArgs = ['lieu_enlevement'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" id="inputtest4" value="<?php echo e($carPosition->lieu_enlevement); ?>" name="lieu_enlevement">
                                        <?php $__errorArgs = ['lieu_enlevement'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                        <div class="invalid-feedback"><?php echo e($message); ?></div>
                                        <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <div class="col-md-12">
                                        <label class="form-label" for="inputtest4">Nom Responsable de MEF</label>
                                        <input type="test" class="form-control <?php $__errorArgs = ['nom_responsable_mef'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" id="inputEmail4" value="<?php echo e($carPosition->nom_responsable_mef); ?>" name="nom_responsable_mef">
                                        <?php $__errorArgs = ['nom_responsable_mef'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                        <div class="invalid-feedback"><?php echo e($message); ?></div>
                                        <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <?php if(Auth::user()->role->nomRole != 'Autorite commune' || Auth::user()->role->nomRole != 'Autorite prefecture'): ?>
                                    <div class="col-md-6">
                                        <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                            <i class="lni lni-checkmark"></i> Fin de Procédure
                                        </button>
                                    </div>
                                    <?php endif; ?>
                                    <div class="col-md-6">
                                        <?php if($carPosition->etat == "ENLEVE"): ?>
                                        <a href="<?php echo e(route('pdf', [$carPosition->id])); ?>" class="main-btn success-btn-light btn-hover ">
                                            <i class="lni lni-empty-file"></i> Imprimer le PV
                                        </a>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                    <?php endif; ?>
                    <!-- Approbation form -->
                    <div class="tab-pane fade" id="approval" role="tabpanel" aria-labelledby="approval-tab">
                        <div class="card-body">
                            <div class="box_header">
                                <div class="main-title">
                                    <h2 class="m-0">Approbation</h2>
                                </div>
                            </div>
                            <form action="<?php echo e(route('approbation', [$carPosition->id])); ?>" method="post">
                                <?php echo method_field('patch'); ?>
                                <?php echo csrf_field(); ?>
                                <div class="row mb-2">
                                    <div class="col-md-12">
                                        <div class="col-form-label col-sm-4">Approuver ?</div>
                                        <div class="col-sm-8">
                                            <div class="form-check">
                                                <input class="form-check-input is-valid" type="radio" name="approbation" id="approbation1" value="OUI" <?php echo e($carPosition->is_approve == true ? 'checked' : ''); ?>>
                                                <label class="form-label form-check-label" for="approbation1">
                                                    OUI
                                                </label>
                                            </div>
                                            <div class="form-check">
                                                <input class="form-check-input is-invalid" type="radio" name="approbation" id="approbation2" value="NON" <?php echo e($carPosition->is_approve == false ? 'checked' : ''); ?>>
                                                <label class="form-label form-check-label" for="approbation2">
                                                    NON
                                                </label>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <div class="col-md-12">
                                        <label class="form-label" for="inputEmail4">Motif d'approbation</label>
                                        <textarea class="form-control <?php $__errorArgs = ['motife_approbation'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" maxlength="225" rows="3" name="motife_approbation" id="maxlength-textarea" placeholder="Entrez le motif d'approbation"><?php echo e($carPosition->motife_approbation); ?></textarea>
                                    </div>
                                    <?php $__errorArgs = ['motife_approbation'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                                    <div class="invalid-feedback"><?php echo e($message); ?></div>
                                    <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                                </div>
                                <div class="row justify-content-center align-items-center g-2">
                                    <div class="col-md-6">
                                        <?php if(Auth::user()->role->nomRole != 'Agent'): ?>
                                        <button type="submit mb-3" class="main-btn success-btn-light btn-hover">
                                            <i class="lni lni-checkmark"></i> Enregistrer
                                        </button>
                                        <?php endif; ?>
                                    </div>
                                    <div class="col-md-6">
                                        <?php if($carPosition->etat != "SIGNALE"): ?>
                                        <a href="<?php echo e(route('pdf', [$carPosition->id])); ?>" class="main-btn success-btn-light btn-hover ">
                                            <i class="lni lni-empty-file"></i> Imprimer le PV
                                        </a>
                                        <?php endif; ?>
                                    </div>
                                </div>
                            </form>
                        </div>
                    </div>
                    <!-- Dommages form -->
                    <div class="tab-pane fade" id="dommages" role="tabpanel" aria-labelledby="dommages-tab">
                        <div class="card-body">
                            <form id="signature-form" method="POST" action="<?php echo e(route('signature.store', [$carPosition->id])); ?>">
                                <?php echo csrf_field(); ?>
                                <img id="default-image" src="<?php echo e(asset('img/constation image.png')); ?>" style="display: none;">
                                <?php if($carPosition->dommage_image): ?>
                                
                                <img id="existing-damage-image" src="<?php echo e(config('services.backend.storage_url').'/dommages/'.$carPosition->dommage_image); ?>" style="display: none;" crossorigin="anonymous">
                                <?php endif; ?>
                                <div class="sendra-damage-wrap">
                                    <h5 class="mb-3">Type de véhicule</h5>
                                    <div class="sendra-choice-grid mb-4">
                                        <div>
                                            <input class="sendra-choice-input damage-vehicle-choice" type="radio" name="damage_vehicle_type" id="damage-car" value="car" checked>
                                            <label class="sendra-choice-card" for="damage-car">🚗 Voiture</label>
                                        </div>
                                        <div>
                                            <input class="sendra-choice-input damage-vehicle-choice" type="radio" name="damage_vehicle_type" id="damage-motorcycle" value="motorcycle">
                                            <label class="sendra-choice-card" for="damage-motorcycle">🏍️ Moto</label>
                                        </div>
                                    </div>
                                    <p class="text-sm mb-2">
                                        Dessinez uniquement sur le véhicule pour indiquer les dommages.
                                        <?php if($carPosition->dommage_image): ?>
                                        <span class="text-muted">Dommages déjà constatés affichés ci-dessous.</span>
                                        <?php endif; ?>
                                    </p>
                                    <canvas id="signature-canvas" width="760" height="360"></canvas>
                                    <?php if($carPosition->dommage_image): ?>
                                    <div class="mt-2 d-flex gap-2 flex-wrap">
                                        <button type="button" id="blank-template" class="main-btn btn-hover"><i class="lni lni-reload"></i> Nouveau gabarit vierge</button>
                                        <button type="button" id="restore-agent-version" class="main-btn btn-hover"><i class="lni lni-undo"></i> Revenir à la version de l'agent</button>
                                    </div>
                                    <?php endif; ?>
                                </div>
                                <input type="hidden" name="signature" id="signature">
                                <hr>
                                <div class="row justify-content-center align-items-center g-2 sendra-actions" id="signature-controls">
                                    <div class="col-md-6">
                                        <button type="button" id="clear-signature" class="main-btn danger-btn-light btn-hover"> <i class="lni lni-reload"></i> Effacer</button>
                                    </div>
                                    <div class="col-md-6 text-end">
                                        <button type="submit" id="save-signature" class="main-btn success-btn-light btn-hover "> <i class="lni lni-checkmark"></i> Enregistrer
                                        </button>
                                    </div>
                                </div>
                            </form>
                            <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.3.1/jspdf.umd.min.js"></script>
                            <script src="<?php echo e(asset('assets/js/signature.js')); ?>?v=<?php echo e(filemtime(public_path('assets/js/signature.js'))); ?>"></script>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
<?php $__env->stopSection(); ?>

<?php echo $__env->make('layouts.master', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /var/www/html/resources/views/carPosition/show.blade.php ENDPATH**/ ?>