<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class AttendanceFaceService
{
    public function ready(): bool
    {
        return (bool) config('attendance_face.enabled')
            && filled(config('attendance_face.token'));
    }

    public function analyze(string $action, array $payload): array
    {
        abort_unless($this->ready(), 503, 'Vérification du visage indisponible.');
        try {
            $response = Http::timeout(90)->withHeaders([
                'X-Face-Token' => config('attendance_face.token'),
            ])->post(rtrim(config('attendance_face.url'), '/').'/'.$action, $payload);
        } catch (\Throwable $error) {
            abort(503, 'Service de vérification du visage indisponible.');
        }
        abort_if($response->serverError(), 503, 'Service de vérification du visage indisponible.');
        if ($response->failed()) {
            $detail = $response->json('detail');
            abort(422, is_string($detail) && mb_strlen($detail) < 200
                ? $detail : 'Capture du visage refusée. Réessayez.');
        }
        return $response->json();
    }
}
