<?php

namespace App\Http\Controllers;



use Illuminate\Support\Facades\Auth;
use App\Http\Controllers\Controller;
use App\Http\Requests\RegisterRequest;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

use App\Services\OrangeSmsService;
use App\Models\UserVerificationCode;

class AuthControllerApi extends Controller
{
    /**
     * Create a new AuthController instance.
     *
     * @return void
     */
    protected $smsService;

    public function __construct(OrangeSmsService $smsService=null)
    {
        // Correction API-M-6 : l'auth était vérifiée deux fois — ici via
        // 'auth:api', et par le middleware 'jwt.auth' déjà posé sur les
        // routes protégées dans routes/api.php. On garde une seule couche
        // (le middleware de route), plus explicite à lire.
        $this->smsService = $smsService;
    }

    /**
 * Connexion de l'utilisateur
 *
 * Cette API permet à un utilisateur de se connecter en fournissant son numéro de téléphone et son mot de passe.
 *
 * @group Authentification
 * @bodyParam telephone string requis Le numéro de téléphone de l'utilisateur. Exemple: 774208140
 * @bodyParam password string requis Le mot de passe de l'utilisateur. Exemple: motdepasse123
 * @response 200 {
 *   "success": true,
 *   "token": "eyJhbGciOiJIUzI1...",
 *   "id": 1,
 *   "fullName": "John Doe",
 *   "phone": "774208140",
 *   "token_type": "bearer"
 * }
 * @response 401 {
 *   "error": "Non autorisé"
 * }
 */
    public function login()
    {
        $credentials = request(['telephone', 'password']);

        if (!$token = auth()->attempt($credentials)) {
            return response()->json(['error' => 'Unauthorized'], 401);
        }

        // Un compte supprimé depuis le back-office (colonne `users.deleted`)
        // n'est plus affilié à SENDRA : il ne doit plus obtenir de jeton,
        // même si son mot de passe reste valable.
        if (auth()->user()->deleted) {
            auth()->logout();

            return response()->json(['error' => 'Unauthorized'], 401);
        }

        return $this->respondWithToken($token);
    }

    public function checkPhone(Request $request)
    {
        // Correction API-C-5 : la clé statique ('Sendra@2025!') était forcément
        // extractible de l'app mobile et n'apportait donc aucune protection
        // réelle contre l'énumération de numéros. Protection déplacée sur le
        // throttling de la route (voir routes/api.php).
        $request->validate([
            'telephone' => 'required|regex:/^\d{9}$/', // Phone number format validation
        ]);

        $phoneExists = User::where('telephone', $request->telephone)->exists();

        return response()->json([
            'exists' => $phoneExists
        ], 200);
    }

    /**
 * Envoyer un code de vérification
 *
 * Cette API envoie un code de vérification au numéro de téléphone de l'utilisateur.
 *
 * @group Authentification
 * @bodyParam telephone string requis Le numéro de téléphone auquel envoyer le code de vérification. Exemple: 774208140
 * @response 200 {
 *   "success": true,
 *   "message": "Code de vérification envoyé avec succès."
 * }
 * @response 400 {
 *   "success": false,
 *   "message": "Échec de l'envoi du code de vérification."
 * }
 */
    public function sendVerificationCode(Request $request)
    {
        // Correction API-C-5 : idem checkPhone(), clé statique retirée au
        // profit du throttling de route.
        $request->validate([
            'telephone' => 'required|regex:/^\d{9}$/', // Phone number format validation
        ]);

        $verificationCode = rand(100000, 999999); // Generate a 6-digit code

        $smsResult = $this->smsService->sendSms(
            'Code de vérification',
            'EPAVIE',
            '221'.$request->telephone,
            "Votre code de vérification est: $verificationCode"
        );

        if (($smsResult['success'] ?? false) !== true) {
            return response()->json([
                'success' => false,
                'message' => 'Le SMS de vérification n’a pas pu être envoyé. Veuillez réessayer plus tard.',
            ], 503);
        }

        // Le code n'est valable qu'après confirmation de l'envoi par le prestataire.
        UserVerificationCode::updateOrCreate(
            ['phone' => $request->telephone],
            [
                'code' => $verificationCode,
                'expires_at' => now()->addMinutes(10),
                'verified_at' => null,
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Code de vérification envoyé.',
        ]);
    }


    /**
 * Vérifier le code
 *
 * Cette API permet de vérifier le code envoyé au numéro de téléphone de l'utilisateur.
 *
 * @group Authentification
 * @bodyParam telephone string requis Le numéro de téléphone à vérifier. Exemple: 774208140
 * @bodyParam code string requis Le code de vérification envoyé à l'utilisateur. Exemple: 123456
 * @response 200 {
 *   "success": true,
 *   "message": "Vérification réussie."
 * }
 * @response 400 {
 *   "success": false,
 *   "message": "Code de vérification invalide ou expiré."
 * }
 */
    public function verifyCode(Request $request)
    {
        $request->validate([
            'telephone' => 'required|regex:/^\d{9}$/',
            'code' => 'required|digits:6',
        ]);

        $verification = UserVerificationCode::where('phone', $request->telephone)->first();

        if (!$verification) {
            return response()->json(['success' => false,
            'message' => 'Numéro de téléphone invalide.'], 404);
        }

        if ($verification->isExpired()) {
            return response()->json(['success' => false,
            'message' => 'Le code vérification a expiré.'], 400);
        }

        // Correction API-H-5 : comparaison stricte entre la valeur en base
        // (string) et une valeur potentiellement numérique côté client
        // mobile — toujours fausse dans ce cas. On compare en string des
        // deux côtés.
        if ((string) $verification->code !== (string) $request->code) {
            return response()->json(['success' => false,
            'message' => 'Le code de vérification est invalide.'], 400);
        }

        // Correction API-H-6 : marquer explicitement la vérification comme
        // réussie, pour que register() puisse s'appuyer dessus au lieu de
        // se contenter de l'existence d'un code non expiré.
        $verification->verified_at = now();
        $verification->save();

        // Verification successful
        return response()->json(['success' => true,
        'message' => 'Vérifié avec succés.'], 200);
    }


