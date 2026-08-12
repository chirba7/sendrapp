<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

// Fichier : app/Providers/AppServiceProvider.php

use App\Services\SMSGatewayInterface;
use App\Services\TwilioGateway;




class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
        $this->app->bind(SMSGatewayInterface::class, TwilioGateway::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
