<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreAgentRequest;
use App\Http\Requests\UpdateAgentRequest;
use App\Mail\AuthMail;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class UserController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function agents()
    {
        $users = User::with('role')->where('role_id', 2)->paginate(5);
        return view('comptes.agents', compact('users'));
    }
    public function admin()
    {
        $users = User::with('role')->where('role_id', 1)->paginate(5);
        return view('comptes.admin', compact('users'));
    }
    public function autorites()
    {
        $users = User::with('role')->where('role_id', 3)->paginate(5);
        return view('comptes.autorites', compact('users'));
    }
    public function utilisateurs()
    {
        $users = User::with('role')->where('role_id', 4)->paginate(5);
        return view('comptes.utilisateurs', compact('users'));
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
        return back()->with('success', 'Compte ajouter avec success');
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
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        //
    }
}
