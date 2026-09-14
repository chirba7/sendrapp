<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAgentRequest;
use App\Http\Requests\UpdateAgentRequest;
use App\Mail\AuthMail;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function agents(Request $request)
    {
        return $this->listerComptes($request, 2, 'comptes.agents');
    }
    public function admin(Request $request)
    {
        return $this->listerComptes($request, 1, 'comptes.admin');
    }
    public function autorites(Request $request)
    {
        return $this->listerComptes($request, 3, 'comptes.autorites');
    }
    public function utilisateurs(Request $request)
    {
        return $this->listerComptes($request, 4, 'comptes.utilisateurs');
    }

    /**
     * Liste des comptes d'un rôle. `?archives=1` affiche les comptes
     * supprimés au lieu des comptes actifs — c'est la seule façon de les
     * retrouver et de les restaurer.
     */
    private function listerComptes(Request $request, int $roleId, string $vue)
    {
        $archives = $request->boolean('archives');

        $users = User::with('role')
            ->where('role_id', $roleId)
            ->when(
                $archives,
                fn ($requete) => $requete->archives(),
                fn ($requete) => $requete->nonArchives()
            )
            ->paginate(5)
            ->withQueryString();

        return view($vue, compact('users', 'archives'));
    }
    // Correction WEB-M-1 : aucun écran n'affichait les comptes citoyens
    // (role_id=5, créés depuis l'app mobile) — invisibles depuis le
    // back-office alors qu'ils existent bien en base.
    public function citoyens()
    {
        $users = User::with('role')->where('role_id', 5)->paginate(5);
        return view('comptes.citoyens', compact('users'));
    }
    public function ajouter()
    {
        return view('comptes.add');
    }

    /**
     * Show the form for creating a new resource.
     */
    public function modifierMotDePasse()
    {
        return view('comptes.modifierMotDePasse');
    }

    public function modifierMotDePasse2(Request $request)
    {
        $request->validate([
            'password' => ['required', 'string', 'min:8', 'confirmed', 'regex:/^(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).+$/'],
            'password_confirmation' => ['required'],
        ], [
            'password.required' => 'Le champ mot de passe est requis.',
            'password.string' => 'Le mot de passe doit être une chaîne de caractères.',
            'password.min' => 'Le mot de passe doit contenir au moins :min caractères.',
            'password.confirmed' => 'La confirmation du mot de passe ne correspond pas.',
            'password.regex' => 'Le mot de passe doit contenir au moins une lettre majuscule, un chiffre et un caractère spécial.',
            'password_confirmation.required' => 'Le champ de confirmation du mot de passe est requis.'
        ]);

        $user = Auth::user();
        $user->password = Hash::make($request->password);
        $user->is_enabled = true;
        $user->update();

        return redirect()->route('dashboard')->with('success', 'Votre mot de passe a été modifié avec succès.');
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreAgentRequest $request)
    {
        $user = new User();
        $user->first_name = $request->prenom;
        $user->last_name = $request->nom;
        $user->telephone = $request->telephone;
        $user->role_id = $request->role;
        $user->email = $request->email;
        // Correction WEB-H-5 : mot de passe par défaut identique
        // ('sendra2024@') pour tous les nouveaux comptes staff — un mot de
        // passe aléatoire par compte est généré à la place. Toujours envoyé
        // par e-mail ; is_enabled reste false par défaut donc le
        // changement forcé à la première connexion (IsActiveMiddleware)
        // s'applique déjà.
        $temporaryPassword = Str::random(12);
        $user->password = Hash::make($temporaryPassword);
        if ($user->save()) {
            Mail::to($request->email)->send(new AuthMail($user, $temporaryPassword));
        }
        return back()->with('success', 'Compte ajouter avec success');
    }

    // Correction WEB-M-5 : route /test et cette méthode supprimées — elle
    // envoyait par e-mail les données de l'utilisateur connecté (y compris
    // le hash du mot de passe) vers une adresse personnelle codée en dur.

    public function modifier(UpdateAgentRequest $request, User $user)
    {
        $user->first_name = $request->prenom;
        $user->last_name = $request->nom;
        $user->telephone = $request->telephone;
        $user->role_id = $request->role;
        $user->email = $request->email;

        $user->update();
        // Correction : le message reprenait celui de la création de compte
        // (copier-coller de store()) — trompeur sur une simple modification.
        return back()->with('success', 'Compte modifié avec succès');
    }

    /**
     * Réinitialise le mot de passe d'un compte (Admin uniquement, déjà
     * garanti par le middleware role:1 sur ce groupe de routes). Génère un
     * mot de passe temporaire et le transmet par e-mail — jamais saisi en
     * clair par l'Admin, pour éviter qu'un mot de passe ne transite dans la
     * requête ou reste affiché à l'écran (même logique que store()).
     */
    public function resetPassword(User $user)
    {
        if (!$user->email) {
            return back()->with('error', "Impossible de réinitialiser : ce compte n'a pas d'adresse e-mail renseignée.");
        }

        $temporaryPassword = Str::random(12);
        $user->password = Hash::make($temporaryPassword);
        // Force le changement de mot de passe à la prochaine connexion,
        // comme pour un compte nouvellement créé (IsActiveMiddleware).
        $user->is_enabled = false;
        $user->save();

        // Le mot de passe est déjà changé à ce stade : un échec d'envoi
        // (serveur SMTP injoignable, ex. constaté sur cet environnement)
        // ne doit pas faire planter la requête en 500 alors que l'action
        // a réussi — même logique que
        // DommagesController::notifierAdministrateurs().
        try {
            Mail::to($user->email)->send(new AuthMail($user, $temporaryPassword));
            return back()->with('success', 'Mot de passe réinitialisé — un nouveau mot de passe temporaire a été envoyé à ' . $user->email . '.');
        } catch (\Throwable $exception) {
            Log::error("Échec de l'envoi de l'e-mail de réinitialisation de mot de passe.", [
                'userId' => $user->id,
                'exception' => $exception->getMessage(),
            ]);
            // Repli : sans e-mail fonctionnel, l'Admin doit pouvoir
            // communiquer le mot de passe autrement, sinon le compte reste
            // bloqué sans que personne ne connaisse le nouveau mot de passe.
            return back()->with('warning', "Mot de passe réinitialisé, mais l'e-mail n'a pas pu être envoyé (serveur mail injoignable). Mot de passe temporaire à transmettre manuellement : " . $temporaryPassword);
        }
    }

    /**
     * Display the specified resource.
     */
    public function show(User $user)
    {
        return view('comptes.show', compact('user'));
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(User $user)
    {
        return back()->with('success', 'compte modifié avec succès');
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request)
    {
        $user = Auth::user();
        $data = $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email|max:255',
        ], [
            'first_name.required' => 'Le champ Nom est requis.',
            'last_name.required' => 'Le champ Prénom est requis.',
            'email.required' => 'Le champ "Email" est requis.',
            'email.email' => 'Veuillez entrer une adresse email valide.',
            'email.max' => 'L\'email ne peut pas dépasser 255 caractères.',
        ]);


        $user->first_name = $data['first_name'];
        $user->last_name = $data['last_name'];
        $user->email = $data['email'];

        $user->update();

        return redirect()->route('dashboard')->with('success', 'Votre mot de passe a été modifié avec succès.');
    }


    public function updatepass(Request $request)
    {

        $request->validate([
            'current_password' => 'required',
            'password' => ['required', 'string', 'min:8', 'confirmed', 'regex:/^(?=.*[A-Z])(?=.*\d)(?=.*[^a-zA-Z\d]).+$/'],
            'password_confirmation' => ['required'],
        ], [
            'current_password.required' => 'Le champ mot de passe actuel est requis.',
            'password.required' => 'Le champ mot de passe est requis.',
            'password.string' => 'Le mot de passe doit être une chaîne de caractères.',
            'password.min' => 'Le mot de passe doit contenir au moins :min caractères.',
            'password.confirmed' => 'La confirmation du mot de passe ne correspond pas.',
            'password.regex' => 'Le mot de passe doit contenir au moins une lettre majuscule, un chiffre et un caractère spécial.',
            'password_confirmation.required' => 'Le champ de confirmation du mot de passe est requis.'
        ]);

        $user = Auth::user();

        if (!Hash::check($request->current_password, $user->password)) {
            return redirect()->back()->withErrors(['current_password' => 'Le mot de passe actuel est incorrect.']);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        $request->session()->invalidate();

        return redirect()->route('login')->with('success', 'Mot de passe mis à jour avec succès ! Veuillez vous reconnecter.');
    }
    /**
     * Supprime un compte qui n'est plus affilié à SENDRA.
     *
     * La ligne n'est pas effacée : `car_positions.user_id` et
     * `car_positions.agent_id` sont en ON DELETE CASCADE, un vrai DELETE
     * emporterait tous les signalements du compte, leurs photos et leurs
     * dommages. Le compte est marqué `deleted` : il sort des listes, ne
     * peut plus se connecter (middleware `notArchived`) et n'est plus
     * destinataire des e-mails de demande d'approbation envoyés par le
     * backend. Réservé aux Admins par le middleware `role:1` de la route.
     */
    public function destroy(User $user)
    {
        if ($user->id === Auth::id()) {
            return back()->with('error', 'Vous ne pouvez pas supprimer votre propre compte.');
        }

        if (!in_array((int) $user->role_id, [1, 2, 3, 4], true)) {
            return back()->with('error', 'Seuls les comptes du personnel (Admin, Agent, Autorité commune, Autorité préfecture) peuvent être supprimés ici.');
        }

        if ($user->estArchive()) {
            return back()->with('error', 'Ce compte est déjà supprimé.');
        }

        // Garde-fou : il doit rester au moins un Admin actif, sinon plus
        // personne ne peut gérer les comptes — ni restaurer celui-ci.
        $dernierAdmin = (int) $user->role_id === 1
            && User::nonArchives()->where('role_id', 1)->where('id', '!=', $user->id)->doesntExist();

        if ($dernierAdmin) {
            return back()->with('error', "Impossible de supprimer ce compte : c'est le dernier Admin actif.");
        }

        $user->deleted = true;
        $user->save();

        Log::info('Compte supprimé (archivé).', [
            'userId' => $user->id,
            'email' => $user->email,
            'parUserId' => Auth::id(),
        ]);

        return back()->with('success', 'Compte supprimé : il n’apparaît plus dans les listes, ne peut plus se connecter et ne reçoit plus les e-mails. Il reste restaurable depuis « Comptes supprimés ».');
    }

    /**
     * Restaure un compte supprimé par erreur.
     */
    public function restaurer(User $user)
    {
        if (!$user->estArchive()) {
            return back()->with('error', "Ce compte n'est pas supprimé.");
        }

        $user->deleted = false;
        $user->save();

        Log::info('Compte restauré.', [
            'userId' => $user->id,
            'parUserId' => Auth::id(),
        ]);

        return back()->with('success', 'Compte restauré avec succès.');
    }
}
