<!DOCTYPE html>
<html lang="fr">

<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        /* Styles pour le tableau */
        table {
            width: 100%;
            border-collapse: collapse;
            border: 1px solid #000;
            margin: 20px;
        }

        th,
        td {
            padding: 8px;
            text-align: left;
            border: 1px solid #000;
            margin: 0px;
            margin-top: 6px;
        }

        th {
            background-color: #fff;
        }

        h4 {
            margin-top: -1px;
            margin-bottom: -1px;
            font-size: 13px;
        }

        h6 {
            margin-top: -1px;
            margin-bottom: -1px;
            font-size: 9px;
        }

        h6 {
            margin-top: -1px;
            margin-bottom: -1px;
            font-size: 8px;
        }

        .text-center {
            text-align: center;
        }

        .horizontal-text {
            writing-mode: vertical-lr;
            transform: rotate(-90deg);
            white-space: nowrap;
        }

        .taille {
            font-size: 11px;
        }

        p {
            font-size: 10px;
        }

        label {
            font-size: 9.6px;
            display: inline-block;
            vertical-align: middle;
        }

        input[type="checkbox"] {
            font-size: 9.6px;
            display: inline-block;
            vertical-align: middle;
        }

        .marge-null {
            margin: 0;
        }
    </style>

</head>

