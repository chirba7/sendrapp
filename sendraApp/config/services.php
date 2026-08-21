<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme' => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    // Correction WEB-H-3 : plusieurs vues pointaient en dur vers
    // 'https://backend.sendra.sn/storage/', et SignalementRessource.php
    // (côté backendSendra) vers un domaine personnel tiers totalement
    // différent — aucun des deux n'était le domaine réel de cette app.
    'backend' => [
        'storage_url' => env('BACKEND_STORAGE_URL', 'https://backend.sendra.sn/storage'),
    ],

];
