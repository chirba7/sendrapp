<?php
namespace App\Http\Controllers;

use App\Services\OrangeSmsService;
use Illuminate\Http\Request;

class SMSController extends Controller
{
    protected $smsService;

    public function __construct(OrangeSmsService $smsService)
    {
        $this->smsService = $smsService;
    }

    public function sendSms(Request $request)
    {
        /*if (!auth()->check()) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }*/

        $request->validate([
            'subject' => 'required|string|max:100',
            'signature' => 'required|string|max:100',
            'recipient' => ['required', 'regex:/^221\d{9}$/'], // Validates a 9-digit number without "221"
            'content' => 'required|string|max:1600',
        ]);

        $response = $this->smsService->sendSms(
            $request->subject,
            $request->signature,
            $request->recipient,
            $request->content
        );

      

        return response()->json($response, $response['success'] ? 200 : 500);
    }
}
