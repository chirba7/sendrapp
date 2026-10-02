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

    'sendra' => [
        'backoffice_url' => env('BACKOFFICE_URL', 'http://localhost:8001'),
    ],

    'orange_sms' => [
        'login' => env('ORANGE_SMS_LOGIN', ''),
        'api_key' => env('ORANGE_SMS_API_KEY', ''),
        'token' => env('ORANGE_SMS_TOKEN', ''),
        'base_uri' => env('ORANGE_SMS_BASE_URI', 'https://api.orangesmspro.sn:8443/api'),
    ],

];
