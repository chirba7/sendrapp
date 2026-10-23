<?php

namespace App\Support;

use App\Models\CarPosition;
use Illuminate\Http\JsonResponse;

/**
 * Verrou de prise en charge d'un signalement par un agent.
 *
 * Un signalement pris en charge (`agent_id`) ne peut être modifié que par cet
 * agent : deux agents ne peuvent plus saisir la même constatation en même
 * temps. Seul le rôle Agent (2) est concerné : un administrateur ou une
 * autorité garde la main pour corriger.
 */
class PriseEnCharge
{
    /** Réponse 409 si un autre agent détient le signalement, sinon null. */
    public static function refusSiAutreAgent(CarPosition $carPosition): ?JsonResponse
    {
        $user = auth()->user();
        if (!$user || (int) $user->role_id !== 2) {
            return null;
        }
        if ($carPosition->agent_id && (int) $carPosition->agent_id !== (int) $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Ce signalement est pris en charge par '.self::nomAgent($carPosition).'.',
                'pris_en_charge_par' => self::nomAgent($carPosition),
            ], 409);
        }

        return null;
    }

    public static function nomAgent(CarPosition $carPosition): string
    {
        $agent = $carPosition->relationLoaded('agent') ? $carPosition->agent : $carPosition->agent()->first();
        $nom = trim(($agent->first_name ?? '').' '.($agent->last_name ?? ''));

        return $nom !== '' ? $nom : 'un autre agent';
    }
}
