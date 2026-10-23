<?php

namespace App\Support;

/**
 * Générateur PDF minimal, sans dépendance Composer (le backend n'embarque pas
 * DomPDF et on ne veut pas d'un `composer install` en production pour un seul
 * document). Suffisant pour un procès-verbal : texte Helvetica (accents
 * français via WinAnsi), rectangles, traits et images JPEG/PNG.
 *
 * Les coordonnées de l'API sont en points, origine en HAUT à gauche (y vers le
 * bas), sur une page A4 portrait (595 × 842).
 */
class PdfSimple
{
    public const LARGEUR = 595.28;
    public const HAUTEUR = 841.89;

    /** @var array<int, string> contenu de chaque page */
    private array $pages = [];

    /** @var array<string, array{w:int,h:int,dict:string,data:string}> */
    private array $images = [];

    /** Largeurs Helvetica (1/1000 em) pour les octets 32..126 ; 556 sinon. */
    private const LARGEURS = [
        32 => 278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278,
        556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556,
        1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778,
        667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556,
        333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556,
        556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584,
    ];

    public function ajouterPage(): void
    {
        $this->pages[] = '';
    }

    public function nombrePages(): int
    {
        return count($this->pages);
    }

    private function ecrire(string $ops): void
    {
        if (!$this->pages) {
            $this->ajouterPage();
        }
        $this->pages[count($this->pages) - 1] .= $ops."\n";
    }

    private static function f(float $v): string
    {
        return rtrim(rtrim(number_format($v, 2, '.', ''), '0'), '.');
    }

    private static function couleur(array $rgb): string
    {
        return implode(' ', array_map(fn ($c) => self::f($c / 255), $rgb));
    }

    /** Convertit l'UTF-8 en Windows-1252 (WinAnsiEncoding). */
    public static function versWinAnsi(string $texte): string
    {
        $texte = str_replace(["\r\n", "\r", "\t"], ["\n", "\n", ' '], $texte);
        if (function_exists('mb_convert_encoding')) {
            $sortie = @mb_convert_encoding($texte, 'Windows-1252', 'UTF-8');
            if ($sortie !== false && $sortie !== null) {
                return $sortie;
            }
        }
        $sortie = @iconv('UTF-8', 'Windows-1252//TRANSLIT', $texte);

        return $sortie === false ? $texte : $sortie;
    }

    public function largeurTexte(string $texteUtf8, float $taille, bool $gras = false): float
    {
        $octets = self::versWinAnsi($texteUtf8);
        $total = 0;
        for ($i = 0, $n = strlen($octets); $i < $n; $i++) {
            $total += self::LARGEURS[ord($octets[$i])] ?? 556;
        }

        return $total * $taille / 1000 * ($gras ? 1.07 : 1);
    }

    /** Découpe un texte en lignes tenant dans $largeurMax. */
    public function couperTexte(string $texte, float $taille, float $largeurMax, bool $gras = false): array
    {
        $lignes = [];
        foreach (explode("\n", str_replace(["\r\n", "\r"], "\n", $texte)) as $paragraphe) {
            $courante = '';
            foreach (preg_split('/\s+/u', trim($paragraphe)) ?: [] as $mot) {
                if ($mot === '') {
                    continue;
                }
                $essai = $courante === '' ? $mot : $courante.' '.$mot;
                if ($this->largeurTexte($essai, $taille, $gras) <= $largeurMax || $courante === '') {
                    $courante = $essai;
                } else {
                    $lignes[] = $courante;
                    $courante = $mot;
                }
            }
            $lignes[] = $courante;
        }

        return $lignes;
    }

    public function texte(float $x, float $y, string $texte, float $taille = 10, bool $gras = false, array $rgb = [21, 32, 26]): void
    {
        $octets = self::versWinAnsi($texte);
        $echappe = str_replace(['\\', '(', ')', "\n"], ['\\\\', '\\(', '\\)', ' '], $octets);
        $police = $gras ? 'F2' : 'F1';
        $yPdf = self::HAUTEUR - $y - $taille * 0.8;
        $this->ecrire(sprintf(
            'BT /%s %s Tf %s rg %s %s Td (%s) Tj ET',
            $police, self::f($taille), self::couleur($rgb), self::f($x), self::f($yPdf), $echappe
        ));
    }