    /**
 * Inscription d'un utilisateur
 *
 * Cette API permet à un nouvel utilisateur de s'inscrire en fournissant ses informations personnelles.
 *
 * @group Authentification
 * @bodyParam first_name string requis Le prénom de l'utilisateur. Exemple: Jean
 * @bodyParam last_name string requis Le nom de famille de l'utilisateur. Exemple: Dupont
 * @bodyParam telephone string requis Le numéro de téléphone de l'utilisateur. Exemple: 774208140
 * @bodyParam password string requis Le mot de passe de l'utilisateur. Exemple: motdepasse123
 * @response 200 {
 *   "success": true,
 *   "message": "Utilisateur enregistré avec succès."
 * }
 */
    public function register(RegisterRequest $request)
    {
        $request->validate([
            'telephone' => 'required|regex:/^\d{9}$/',
            'first_name' => 'required|string|max:50',
            'last_name' => 'required|string|max:50',
            'password' => 'required|string|min:6',
        ]);

        // Correction API-H-6 : on exigeait seulement l'existence d'un code
        // non expiré, jamais qu'un verifyCode() ait réellement réussi — un
        // compte pouvait donc être créé sans jamais soumettre le bon code.
        $verification = UserVerificationCode::where('phone', $request->telephone)->first();

        if (!$verification || $verification->isExpired() || !$verification->verified_at) {
            return response()->json(['message' => 'Le numéro de téléphone n\'a pas été vérifié ou le code a expiré.'], 400);
        }

        // Create the user
        $user = new User();
        $user->first_name = $request->first_name;
        $user->last_name = $request->last_name;
        $user->telephone = $request->telephone;
        $user->role_id = 5; // Default role
        $user->password = Hash::make($request->password);
        $user->save();

        // Delete the verification record after successful registration
        $verification->delete();

        return response()->json(['message' => 'Registration successful.']);
    }

    /**
     * Réinitialiser le mot de passe (flux "mot de passe oublié").
     *
     * S'appuie sur le même mécanisme de vérification par code que
     * l'inscription (send-verification-code / verify-code) : n'accepte la
     * réinitialisation que si ce numéro a un code vérifié (verified_at) et
     * non expiré — évite qu'un tiers connaissant seulement le numéro de
     * téléphone puisse réinitialiser le mot de passe d'un autre compte.
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'telephone' => 'required|regex:/^\d{9}$/',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $verification = UserVerificationCode::where('phone', $request->telephone)->first();

        if (!$verification || $verification->isExpired() || !$verification->verified_at) {
            return response()->json(['success' => false,
            'message' => 'Le numéro de téléphone n\'a pas été vérifié ou le code a expiré.'], 400);
        }

        $user = User::where('telephone', $request->telephone)->first();
        if (!$user) {
            return response()->json(['success' => false,
            'message' => 'Aucun compte associé à ce numéro.'], 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        $verification->delete();

        return response()->json(['success' => true,
        'message' => 'Mot de passe réinitialisé avec succès.']);
    }

    /**
     * Modifier le mot de passe (utilisateur authentifié, depuis le profil).
     */
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $user = auth()->user();

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json(['success' => false,
            'message' => 'Le mot de passe actuel est incorrect.'], 422);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        return response()->json(['success' => true,
        'message' => 'Mot de passe modifié avec succès.']);
    }

    /**
     * Get the authenticated User.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function me()
    {
        return response()->json(auth()->user());
    }

    /**
     * Log the user out (Invalidate the token).
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout()
    {
        auth()->logout();

        return response()->json(['message' => 'Successfully logged out']);
    }

    /**
     * Refresh a token.
     *
     * @return \Illuminate\Http\JsonResponse
     */
    public function refresh()
    {
        return $this->respondWithToken(auth()->refresh());
    }

    /**
     * Get the token array structure.
     *
     * @param  string $token
     *
     * @return \Illuminate\Http\JsonResponse
     */
    protected function respondWithToken($token)
    {
        // Correction API-M-7 (partielle) : reformater entièrement cette
        // réponse casserait le contrat déjà consommé par l'app mobile
        // publiée (token/id/fullName/phone à la racine). On ajoute juste
        // 'message' pour se rapprocher du format {success, message, ...}
        // utilisé ailleurs, sans retirer/renommer les champs existants.
        return response()->json([
            'success' => true,
            'message' => 'Connexion réussie.',
            'token' => $token,
            'id' => Auth::user()->id,
            'fullName' => Auth::user()->first_name . " " . Auth::user()->last_name,
            'phone' => Auth::user()->telephone,
            'role_id' => Auth::user()->role_id,
            'token_type' => 'bearer',
        ]);
    }

    public function deleteUser(Request $request)
    {
        // Correction API-C-2 : ne supprime plus que le compte de l'appelant
        // authentifié. L'ancienne version acceptait un `telephone` arbitraire
        // dans la requête et supprimait CE compte, permettant à n'importe
        // quel utilisateur connecté de supprimer le compte de n'importe qui.
        $user = Auth::user();

        $user->delete();

        return response()->json(['message' => 'Utilisateur supprimé avec succès.']);
    }
    
}
