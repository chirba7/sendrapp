<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Procedures d'Infractions</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
        }

        .container {
            width: 100%;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }

        .header {
            text-align: center;
            font-weight: bold;
            margin-bottom: 20px;
            font-size: 18px;
            color: #343a40;
            border-bottom: 2px solid #343a40;
            padding-bottom: 10px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }

        th,
        td {
            padding: 10px;
            text-align: left;
            border: 1px solid #dee2e6;
        }

        th {
            background-color: #f1f3f5;
            font-size: 14px;
        }

        td {
            font-size: 13px;
        }

        .checkbox-group {
            display: flex;
            align-items: center;
        }

        .checkbox-group label {
            margin-left: 5px;
            margin-right: 15px;
        }

        .text-center {
            text-align: center;
        }

        .footer {
            border-top: 1px solid #dee2e6;
            text-align: center;
            padding-top: 10px;
            margin-top: 20px;
            font-size: 12px;
            color: #6c757d;
        }

        .marge-null {
            margin: 0;
        }

        .taille {
            font-size: 11px;
        }

        p {
            font-size: 10px;
        }

        h4,
        h6,
        h5 {
            margin: 0;
        }


        label {
            font-size: 12px;
            display: inline-block;
            vertical-align: middle;
        }

        input[type="checkbox"] {
            font-size: 12px;
            display: inline-block;
            vertical-align: middle;
        }
    </style>
</head>

<body>

    <div class="container">
        <div class="header text-center">
            PROCEDURES D'INFRACTIONS: FICHE DE SIGNALAMENT AU STATIONNEMENT
        </div>
        <table>
            <tr>
                <th>NUMERO DU VEHICULE:</th>
                <td>{{$carPosition->numero_vehicule}}</td>
                <th>SECTEUR:</th>
                <td>{{$carPosition->commune}}</td>
            </tr>
            <tr>
                <th>DATE:</th>
                <td>{{ $carPosition->created_at->format('d F Y') }}</td>
                <th>HEURE:</th>
                <td>{{ $carPosition->created_at->format('H:i') }}</td>
            </tr>
            <tr>
                <th colspan="2">Lieu:</th>
                <td colspan="2">
                    <div class="checkbox-group">
                        <input type="checkbox" id="prive" name="agent" value="PRIVE" {{ old('lieu', $carPosition->lieu) == 'PRIVE' ? 'checked' : '' }}>
                        <label for="prive">PRIVE</label>
                        <input type="checkbox" id="public" name="agent" value="PUBLIC" {{ old('lieu', $carPosition->lieu) == 'PUBLIC' ? 'checked' : '' }}>
                        <label for="public">PUBLIC</label>
                    </div>
                </td>
            </tr>
            <tr>
                <th>MARQUE:</th>
                <td>{{$carPosition->marque}}</td>
                <th>COULEUR:</th>
                <td>{{$carPosition->couleur}}</td>
            </tr>
            <tr>
                <th>TYPE:</th>
                <td>{{$carPosition->type_car}}</td>
                <th>MOTIF INFRACTION:</th>
                <td>{{$carPosition->motif_infraction}}</td>
            </tr>
            <tr>
                <th>MODÈLE:</th>
                <td>{{$carPosition->model}}</td>
                <th>CATÉGORIE:</th>
                <td>{{$carPosition->categorie}}</td>
            </tr>
            <tr>
                <th>ENTRETIEN:</th>
                <td>{{$carPosition->entretien}}</td>
                <th>AGENT:</th>
                <td>{{ $carPosition->agent?->first_name }} {{ $carPosition->agent?->last_name }}</td>
            </tr>
        </table>
        <p><strong>Explication :</strong> {{ $carPosition->explication_infraction ?: 'Non renseignée' }}</p>
        <p><strong>Pièces manquantes :</strong> {{ $carPosition->pieces_manquantes ?: 'Aucune précisée' }}</p>
        <p><strong>État de l’approbation :</strong>
            {{ $carPosition->etat === 'REJETE' ? 'Refusé' : ($carPosition->is_approve ? 'Approuvé' : 'En attente') }}
            @if($carPosition->motife_approbation) — {{ $carPosition->motife_approbation }} @endif
        </p>
        <p><strong>Photos du citoyen :</strong> {{ $carPosition->photo->where('position', '!=', 'agent_constat')->count() }} ·
           <strong>Photos de l’agent :</strong> {{ $carPosition->photo->where('position', 'agent_constat')->count() }}</p>

        @php($signatureAgent = \App\Support\SignatureAgent::dataUri($carPosition))
        <div style="margin-top:18px;border:1px solid #c8d3cc;border-radius:8px;padding:12px;width:60%;">
            <p style="margin:0 0 6px;"><strong>Signature de l’agent verbalisateur :</strong>
                {{ trim(($carPosition->agent?->first_name ?? '').' '.($carPosition->agent?->last_name ?? '')) ?: 'Agent non renseigné' }}</p>
            @if($signatureAgent)
                <img src="{{ $signatureAgent }}" alt="Signature de l’agent" style="max-width:260px;max-height:110px;">
                @if($carPosition->pv_signe_at)
                    <p style="margin:6px 0 0;font-size:12px;color:#555;">Signé le {{ \Carbon\Carbon::parse($carPosition->pv_signe_at)->format('d/m/Y à H\hi') }}{{ $carPosition->pv_numero ? ' · '.$carPosition->pv_numero : '' }}</p>
                @endif
            @else
                <p style="margin:0;font-size:12px;color:#555;">Procès-verbal pas encore signé par l’agent dans l’application.</p>
            @endif
        </div>

        <div class="footer">
            PROCEDURES D'INFRACTIONS: FICHE DE SIGNALAMENT AU STATIONNEMENT
        </div>
    </div>

</body>

</html>