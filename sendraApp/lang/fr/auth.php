<?php

// Correction : lang/fr/auth.php n'existait pas du tout (seuls actions.php,
// http-statuses.php, validation.php avaient été publiés en français) — tout
// message d'authentification (échec de connexion, mot de passe incorrect,
// trop de tentatives) affichait la clé brute non traduite (ex: "auth.failed")
// au lieu du message clair, puisque locale='fr' dans config/app.php.

return [

    'failed' => 'Ces identifiants ne correspondent pas à nos enregistrements.',
    'password' => 'Le mot de passe fourni est incorrect.',
    'throttle' => 'Trop de tentatives de connexion. Veuillez réessayer dans :seconds secondes.',

];
