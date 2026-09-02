<?php

namespace App\Support;

/**
 * Les photos envoyées telles quelles par un appareil photo de téléphone
 * (souvent 3000px+ de large) gonflaient inutilement le stockage et la
 * taille des réponses API (listerSignalements/voirSignalements embarquent
 * l'URL de l'image, chargée ensuite par l'app mobile). Redimensionne à une
 * dimension maximale raisonnable pour l'affichage, sans dépendance externe
 * (utilise l'extension GD déjà présente dans l'image Docker du backend).
 */
class ImageOptimizer
{
    /**
     * Redimensionne (si besoin) et réencode une image binaire.
     *
     * Encode en JPEG si le build GD le supporte (bien plus compact pour une
     * photo) ; certains builds GD (constaté sur l'image Docker locale) sont
     * compilés sans libjpeg (imagejpeg() n'existe alors pas) — on retombe
     * silencieusement sur PNG dans ce cas, sans jamais faire planter l'appel.
     *
     * @param string $binary Contenu binaire de l'image source (déjà validé comme image réelle)
     * @param int $maxDimension Largeur/hauteur maximale en pixels
     * @param int $jpegQuality Qualité JPEG (0-100), utilisée seulement si JPEG disponible
     * @return array{binary: string, extension: string} Contenu réencodé + extension de fichier à utiliser
     */
    public static function resize(string $binary, int $maxDimension = 1600, int $jpegQuality = 82): array
    {
        $source = @imagecreatefromstring($binary);
        if ($source === false) {
            return ['binary' => $binary, 'extension' => 'png'];
        }

        $width = imagesx($source);
        $height = imagesy($source);
        $scale = min(1, $maxDimension / max($width, $height));

        if ($scale < 1) {
            $newWidth = max(1, (int) round($width * $scale));
            $newHeight = max(1, (int) round($height * $scale));
            $resized = imagecreatetruecolor($newWidth, $newHeight);
            // Fond blanc avant copie : une image source avec canal alpha
            // laisserait sinon un fond noir une fois exportée en JPEG, qui
            // ne supporte pas la transparence.
            imagefill($resized, 0, 0, imagecolorallocate($resized, 255, 255, 255));
            imagecopyresampled($resized, $source, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
            imagedestroy($source);
            $source = $resized;
        }

        $useJpeg = function_exists('imagejpeg');

        ob_start();
        if ($useJpeg) {
            imagejpeg($source, null, $jpegQuality);
        } else {
            // Niveau de compression PNG max (0-9) : sans perte, mais reste
            // le seul format garanti disponible sur tous les builds GD.
            imagepng($source, null, 9);
        }
        $output = ob_get_clean();
        imagedestroy($source);

        if ($output === false) {
            return ['binary' => $binary, 'extension' => 'png'];
        }

        return ['binary' => $output, 'extension' => $useJpeg ? 'jpg' : 'png'];
    }
}
