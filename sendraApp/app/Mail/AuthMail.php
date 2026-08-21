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
    public function __construct(public User $user, public string $plainPassword)
    {
        //
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Nouveau Compte Chez SENDRA',
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