    public function rectangle(float $x, float $y, float $l, float $h, ?array $remplissage = null, ?array $trait = null, float $epaisseur = 0.8): void
    {
        $ops = 'q ';
        if ($remplissage) {
            $ops .= self::couleur($remplissage).' rg ';
        }
        if ($trait) {
            $ops .= self::couleur($trait).' RG '.self::f($epaisseur).' w ';
        }
        $ops .= sprintf('%s %s %s %s re ', self::f($x), self::f(self::HAUTEUR - $y - $h), self::f($l), self::f($h));
        $ops .= $remplissage && $trait ? 'B' : ($remplissage ? 'f' : 'S');
        $this->ecrire($ops.' Q');
    }

    public function trait(float $x1, float $y1, float $x2, float $y2, array $rgb = [200, 210, 204], float $epaisseur = 0.8): void
    {
        $this->ecrire(sprintf(
            'q %s RG %s w %s %s m %s %s l S Q',
            self::couleur($rgb), self::f($epaisseur),
            self::f($x1), self::f(self::HAUTEUR - $y1), self::f($x2), self::f(self::HAUTEUR - $y2)
        ));
    }

    /**
     * Enregistre une image (JPEG intégré tel quel, autre format converti par
     * GD). Renvoie sa clé et ses dimensions, ou null si illisible.
     *
     * @return array{cle:string,w:int,h:int}|null
     */
    public function chargerImage(string $binaire, int $tailleMax = 1000): ?array
    {
        $infos = @getimagesizefromstring($binaire);
        if ($infos === false) {
            return null;
        }
        [$w, $h, $type] = $infos;

        // Photo trop grande : on la réduit pour garder un PV léger (si GD sait
        // relire et réécrire le JPEG).
        if ($type === IMAGETYPE_JPEG && max($w, $h) > $tailleMax
            && function_exists('imagecreatefromstring') && function_exists('imagejpeg')) {
            $reduit = ImageOptimizer::resize($binaire, $tailleMax, 80);
            if ($reduit['extension'] === 'jpg') {
                $binaire = $reduit['binary'];
                $infos = @getimagesizefromstring($binaire) ?: $infos;
                [$w, $h, $type] = $infos;
            }
        }

        if ($type === IMAGETYPE_JPEG) {
            $canaux = $infos['channels'] ?? 3;
            $espace = $canaux === 1 ? '/DeviceGray' : ($canaux === 4 ? '/DeviceCMYK /Decode [1 0 1 0 1 0 1 0]' : '/DeviceRGB');
            $dict = "/Type /XObject /Subtype /Image /Width $w /Height $h /ColorSpace $espace /BitsPerComponent 8 /Filter /DCTDecode";
            $donnees = $binaire;
        } else {
            $source = function_exists('imagecreatefromstring') ? @imagecreatefromstring($binaire) : false;
            if ($source === false) {
                return null;
            }
            $w = imagesx($source);
            $h = imagesy($source);
            if (max($w, $h) > $tailleMax) {
                $echelle = $tailleMax / max($w, $h);
                $nw = max(1, (int) round($w * $echelle));
                $nh = max(1, (int) round($h * $echelle));
                $reduit = imagecreatetruecolor($nw, $nh);
                imagefill($reduit, 0, 0, imagecolorallocate($reduit, 255, 255, 255));
                imagecopyresampled($reduit, $source, 0, 0, 0, 0, $nw, $nh, $w, $h);
                imagedestroy($source);
                $source = $reduit;
                [$w, $h] = [$nw, $nh];
            }
            // Pixels RGB composés sur fond blanc (la transparence d'une
            // signature PNG donnerait sinon un fond noir).
            $brut = '';
            for ($y = 0; $y < $h; $y++) {
                for ($x = 0; $x < $w; $x++) {
                    $c = imagecolorsforindex($source, imagecolorat($source, $x, $y));
                    $a = 1 - ($c['alpha'] ?? 0) / 127;
                    $brut .= chr((int) round($c['red'] * $a + 255 * (1 - $a)))
                        .chr((int) round($c['green'] * $a + 255 * (1 - $a)))
                        .chr((int) round($c['blue'] * $a + 255 * (1 - $a)));
                }
            }
            imagedestroy($source);
            $dict = "/Type /XObject /Subtype /Image /Width $w /Height $h /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode";
            $donnees = gzcompress($brut, 6);
        }

        $cle = 'Im'.(count($this->images) + 1);
        $this->images[$cle] = ['w' => $w, 'h' => $h, 'dict' => $dict, 'data' => $donnees];

        return ['cle' => $cle, 'w' => $w, 'h' => $h];
    }

