<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserVerificationCode extends Model
{
    use HasFactory;

    protected $fillable = ['phone', 'code', 'expires_at'];

    // Check if the verification code has expired
    public function isExpired()
    {
        return now()->greaterThan($this->expires_at);
    }
}

