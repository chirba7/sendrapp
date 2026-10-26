<?php

namespace App\Support;

use App\Models\CarPosition;

/**
 * Signature de l'agent sur le procès-verbal, faite dans l'application Pro.
 *
 * Le fichier est rangé par le backend sur son disque privé (`storage/app`),
 * voisin du disque public que le back-office connaît déjà (`backend`, racine
 * BACKEND_STORAGE_PATH = storage/app/public du backend). On le lit donc
 * dans le dossier parent. Renvoyé en data URI : DomPDF et le navigateur
 * l'affichent sans exposer le fichier publiquement.
 */
class SignatureAgent
{
    public static function dataUri(CarPosition $carPosition): ?string
    {
        if (empty($carPosition->pv_signature)) {
            return null;
        }
        $racine = rtrim((string) config('filesystems.disks.backend.root'), '/');
        $chemin = dirname($racine).'/'.ltrim($carPosition->pv_signature, '/');
        // Pas de remontée hors du dossier du backend.
        if (str_contains($carPosition->pv_signature, '..') || !is_file($chemin) || !is_readable($chemin)) {
            return null;
        }
        $contenu = @file_get_contents($chemin);
        if ($contenu === false || @getimagesizefromstring($contenu) === false) {
            return null;
        }

        return 'data:image/png;base64,'.base64_encode($contenu);
    }
}
