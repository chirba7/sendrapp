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

        // Les téléphones enregistrent souvent la photo « couchée » avec une
        // simple étiquette EXIF d'orientation. GD ignore cette étiquette et
        // la perd au réencodage : la photo apparaissait pivotée dans l'app.
        // On applique la rotation sur les pixels avant de réencoder.
        $source = self::redresser($source, self::orientationExif($binary));

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

    /**
     * Valeur EXIF « Orientation » (1 à 8) d'un JPEG, 1 si absente. Lecture
     * directe des octets : ne dépend pas de l'extension PHP exif.
     */
    public static function orientationExif(string $binary): int
    {
        if (strncmp($binary, "\xFF\xD8", 2) !== 0) {
            return 1;
        }
        $longueur = strlen($binary);
        $pos = 2;
        while ($pos + 4 <= $longueur) {
            if (ord($binary[$pos]) !== 0xFF) {
                return 1;
            }
            $marqueur = ord($binary[$pos + 1]);
            if ($marqueur === 0xD9 || $marqueur === 0xDA) {
                return 1; // fin d'image ou début des données : pas d'EXIF
            }
            $taille = unpack('n', substr($binary, $pos + 2, 2))[1];
            if ($marqueur === 0xE1 && substr($binary, $pos + 4, 6) === "Exif\0\0") {
                return self::lireOrientationTiff(substr($binary, $pos + 10, $taille - 8));
            }
            $pos += 2 + $taille;
        }

        return 1;
    }

    private static function lireOrientationTiff(string $tiff): int
    {
        if (strlen($tiff) < 8) {
            return 1;
        }
        $le = substr($tiff, 0, 2) === 'II';
        $u16 = fn (int $o) => $o + 2 <= strlen($tiff) ? unpack($le ? 'v' : 'n', substr($tiff, $o, 2))[1] : 0;
        $u32 = fn (int $o) => $o + 4 <= strlen($tiff) ? unpack($le ? 'V' : 'N', substr($tiff, $o, 4))[1] : 0;
        $ifd = $u32(4);
        $entrees = $u16($ifd);
        for ($i = 0; $i < $entrees; $i++) {
            $entree = $ifd + 2 + $i * 12;
            if ($u16($entree) === 0x0112) {
                $valeur = $u16($entree + 8);

                return ($valeur >= 1 && $valeur <= 8) ? $valeur : 1;
            }
        }

        return 1;
    }

    /** Applique une orientation EXIF à une image GD. */
    public static function redresser($image, int $orientation)
    {
        if ($orientation <= 1 || !function_exists('imagerotate')) {
            return $image;
        }
        $flip = function ($img, int $mode) {
            if (function_exists('imageflip')) {
                imageflip($img, $mode);
            }

            return $img;
        };
        $rotation = fn ($img, int $angle) => tap(imagerotate($img, $angle, 0), fn () => imagedestroy($img));

        return match ($orientation) {
            2 => $flip($image, IMG_FLIP_HORIZONTAL),
            3 => $rotation($image, 180),
            4 => $flip($image, IMG_FLIP_VERTICAL),
            5 => $flip($rotation($image, 270), IMG_FLIP_HORIZONTAL),
            6 => $rotation($image, 270),
            7 => $flip($rotation($image, 90), IMG_FLIP_HORIZONTAL),
            8 => $rotation($image, 90),
            default => $image,
        };
    }
}
