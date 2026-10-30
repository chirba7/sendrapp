<?php

/*
|--------------------------------------------------------------------------
| Codes de vérification SMS (OTP)
|--------------------------------------------------------------------------
|
| Correction sécurité (audit du 29/10/2026) :
|  - un code à 6 chiffres sans limite d'essais par numéro se devine par
|    essais répétés depuis plusieurs IP, et /reset-password n'exige que ce
|    code : prise de contrôle de n'importe quel compte ;
|  - l'envoi n'était limité que par IP : on pouvait faire partir des
|    milliers de SMS payants vers des numéros différents.
|
| Les compteurs vivent dans le cache par défaut (CACHE_DRIVER).
*/

return [
    // Durée de validité d'un code, en minutes.
    'validite_minutes' => (int) env('OTP_VALIDITE_MINUTES', 10),

    // Mauvais codes tolérés avant que le code soit détruit (il faut alors
    // en redemander un).
    'essais_max' => (int) env('OTP_ESSAIS_MAX', 5),

    // Délai minimal entre deux SMS vers le même numéro (l'app affiche un
    // compte à rebours de 60 s avant « Renvoyer »).
    'delai_renvoi_secondes' => (int) env('OTP_DELAI_RENVOI_SECONDES', 60),

    // SMS maximum par numéro et par 24 h.
    'max_par_numero_par_jour' => (int) env('OTP_MAX_PAR_NUMERO_PAR_JOUR', 5),

    // Disjoncteur budgétaire : SMS maximum par 24 h, tous numéros confondus.
    // Au-delà, l'envoi est suspendu (503) jusqu'au lendemain et une erreur
    // est journalisée. À ajuster au trafic réel.
    'max_global_par_jour' => (int) env('OTP_MAX_GLOBAL_PAR_JOUR', 500),

    // Numéro à 9 chiffres, sans indicatif : l'app préfixe déjà +221 (écrit
    // en dur à côté du champ) et le serveur envoie toujours vers 221 + numéro.
    // Aucune restriction de préfixe : les plans de numérotation évoluent.
    'format_numero' => '/^\d{9}$/',
];
