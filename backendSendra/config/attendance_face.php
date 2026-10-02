<?php

return [
    // Leave disabled until the local detector has been installed and evaluated
    // against real devices, photos and replay attempts.
    'enabled' => env('ATTENDANCE_FACE_ENABLED', false),
    'pointage_enabled' => env('ATTENDANCE_FACE_POINTAGE_ENABLED', false),
    'video_required' => env('ATTENDANCE_FACE_VIDEO_REQUIRED', false),
    'angles_required' => env('ATTENDANCE_FACE_ANGLES_REQUIRED', false),
    'url' => env('ATTENDANCE_FACE_URL', 'http://127.0.0.1:8010'),
    'token' => env('ATTENDANCE_FACE_TOKEN'),
];
