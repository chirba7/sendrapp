<?php $__env->startSection('session'); ?>
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
                                                            <h6 class="text-sm text-medium">Météo</h6>
                                                        </td>
                                                        <td>
                                                            <div class="d-flex align-items-center">
                                                                <div class="d-flex align-items-center align-content-center">
                                                                    <div class="form-check">
                                                                        <input class="form-check-input is-valid me-3" type="checkbox" name="meteo[]" value="nuit" <?php echo e($carPosition->nuit ? 'checked' : ''); ?>>
                                                                        <label class="form-label form-check-label" for="nuit">Nuit</label>
                                                                    </div>
                                                                    <div class="form-check">
    <input 
        class="form-check-input is-valid me-3" 
        type="checkbox" 
        name="meteo[]" 
        id="pluie"
        value="pluie" 
        <?php echo e($carPosition->pluie ? 'checked' : ''); ?>>
    <label class="form-label form-check-label" for="pluie">Pluie</label>
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
                                                                    <label class="form-label form-check-label" for="lieu1">PUBLIC</label>
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
                                                                    <label class="form-label form-check-label" for="lieu2">PRIVE</label>
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
unset($__errorArgs, $__bag); ?>" id="numero_vehicule" value="<?php echo e(old('numero_vehicule', strtoupper($carPosition->numero_vehicule))); ?>" name="numero_vehicule">
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
                                                            <select id="marque" class="form-control <?php $__errorArgs = ['marque'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" name="marque">
                                                                <option value="" <?php echo e($carPosition->marque == '' ? 'selected' : ''); ?>>Sélectionnez une marque</option>
                                                                <option value="Toyota" <?php echo e($carPosition->marque == 'Toyota' ? 'selected' : ''); ?>>Toyota</option>
                                                                <option value="Ford" <?php echo e($carPosition->marque == 'Ford' ? 'selected' : ''); ?>>Ford</option>
                                                                <option value="Honda" <?php echo e($carPosition->marque == 'Honda' ? 'selected' : ''); ?>>Honda</option>
                                                                <option value="Chevrolet" <?php echo e($carPosition->marque == 'Chevrolet' ? 'selected' : ''); ?>>Chevrolet</option>
                                                                <option value="Nissan" <?php echo e($carPosition->marque == 'Nissan' ? 'selected' : ''); ?>>Nissan</option>
                                                                <option value="BMW" <?php echo e($carPosition->marque == 'BMW' ? 'selected' : ''); ?>>BMW</option>
                                                                <option value="Mercedes-Benz" <?php echo e($carPosition->marque == 'Mercedes-Benz' ? 'selected' : ''); ?>>Mercedes-Benz</option>
                                                                <option value="Audi" <?php echo e($carPosition->marque == 'Audi' ? 'selected' : ''); ?>>Audi</option>
                                                                <option value="Volkswagen" <?php echo e($carPosition->marque == 'Volkswagen' ? 'selected' : ''); ?>>Volkswagen</option>
                                                                <option value="Hyundai" <?php echo e($carPosition->marque == 'Hyundai' ? 'selected' : ''); ?>>Hyundai</option>
                                                                <option value="Kia" <?php echo e($carPosition->marque == 'Kia' ? 'selected' : ''); ?>>Kia</option>
                                                                <option value="Mazda" <?php echo e($carPosition->marque == 'Mazda' ? 'selected' : ''); ?>>Mazda</option>
                                                                <option value="Peugeot" <?php echo e($carPosition->marque == 'Peugeot' ? 'selected' : ''); ?>>Peugeot</option>
                                                                <option value="Renault" <?php echo e($carPosition->marque == 'Renault' ? 'selected' : ''); ?>>Renault</option>
                                                            </select>
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
                                                                <option value="BPP" <?php echo e($carPosition->categorie == 'BPP' ? 'selected' : ''); ?>>BPP</option>
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
                                                            <select id="inputColor" class="form-control <?php $__errorArgs = ['couleur'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?> is-invalid <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>" name="couleur">
                                                                <option value="">Sélectionnez une couleur</option>
                                                                <option value="Noir" <?php echo e($carPosition->couleur == 'Noir' ? 'selected' : ''); ?>>Noir</option>
                                                                <option value="Blanc" <?php echo e($carPosition->couleur == 'Blanc' ? 'selected' : ''); ?>>Blanc</option>
                                                                <option value="Rouge" <?php echo e($carPosition->couleur == 'Rouge' ? 'selected' : ''); ?>>Rouge</option>
                                                                <option value="Bleu" <?php echo e($carPosition->couleur == 'Bleu' ? 'selected' : ''); ?>>Bleu</option>
                                                                <option value="Gris" <?php echo e($carPosition->couleur == 'Gris' ? 'selected' : ''); ?>>Gris</option>
                                                                <option value="Argent" <?php echo e($carPosition->couleur == 'Argent' ? 'selected' : ''); ?>>Argent</option>
                                                                <option value="Vert" <?php echo e($carPosition->couleur == 'Vert' ? 'selected' : ''); ?>>Vert</option>
                                                                <option value="Jaune" <?php echo e($carPosition->couleur == 'Jaune' ? 'selected' : ''); ?>>Jaune</option>
                                                                <option value="Orange" <?php echo e($carPosition->couleur == 'Orange' ? 'selected' : ''); ?>>Orange</option>
                                                                <option value="Marron" <?php echo e($carPosition->couleur == 'Marron' ? 'selected' : ''); ?>>Marron</option>
                                                                <option value="Violet" <?php echo e($carPosition->couleur == 'Violet' ? 'selected' : ''); ?>>Violet</option>
                                                            </select>
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
                                                                    <label class="form-label form-check-label" for="entretien1">BON</label>
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
                                                                    <label class="form-label form-check-label" for="entretien2">MOYEN</label>
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
                                                                    <label class="form-label form-check-label" for="entretien3">DEGRADE</label>
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
                                                                    <label class="form-label form-check-label" for="pays_etranger1">OUI</label>
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
                                                                    <label class="form-label form-check-label" for="pays_etranger2">NON</label>
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
                                <canvas id="signature-canvas" width="650" height="400"></canvas>
                                <input type="hidden" name="signature" id="signature">
                                <hr>
                                <div class=" row justify-content-center align-items-center g-2" id="signature-controls">
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
                            <script src="<?php echo e(asset('assets/js/signature.js')); ?>"></script>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</section>
<?php $__env->stopSection(); ?>

<?php echo $__env->make('layouts.master', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /var/www/html/resources/views/carPosition/show.blade.php ENDPATH**/ ?>