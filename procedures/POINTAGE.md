# Module Pointage — backend Sendra et back-office

Le module est dans `backendSendra` (API mobile) et `sendraApp` (administration), comme les missions. Il utilise leur base commune. Aucun changement dans `sendra-refonte`.

## Activation

Déployer les fichiers des deux applications. Exécuter une seule fois sur la base commune, depuis `backendSendra` :

```sh
php artisan migrate --path=database/migrations/2026_09_28_000001_create_attendance_tables.php --force
php artisan migrate --path=database/migrations/2026_09_28_000002_create_attendance_enrollments.php --force
```

La migration est identique dans les deux applications : Laravel la marque comme exécutée dans la même table `migrations`. Ne pas lancer les deux migrations simultanément. Vider/reconstruire les caches de routes, de configuration et de vues selon la procédure habituelle des deux applications. Le changement de `config/jwt.php` aligne les claims obligatoires avec le TTL existant : `exp` reste obligatoire si `JWT_TTL` est défini, et ne l’est pas pour les sessions sans expiration déjà prévues par ce projet.

En préproduction, le cache fichier Laravel sous `backendSendra-preprod/storage/framework/cache/data` doit rester accessible en écriture à `apache`. Des sous-dossiers créés par des commandes Artisan exécutées en `root` ont provoqué des réponses HTTP 500 sur les requêtes Pointage le 1er octobre 2026. Exécuter les opérations de cache sous le compte web ou vérifier les droits du répertoire après le déploiement.

Dans le back-office, menu **Pointage** (administrateur uniquement) :

1. Créer un site : nom, coordonnées sur la carte ou saisie manuelle, rayon, précision GPS maximale et fuseau horaire.
2. Valider l'inscription d'un employé faite depuis l'application Pointage. Seuls les inscrits approuvés et actifs apparaissent dans la liste des affectations.
3. Affecter un employé validé, avec jours de semaine, début/fin et tolérance.
4. Consulter les présences par date de début du service, site et statut.

## Contrat mobile

Authentification avec le JWT Sendra existant, en-tête `Authorization: Bearer …`. Un compte non approuvé, inactif ou archivé ne peut pas pointer. Les comptes créés depuis l'application Pointage reçoivent le rôle « Employe pointage » et restent inactifs jusqu'à validation par un administrateur. Un compte personnel déjà existant peut se connecter dans l'application Pointage puis envoyer une demande d'adhésion.

- `POST /api/send-verification-code`, puis `POST /api/verify-code` : vérification du téléphone par SMS.
- `POST /api/pointage/inscription` : prénom, nom, téléphone vérifié, mot de passe et confirmation. Crée un compte Pointage en attente.
- `POST /api/login` : obtention du JWT.
- `GET /api/pointage/statut` : identité et état `not_registered`, `pending`, `approved` ou `disabled`.
- `POST /api/pointage/adhesion` : demande d'accès pour un compte Sendra existant connecté dans l'application Pointage.

- `GET /api/pointage/configuration` : `assignment` avec `site`, `open_session` éventuelle et `server_time`. Affectation inactive ou site désactivé : `assignment` vaut `null`, sans masquer la journée ouverte.
- `GET /api/pointage/historique` : pagination Laravel de 30 journées, limitée à l’employé connecté.
- `POST /api/pointage/pointer` : arrivée ou départ (10 requêtes/minute).

### Téléphone autorisé et biométrie native

Après inscription et vérification SMS, l’employé lie son téléphone dans l’application. Une clé aléatoire de 256 bits est conservée dans le stockage local protégé par biométrie forte (empreinte ou Face ID/Touch ID). L’API conserve la clé chiffrée et associe un seul identifiant de téléphone au compte. Le responsable vérifie l’identité en personne avant de valider l’inscription. Un compte connecté sur un autre appareil ne peut pas obtenir de pointage avec sa seule session JWT.

`POST /api/pointage/appareil/enregistrer` lie un appareil au compte encore en attente. `POST /api/pointage/appareil/defi` crée un défi valable deux minutes, lié au compte, à l’appareil, au type de pointage et à l’identifiant de requête. Le téléphone demande la biométrie pour lire la clé, signe le défi par HMAC-SHA256, puis envoie la signature à `POST /api/pointage/pointer`. Le serveur vérifie la signature et consomme le défi dans la transaction de pointage. Un défi utilisé ne peut servir qu’à réémettre exactement le même pointage enregistré.

Le changement de téléphone se fait depuis le back-office : le responsable réinitialise l’appareil, ce qui suspend le pointage et remet l’inscription en attente. L’employé lie le nouveau téléphone, puis le responsable vérifie de nouveau son identité et valide. Les anciens comptes approuvés par le parcours selfie sont remis en attente par la migration pour cette opération. Les routes de selfie ne sont plus exposées ; les anciens profils faciaux ne participent plus à la décision de pointage.

