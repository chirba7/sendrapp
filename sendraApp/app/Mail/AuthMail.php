<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class AuthMail extends Mailable
{
    use Queueable, SerializesModels;

    /**
     * Create a new message instance.
     */
    /**
     * @param bool $isReset Réinitialisation par un administrateur (et non
     *                      création du compte) : le message doit le dire, sinon
     *                      les deux e-mails sont indiscernables et l'utilisateur
     *                      essaie le mot de passe périmé du premier.
     */
    public function __construct(
        public User $user,
        public string $plainPassword,
        public bool $isReset = false
    ) {
        //
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: $this->isReset
                ? 'SENDRA — nouveau mot de passe'
                : 'SENDRA — votre nouveau compte',
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'mail.newCompte',
            with: [
                // Correction WEB-H-5 : le mot de passe HASHÉ ($user->password)
                // était passé à la vue au lieu du mot de passe en clair
                // généré à la création du compte.
                'password' => $this->plainPassword,
                'email' => $this->user->email,
                // Correction WEB-L-1 : 'nom' n'existe pas sur User (colonnes
                // réelles : first_name/last_name) — la vue affichait
                // "Bienvenue,  !" avec un nom vide.
                'nom' => trim($this->user->first_name . ' ' . $this->user->last_name),
                // L'Agent (role_id=2) et le citoyen (5) n'utilisent que
                // l'app mobile, jamais app.sendra.sn — leur envoyer le
                // bouton/lien vers le back-office web n'a pas de sens.
                // 7 = Operateur : il travaille lui aussi depuis le
                // back-office web, il lui faut donc le lien.
                'showWebLink' => in_array($this->user->role_id, [1, 3, 4, 7], true),
                'isReset' => $this->isReset,
                // Date d'envoi : permet de reconnaître le dernier e-mail reçu.
                'sentAt' => now()->format('d/m/Y à H:i'),
                // Le lien pointait en dur sur app.sendra.sn : un compte créé
                // depuis la préproduction recevait un lien vers la production.
                'webUrl' => rtrim(config('app.url'), '/'),
            ],
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}