<body>
    <table>
        <tbody>
            <tr>
                <td>
                    <h6>AUTORITE DONT RELEVE LA FOURRIERE</h6>
                </td>
                <td rowspan="4">
                    <h4 class="text-center">PROCES VERBAL DE MISE EN FOURRIERE</h4>
                    <br>
                    <h6 class="text-center">FICHE DESCRIPTIVE DU VEHICULE</h6>
                </td>
                <td>
                    <h6>AUTORITE DONT RELEVE LA FOURRIERE</h6>
                </td>
            </tr>
            <tr>
                <td rowspan="3"></td>
                <td>
                    <h6>VEHICULE SANS PLAQUE: {{$carPosition->numero_vehicule ? 'Non' : 'Oui'}}</h6>
                </td>
            </tr>
            <tr>
                <td>
                    <h6>PAYS ETRANGER: {{$carPosition->pays_etranger}}</h6>
                </td>
            </tr>
            <tr>
                <td>
                    <h6>NUMERO VIN: {{$carPosition->numero_vehicule}}</h6>
                </td>
            </tr>
        </tbody>
    </table>
    <br>
    <table>
        <tbody>
            <tr>
                <td rowspan="5">
                    <h3 class="text-center horizontal-text marge-null taille"><b>INFRACTION</b></h3>
                </td>
                <td>
                    <h6>DATE DE CONSTATATION DE L'INFRACTION: </h6>
                </td>
                <td>
                </td>
            </tr>
            <tr>
                <td>
                    <h6>NOM DE L'AGENT: {{$carPosition->agent->first_name}} {{$carPosition->agent->last_name}}</h6>
                </td>
                <td>
                    <h6>UNITE: {{$carPosition->agent->email}}</h6>
                </td>
            </tr>
            <tr>
                <td>
                    <h6>LIEU D'ENLEVEMENT (RUE, REPERE, NUMERO) : {{$carPosition->lieu_enlevement}}</h6>
                </td>
                <td>
                    <h6>COMMUNE: {{$carPosition->commune}}</h6>
                </td>
            </tr>
            <tr>
                <td>
                    <h6>MOTIVATION DE LA PRESCRIPTION:</h6>
                </td>
                <td>
                    <h6> {{$carPosition->motif_infraction}}</h6>
                </td>
            </tr>
            <tr>
                <td>
                    <div class="checkbox-group">
                        <input type="checkbox" id="prive" name="agent" value="PRIVE" {{ old('lieu', $carPosition->lieu) == 'PRIVE' ? 'checked' : '' }}>
                        <label for="prive">LIEU PRIVE</label>
                        <input type="checkbox" id="public" name="agent" value="PUBLIC" {{ old('lieu', $carPosition->lieu) == 'PUBLIC' ? 'checked' : '' }}>
                        <label for="public">LIEU PUBLIC</label>
                    </div>
                </td>
                <td>
                    <h6>NUIT: {{$carPosition->nuit ? 'Oui' : 'Non'}} <span style="margin-left: 20px;">PLUIE: {{$carPosition->pluie ? 'Oui' : 'Non'}}</span></h6>
                </td>
            </tr>
        </tbody>
    </table>
    <br>
    <table>
        <tbody>
            <tr>
                <td rowspan="6">
                    <h3 class="text-center horizontal-text marge-null taille"><b>VEHICULE</b></h3>
                </td>
                <td>
                    <h6>MARQUE: {{$carPosition->marque}}</h6>
                </td>
                <td>
                    <h6>MODELE: {{$carPosition->model}}</h6>
                </td>
                <td>
                    <h6>GENRE: {{$carPosition->type_car}}</h6>
                </td>
                <td>
                    <h6>COULEUR: {{$carPosition->couleur}}</h6>
                </td>
            </tr>
            <tr>
                <td colspan="4" class="text-center">
                    <h4>ETAT DU VEHICULE</h4>
                </td>
            </tr>
            <tr>
                <td rowspan="2">
                    <h4>ETAT: {{$carPosition->entretien}} </h4>
                </td>
                <td colspan="3" class="text-center">
                    <h4>DEGRADE</h4>
                </td>
            </tr>
            <tr>
                <td>
                    <label><input type="checkbox" name="defaut" {{ $carPosition->defaut_controle_technique ? 'checked' : '' }}>Défaut de Contrôle technique</label><br>
                    <label><input type="checkbox" name="pneumatiques" {{ $carPosition->pneumatiques_manquantes ? 'checked' : '' }}>Pneumatiques manquantes</label><br>
                    <label><input type="checkbox" name="chassis" {{ $carPosition->chassis_non_reparable ? 'checked' : '' }}>Coque ou Chassis ni réparable ni remplaçable</label><br>
                </td>
                <td>
                    <label><input type="checkbox" name="defaut" {{ $carPosition->vehicule_immerge ? 'checked' : '' }}>Vehicule immerge audessus du tableau de bord</label><br>
                    <label><input type="checkbox" name="defaut" {{ $carPosition->defauts_techniques_irreversibles ? 'checked' : '' }}>Defauts techniques irreversibles et non remplacable</label><br>
                </td>
                <td>
                    <label><input type="checkbox" name="defaut" {{ $carPosition->vehicule_non_identifiable ? 'checked' : '' }}>Vehicule definitivement non identifiable</label><br>
                    <label><input type="checkbox" name="defaut" {{ $carPosition->vehicule_brule ? 'checked' : '' }}>Vehicule completement brule</label><br>
                </td>
            </tr>
            <tr>
                <td colspan="2">
                    <h6>Verouillage</h6>
                </td>
                <td colspan="2">
                    <h6>PORTES: {{$carPosition->portes}}</h6>
                </td>
            </tr>
            <tr>
                <td colspan="4">
                    <h6><b>INDIQUEZ LES DOMMAGES PAR DES SYMBOLES : <span style="margin-left: 120px;">RAYURES:</span> <span style="margin-left: 120px;">ENFONCEMENT:</span> </b></h6>
                    <br>
                    @if ($carPosition->dommage_image)
                    <img src="{{ public_path('storage/dommages/'.$carPosition->dommage_image) }}" alt="constation image" width="100%" height="200px">
                    @else
                    <img src="{{ public_path('img/constation image.png') }}" alt="constation image" width="100%" height="200px">
                    @endif
                </td>
            </tr>
        </tbody>
    </table>

    <br>
    <table>
        <tbody>
            <tr>
                <td colspan="4" class="text-center">
                    <h4>FOURIÈRE NOM ET COORDONNÉES</h4>
                </td>
            </tr>
            <tr>
                <td>
                    <h6>Signature agent et verbalisation</h6>
                    <br>
                    <br>
                    <br>
                    <br>
                </td>
                <td>
                    <h6>Établissement de la fiche</h6>
                    <p>(date et heure)</p>
                    <p>Le: ___/___/______</p>
                    <p>A: _______________</p>
                </td>
                <td>
                    <h6>Signature conducteur</h6>
                    <br>
                    <br>
                    <br>
                    <br>
                </td>
                <td>
                    <h6>Personne chargée de l'enlèvement</h6>
                    <br>
                    <br>
                    <br>
                    <br>
                </td>
        </tbody>
    </table>
</body>

</html>