L’adresse IP et la géolocalisation ne servent pas d’identifiant d’appareil. Le GPS continue à vérifier le site au moment du pointage. La biométrie native ne révèle pas quel doigt ou quel visage enregistré sur un même téléphone a réussi : l’usage d’un téléphone dédié à un seul employé reste requis. Les appareils Android doivent prendre en charge Android 11 (API 30) et la biométrie forte. Les versions Android/iOS de l’application doivent être vérifiées sur appareils réels avant généralisation ; iOS nécessite une compilation sur macOS. Le secret symétrique protégé par le système empêche un autre téléphone ordinaire de pointer, mais ne constitue pas une attestation matérielle contre un appareil compromis.

```json
{
  "request_id": "4259b030-b324-4aee-b72c-77550e3bba88",
  "device_id": "5d8ad3cc-155b-4f33-9ee8-26e94b56bddc",
  "challenge_id": "0ed5b0f8-4f4b-4db2-8e98-07482d60837d",
  "device_signature": "<hmac-sha256-en-hexadecimal>",
  "type": "arrival",
  "site_id": 1,
  "latitude": 14.7167,
  "longitude": -17.4677,
  "accuracy_meters": 10,
  "measured_at": "2026-09-28T08:08:00Z"
}
```

Pour le départ, utiliser `type: departure` et un nouvel UUID. En cas de réseau interrompu, réessayer avec le même UUID pour la même opération : le serveur renvoie le résultat déjà enregistré. Le client ne fournit jamais l’identité de l’employé ni l’heure officielle du pointage.

Succès HTTP 200 : `{"success": true, "session": {...}}`. Les statuts d’arrivée sont `early`, `on_time`, `late`. Les erreurs métier sont HTTP 422 avec `message` et `errors`; 401 pour absence de JWT, 403 pour un compte non autorisé, 429 pour trop de requêtes.

## Règles

- Contrôle de distance ponctuel à chaque arrivée/départ ; aucun suivi GPS en arrière-plan, aucun polygone de géofencing.
- Position mesurée depuis au plus 60 secondes, tolérance d’horloge future de 10 secondes, horodatage ISO 8601 avec fuseau explicite. La fraîcheur déclarée par le téléphone n’est pas une attestation matérielle.
- La précision GPS doit être positive et inférieure ou égale au seuil du site. Elle n’agrandit jamais le rayon autorisé. Le GPS reste une mesure incertaine et les coordonnées d’un téléphone peuvent être falsifiées.
- Heure serveur UTC, calcul des horaires dans le fuseau du site. Arrivée acceptée à toute heure d’un jour de travail prévu ; la tolérance détermine si elle est à l’heure ou en retard. Le départ n’est accepté qu’à partir de l’heure de fin prévue. Les services de nuit sont rattachés au jour de début, même après minuit.
- Un planning hebdomadaire et un site par employé ; une arrivée et un départ par jour de service. Une journée ouverte bloque une nouvelle arrivée.
- Les minutes d’écart sont arrondies à la minute supérieure. La tolérance détermine le statut ; l’écart réel est conservé. Une arrivée à 08:08 pour 08:00 avec 5 minutes de tolérance conserve 8 minutes d’écart.
- Horaires, site, rayon et précision sont figés dans la journée lors de l’arrivée. Changer ou désactiver l’affectation/le site n’empêche pas de pointer le départ avec les règles d’origine. Désactiver le compte bloque tout accès.
- Les comptes et sites référencés par le pointage ne peuvent pas être supprimés physiquement ; utiliser leur désactivation/archivage pour conserver l’historique.

## Périmètre restant

L'application Flutter est dans `app_pointage_sendra`. Elle inclut l'inscription, la connexion, l'attente de validation, la liaison d'un appareil, la position précise et l'historique. Les corrections auditées d'oubli de départ, les congés/absences, pauses et exports ne sont pas implémentés. Un départ oublié reste visible « Sans départ » ; il n'est pas automatiquement inventé. Il faut compléter le parcours de régularisation avant un usage quotidien généralisé.

La comparaison faciale et l'anti usurpation sont des contrôles probabilistes. Le clignement vidéo réduit le risque d'une photo fixe ; une attestation matérielle de l'appareil et une évaluation PAD spécialisée renforceraient la résistance aux injections et aux relectures.

## Vérification

```sh
# Depuis backendSendra
php vendor/phpunit/phpunit/phpunit tests/Feature/AttendanceApiTest.php
# Depuis sendraApp
php vendor/phpunit/phpunit/phpunit tests/Feature/AttendanceBackofficeTest.php
```

Ces tests créent uniquement les tables nécessaires dans une base SQLite en mémoire. Ils ne modifient pas les bases configurées pour l’exploitation. Ils ne remplacent pas une validation MySQL de la concurrence et des migrations avant déploiement.
