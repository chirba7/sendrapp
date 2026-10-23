<?php

namespace App\Console\Commands;

use App\Models\CarPhoto;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

/**
 * Remet droite une photo déjà enregistrée avant le correctif d'orientation
 * EXIF du 23/10/2026 (l'étiquette avait été perdue au réencodage, il n'y a
 * donc plus moyen de la redresser automatiquement).
 *
 *   php artisan photos:pivoter 123 --sens=droite
 *   php artisan photos:pivoter --signalement=45 --sens=gauche
 */
class PivoterPhotoSignalement extends Command
{
    protected $signature = 'photos:pivoter {photo?* : ids de car_photos} {--signalement= : toutes les photos citoyen d\'un signalement} {--sens=droite : droite (90° horaire), gauche, ou retourner (180°)}';

    protected $description = 'Pivote une ou plusieurs photos de signalement déjà enregistrées';

    public function handle(): int
    {
        $angle = match ($this->option('sens')) {
            'droite' => 270, // imagerotate tourne dans le sens antihoraire
            'gauche' => 90,
            'retourner' => 180,
            default => null,
        };
        if ($angle === null) {
            $this->error('--sens doit valoir droite, gauche ou retourner.');

            return self::FAILURE;
        }

        $photos = CarPhoto::query()
            ->when($this->argument('photo'), fn ($q, $ids) => $q->whereIn('id', $ids))
            ->when($this->option('signalement'), fn ($q, $id) => $q->where('card_id', $id)->where('position', '!=', 'agent_constat'))
            ->get();
        if (!$this->argument('photo') && !$this->option('signalement')) {
            $this->error('Indiquez des ids de photo ou --signalement=.');

            return self::FAILURE;
        }

        foreach ($photos as $photo) {
            $disque = Storage::disk('public');
            if (!$disque->exists($photo->filepath)) {
                $this->warn("Photo {$photo->id} : fichier absent ({$photo->filepath}).");
                continue;
            }
            $image = @imagecreatefromstring($disque->get($photo->filepath));
            if ($image === false) {
                $this->warn("Photo {$photo->id} : image illisible.");
                continue;
            }
            $tournee = imagerotate($image, $angle, 0);
            imagedestroy($image);
            ob_start();
            str_ends_with(strtolower($photo->filepath), '.png') ? imagepng($tournee, null, 9) : imagejpeg($tournee, null, 85);
            $disque->put($photo->filepath, ob_get_clean());
            imagedestroy($tournee);
            $this->info("Photo {$photo->id} pivotée ({$this->option('sens')}).");
        }

        return self::SUCCESS;
    }
}
