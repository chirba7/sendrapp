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

    // Correction API-C-5 : la clé était codée en dur ('Sendra@2025!')
    // directement dans AuthControllerApi. La valeur par défaut ci-dessous
    // est identique à l'ancienne valeur pour ne pas casser l'app mobile
    // déjà publiée ; elle doit être déplacée dans .env et changée dès que
    // possible (voir AUDIT_SENDRA.md, finding API-C-5).
    'mobile_security_key' => env('MOBILE_SECURITY_KEY', 'Sendra@2025!'),

];
