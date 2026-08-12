<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    //return view('welcome');
    abort(403, 'Forbidden');
});

Route::get('/test-env', function () {
    return response()->json([
        'login' => env('ORANGE_SMS_LOGIN'),
        'token' => env('ORANGE_SMS_TOKEN'),
        'api_key' => env('ORANGE_SMS_API_KEY'),
        'base_uri' => env('ORANGE_SMS_BASE_URI'),
    ]);
});

