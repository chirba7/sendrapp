<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class MissionReception extends Model
{
    protected $fillable = ['mission_id','mission_removal_id','received_by','front_photo_path','back_photo_path','left_photo_path','right_photo_path','sheet_photo_path','received_at'];
    protected $casts = ['received_at'=>'datetime'];
    public function removal() { return $this->belongsTo(MissionRemoval::class, 'mission_removal_id'); }
}
