<?php

namespace App\Http\Controllers;

use App\Models\ContactMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

/**
 * Messages du formulaire de contact du site web.
 *
 * - storeFromSite : point d'entrée appelé par le serveur du site (Vercel),
 *   protégé par la clé partagée SENDRA_SITE_CONTACT_KEY et un throttle.
 * - index / show / update : back-office, réservé à l'Admin (role:1).
 */
class ContactMessageController extends Controller
{
    public function storeFromSite(Request $request): JsonResponse
    {
        $expected = (string) config('services.site_contact.key');
        $given = (string) $request->header('X-Sendra-Site-Key', '');
        if ($expected === '' || !hash_equals($expected, $given)) {
            return response()->json(['ok' => false, 'message' => 'Accès refusé.'], 401);
        }

        $data = $request->validate([
            'nom' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:190'],
            'telephone' => ['nullable', 'string', 'max:40'],
            'objet' => ['nullable', 'string', 'max:160'],
            'message' => ['required', 'string', 'min:10', 'max:5000'],
            'ip' => ['nullable', 'ip'],
            'user_agent' => ['nullable', 'string', 'max:1000'],
        ]);

        $data['user_agent'] = isset($data['user_agent']) ? Str::limit($data['user_agent'], 250, '') : null;
        $data['statut'] = 'nouveau';

        $msg = ContactMessage::create($data);

        return response()->json(['ok' => true, 'id' => $msg->id], 201);
    }

    public function index(Request $request)
    {
        $statut = $request->query('statut');
        $recherche = trim((string) $request->query('q', ''));

        $messages = ContactMessage::query()
            ->when(array_key_exists((string) $statut, ContactMessage::STATUTS), fn ($q) => $q->where('statut', $statut))
            ->when($recherche !== '', function ($q) use ($recherche) {
                $like = '%' . addcslashes($recherche, '%_\\') . '%';
                $q->where(fn ($w) => $w->where('nom', 'like', $like)
                    ->orWhere('email', 'like', $like)
                    ->orWhere('objet', 'like', $like)
                    ->orWhere('message', 'like', $like));
            })
            ->latest()
            ->paginate(20)
            ->withQueryString();

        $compteurs = ContactMessage::selectRaw('statut, count(*) as total')
            ->groupBy('statut')
            ->pluck('total', 'statut');

        return view('contact-messages.index', compact('messages', 'compteurs', 'statut', 'recherche'));
    }

    public function show(ContactMessage $contactMessage)
    {
        if (!$contactMessage->lu_le) {
            $contactMessage->forceFill(['lu_le' => now()])->save();
        }
        $contactMessage->load('traitePar');

        return view('contact-messages.show', ['msg' => $contactMessage]);
    }

    public function update(Request $request, ContactMessage $contactMessage)
    {
        $data = $request->validate([
            'statut' => ['required', Rule::in(array_keys(ContactMessage::STATUTS))],
            'note_interne' => ['nullable', 'string', 'max:5000'],
        ]);

        if ($data['statut'] === 'traite' && $contactMessage->statut !== 'traite') {
            $data['traite_le'] = now();
            $data['traite_par'] = $request->user()->id;
        } elseif ($data['statut'] !== 'traite') {
            $data['traite_le'] = null;
            $data['traite_par'] = null;
        }

        $contactMessage->update($data);

        return redirect()
            ->route('contact-messages.show', $contactMessage)
            ->with('success', 'Message mis à jour.');
    }
}