    /** Dessine une image enregistrée, ajustée dans la boîte (proportions gardées). Renvoie la hauteur utilisée. */
    public function image(array $image, float $x, float $y, float $lMax, float $hMax): float
    {
        $echelle = min($lMax / $image['w'], $hMax / $image['h']);
        $l = $image['w'] * $echelle;
        $h = $image['h'] * $echelle;
        $this->ecrire(sprintf(
            'q %s 0 0 %s %s %s cm /%s Do Q',
            self::f($l), self::f($h), self::f($x), self::f(self::HAUTEUR - $y - $h), $image['cle']
        ));

        return $h;
    }

    public function rendu(): string
    {
        $objets = [];
        $objets[1] = '<< /Type /Catalog /Pages 2 0 R >>';
        $objets[3] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>';
        $objets[4] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>';

        $prochain = 5;
        $refsImages = [];
        foreach ($this->images as $cle => $img) {
            $objets[$prochain] = ['dict' => $img['dict'], 'flux' => $img['data']];
            $refsImages[] = "/$cle $prochain 0 R";
            $prochain++;
        }
        $ressources = '<< /Font << /F1 3 0 R /F2 4 0 R >> /XObject << '.implode(' ', $refsImages).' >> >>';

        $kids = [];
        foreach ($this->pages ?: [''] as $contenu) {
            $idContenu = $prochain++;
            $idPage = $prochain++;
            $objets[$idContenu] = ['dict' => '', 'flux' => gzcompress($contenu, 6), 'filtre' => true];
            $objets[$idPage] = sprintf(
                '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 %s %s] /Resources %s /Contents %d 0 R >>',
                self::f(self::LARGEUR), self::f(self::HAUTEUR), $ressources, $idContenu
            );
            $kids[] = "$idPage 0 R";
        }
        $objets[2] = '<< /Type /Pages /Kids ['.implode(' ', $kids).'] /Count '.count($kids).' >>';
        ksort($objets);

        $pdf = "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";
        $positions = [];
        foreach ($objets as $id => $objet) {
            $positions[$id] = strlen($pdf);
            if (is_array($objet)) {
                $dict = trim($objet['dict'].(!empty($objet['filtre']) ? ' /Filter /FlateDecode' : ''));
                $pdf .= "$id 0 obj\n<< $dict /Length ".strlen($objet['flux'])." >>\nstream\n".$objet['flux']."\nendstream\nendobj\n";
            } else {
                $pdf .= "$id 0 obj\n$objet\nendobj\n";
            }
        }
        $xref = strlen($pdf);
        $total = max(array_keys($objets)) + 1;
        $pdf .= "xref\n0 $total\n0000000000 65535 f \n";
        for ($i = 1; $i < $total; $i++) {
            $pdf .= isset($positions[$i]) ? sprintf("%010d 00000 n \n", $positions[$i]) : "0000000000 65535 f \n";
        }
        $pdf .= "trailer\n<< /Size $total /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n";

        return $pdf;
    }
}
