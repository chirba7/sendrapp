<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class MissionReception extends Model
{
    protected $casts=['received_at'=>'datetime'];
}
