# EPAVIE

Application Flutter destinée au grand public. L'inscription est conservée et
la connexion accepte uniquement les comptes de rôle `5` (citoyen).

L'application agents reste dans `../sendra_mobile`. Elle ne propose plus
d'inscription et sa connexion accepte uniquement le rôle `2` (agent).

## Identifiants

- Android : `net.appdevs.sendraCitoyen`
- iOS : `net.appdevs.sendraCitoyen`

Avant de distribuer cette nouvelle application, enregistrer ces identifiants
dans le projet Firebase et régénérer `lib/firebase_options.dart` pour cette
application. La copie contient encore les identifiants Firebase de l'application
source ; la vérification téléphonique ne peut pas être considérée comme validée
pour les nouveaux identifiants tant que cette configuration n'est pas faite.

Les deux applications utilisent désormais les nouveaux logos fournis. Le
parcours d'inscription citoyen comprend trois étapes : numéro, code, profil.

Le champ « Autre situation constatée » de l'application agents nécessite la
migration `backendSendra/database/migrations/2026_09_29_000001_add_autre_situation_to_car_positions.php`
sur la base de données de l'API avant son utilisation.
