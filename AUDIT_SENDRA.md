# Plateforme Sendra — Documentation actuelle, Spécifications & Audit

**Objectif de ce document :** servir de base à une **refonte de la plateforme** — comprendre ce qui existe aujourd'hui (systèmes, fonctionnalités, données), et savoir précisément quoi corriger, quoi jeter, quoi garder.

**Date :** 12 août 2026
**Domaine racine :** sendra.sn (et sous-domaines)

**Résumé chiffré des problèmes identifiés :** 8 critiques · 12 élevés · 12 moyens · 13 faibles/dette — répartis sur 3 systèmes de code + 1 exposition d'infrastructure.

---

# Partie 0 — Vue d'ensemble : ce qui tourne réellement

Le nom de domaine `sendra.sn` recouvre **5 systèmes distincts**, découverts en lisant les vhosts Apache (les noms de dossiers ne suffisent pas à savoir ce qui est réellement servi — un premier passage de cet audit s'est d'ailleurs trompé de dossier avant vérification via `/etc/httpd/conf.d/`) :

| Sous-domaine | Rôle | Code | Base de données |
|---|---|---|---|
| **backend.sendra.sn** | API consommée par l'application mobile (citoyens) | `/var/www/backendSendra` — Laravel 10.47, JWT (tymon/jwt-auth) | MySQL `sendra` |
| **app.sendra.sn** | Back-office web pour le personnel (Admin/Agent/Autorités) | `/var/www/sendraApp` — Laravel 10.47, Jetstream + Blade, session Sanctum | **Même** MySQL `sendra` |
| **private.sendra.sn** | Adminer (interface d'admin MySQL) | `/var/www/adminer` — fichier unique tiers | Accès direct à toutes les bases |
| **erp.sendra.sn** | Odoo (ERP tiers), reverse-proxy Apache vers `127.0.0.1:8069` | Pas de code custom — aucune intégration trouvée avec le reste | Base(s) Odoo séparée(s) |
| *(aucun sous-domaine dédié)* | ~9 copies datées de l'app abandonnées dans `/var/www/` | `backendSendra_21112024`, `_25112024`, `_27062024`, `_17012025`, `backendsendra_Aboubacry`, `backendSendra_Avant_Prise_en_main`, `sendraApp_04122024`, `backend.sendra.sn/backendSendra` | — |

**Point clé pour la refonte :** `backendSendra` (API mobile) et `sendraApp` (back-office web) sont **deux codebases Laravel entièrement séparées qui partagent la même base de données**, chacune avec sa **propre copie dupliquée** des modèles Eloquent (`User`, `CarPosition`, `CarPhoto`, `Role`, `Commune`, `Secteur`, `TProcedure`, `Constatation`, `Verification`, `VerificationCode`, `MobileAppInformation`, `Agent`). Rien ne garantit que ces deux copies restent alignées entre elles ni avec le schéma réel — c'est une source de dérive silencieuse documentée dans plusieurs findings ci-dessous, et un choix d'architecture à trancher explicitement dans la refonte (monolithe unique ? service partagé ? API interne ?).

Odoo (erp.sendra.sn) est un système tiers autonome : aucune intégration de code n'a été trouvée entre Odoo et les deux applications Laravel. Il n'est pas couvert par l'audit de code (hors périmètre : produit fermé), seule son exposition réseau est notée en Partie 2.

---

# Partie 1 — Spécification fonctionnelle actuelle

## 1.1 Modèle de rôles (partagé par les deux apps)

Table `roles` (contenu réel en base) :

| id | nomRole | Usage constaté |
|---|---|---|
| 1 | Admin | Back-office complet, gestion des comptes |
| 2 | Agent | Traite les signalements (véhicule/infraction/dommages), pas d'accès à l'approbation |
| 3 | Autorité commune | Back-office, approbation |
| 4 | Autorité préfecture | Back-office (écran mal étiqueté "Utilisateurs" — voir WEB-M-1) |
| 5 | user | Citoyens inscrits depuis l'app mobile — rôle par défaut à l'inscription |

## 1.2 API mobile — `backendSendra` (backend.sendra.sn)

**Authentification** (`AuthControllerApi`) : inscription avec vérification par SMS (OTP à 6 chiffres, 10 min d'expiration), login par téléphone+mot de passe (JWT), rafraîchissement de token, suppression de compte.

**Cycle de vie d'un signalement** (`CarPositionController` + controllers dédiés), déclenché par le citoyen puis complété côté personnel :
1. **Signalement** (`faireSignalement`) — citoyen : géolocalisation, titre, commune, photo → crée `CarPosition` + `CarPhoto`.
2. **Véhicule** (`VehiculeController`) — détails techniques du véhicule (marque, modèle, immatriculation, état d'entretien).
3. **Infraction** (`InfractionController`) — adresse précise, motif, conditions (nuit/pluie), lieu public/privé.
4. **Approbation** (`ApprobationController`) — décision oui/non sur la saisie.
5. **Enlèvement** (`EnlevementController`) — date, lieu, responsable de l'enlèvement effectif.
6. **Dommages** (`DommagesController`) — capture de signature/constat de dommages.
7. Consultation : `voirSignalements` (les siens), `listerSignalements` (les 10 derniers jours, tous), `listerSignalement/{id}`, `statistiques` (compteurs par état).

Ces mêmes étapes (véhicule/infraction/approbation/enlèvement/dommages) existent **aussi** côté back-office web — les deux applications exposent le même workflow métier, avec deux implémentations séparées.

## 1.3 Back-office web — `sendraApp` (app.sendra.sn)

**Stack** : Laravel 10.47, Jetstream 4.3.1, Sanctum (session), Fortify, Livewire 3.4.8 (installé mais non utilisé — toutes les pages sont du Blade classique avec formulaires POST/PATCH), barryvdh/laravel-dompdf 2.1.0.

**Tableau de bord** (`/dashboard`) : compteurs (signalements / non résolus / en cours / enlèvements) + 5 derniers signalements.

**Gestion des comptes** (`UserController`, `/dashboard/comptes/*`) : listes séparées par rôle (Admin/Agent/Autorité commune/"Utilisateurs"=Autorité préfecture), création de compte (mot de passe par défaut envoyé par e-mail), modification, changement de mot de passe forcé à la première connexion.

**Traitement d'un signalement** (`/dashboard/signalement/{id}`) : page à onglets — Informations, Véhicule, Infraction, Dommages (signature), Approbation, Enlèvement (visible seulement après approbation). Chaque onglet correspond à une action `PATCH` dédiée.

**Cartographie** (`/dashboard/cartographie`) : carte de tous les signalements ; vue individuelle (`/dashboard/locatlisation/{id}`).

**Génération PDF** (dompdf) : fiche signalement et fiche de constatation, par véhicule.

**Entités scaffoldées mais jamais implémentées côté UI, dans aucune des deux apps** : `Commune`, `Secteur`, `TProcedure`, `Constatation`, `MobileAppInformation`, `Verification`, `VerificationCode`, `Agent` — les controllers existent (générés via `make:controller --resource`) mais toutes les méthodes sont vides ; les `FormRequest` associées ont de vraies règles de validation mais ne sont jamais appelées. Ce sont des tables réelles en base sans aucun code applicatif qui les gère (à l'exception de `VerificationCode`/`Agent`/`CarPhoto`, partiellement touchées ailleurs). **Décision à prendre pour la refonte : ces entités sont-elles encore nécessaires au produit ?**

## 1.4 Infrastructure annexe

- **Adminer** (private.sendra.sn) : interface web d'administration MySQL générique, permet de se connecter à n'importe quelle base avec des identifiants saisis dans le formulaire.
- **Odoo** (erp.sendra.sn) : ERP tiers, aucune intégration de code constatée avec le reste de la plateforme.

---

# Partie 2 — Problèmes identifiés

Organisés par sévérité, puis par système. Chaque finding cite un fichier et si possible une ligne précise.

## 2.1 Critiques

Fuite de secret actif, contournement total du contrôle d'accès, ou compte privilégié créable par n'importe qui — à traiter avant toute autre chose, indépendamment du calendrier de la refonte.

### [Infra] INFRA-C-1 — Adminer exposé publiquement, sans restriction
`private.sendra.sn` sert Adminer (`/var/www/adminer/index.php`) avec `Require all granted` et `Options Indexes` (listing de répertoire activé), sans authentification applicative ni restriction d'IP. N'importe qui connaissant l'URL peut tenter une connexion à n'importe quelle base MySQL du serveur.
**Correction :** restreindre par IP/VPN ou supprimer si non indispensable.

### [API] API-C-1 — Route publique qui expose les identifiants Orange SMS
`routes/web.php:21-28` — `GET /test-env`, sans authentification, renvoie `ORANGE_SMS_LOGIN`, `ORANGE_SMS_TOKEN`, `ORANGE_SMS_API_KEY`, `ORANGE_SMS_BASE_URI` en clair.
**Correction :** supprimer la route, régénérer les identifiants Orange SMS.

### [API] API-C-2 — N'importe quel utilisateur connecté peut supprimer le compte de n'importe qui
`AuthControllerApi.php:293-308` — `POST /delete-user` supprime le compte correspondant au `telephone` transmis, sans vérifier que c'est celui de l'appelant.
**Correction :** utiliser `Auth::user()` comme source du compte à supprimer.

### [API] API-C-3 — Aucun contrôle de rôle sur les actions métier (API)
`ApprobationController`, `EnlevementController`, `DommagesController`, `InfractionController::update`, `VehiculeController::update`, `CarPositionController::destroy` — aucun ne vérifie `Auth::user()->role_id`. Un citoyen auto-inscrit (`role_id=5`) peut approuver une saisie, modifier un véhicule, supprimer le signalement d'un autre utilisateur.
**Correction :** middleware/policy de rôle sur les routes métier.

### [API] API-C-4 — `/me` renvoie le hash du mot de passe et les secrets 2FA
`AuthControllerApi.php:247-250`, modèle `User` sans `$hidden`.
**Correction :** `protected $hidden = ['password', 'remember_token', 'two_factor_secret', 'two_factor_recovery_codes'];`

### [API] API-C-5 — Clé « secrète » codée en dur dans le code source
`AuthControllerApi.php:71, 112` — `'Sendra@2025!'` protège `checkPhone`/`sendVerificationCode`, mais forcément embarquée dans l'app mobile donc extractible (énumération de numéros, spam SMS).
**Correction :** retirer, s'appuyer sur du rate-limiting.

### [Web] WEB-C-1 — Élévation de privilèges : n'importe quel compte actif peut créer/promouvoir un compte Admin
`UserController.php:982-995` (`store()`) et `:1003-1013` (`modifier()`) : `$user->role_id = $request->role;` directement depuis la requête. Les routes ne sont protégées que par `auth:sanctum, isActived, verified` — **aucune vérification de rôle nulle part dans le code** (confirmé : `AuthServiceProvider::$policies` vide, aucun middleware de rôle n'existe). Le menu "Comptes" est juste masqué dans le Blade pour les non-Admins — protection cosmétique, contournable en tapant l'URL directement.
**Correction :** ajouter une vraie couche d'autorisation (Policy/Gate) vérifiée côté contrôleur, pas seulement côté vue.

### [Web] WEB-C-2 — Formulaire d'inscription public actif sur le back-office
`config/fortify.php` a `Features::registration()` activé, jamais désactivé pour ce panneau interne. `GET|POST /register` est donc joignable publiquement. Le formulaire est actuellement cassé (la table `users` n'a pas de colonne `name` que Fortify essaie d'insérer) mais reste une surface d'attaque publique sur un outil qui ne devrait jamais permettre l'auto-inscription.
**Correction :** désactiver `Features::registration()`, retirer les routes `register`.

## 2.2 Élevés

### [API] API-H-1 — Erreur 500 sur tout signalement sans photo
`SignalementRessource.php:25-26` — `$this->photo[0]->filepath` sur une relation `hasMany` toujours "truthy" même vide.
### [API] API-H-2 — Schéma réel désynchronisé des migrations (`user_verification_codes`)
La migration versionnée ne crée que `id`+timestamps ; les colonnes `phone`/`code`/`expires_at` existent en base sans migration correspondante. Un `migrate:fresh` casserait l'inscription.
### [API] API-H-3 — Upload d'image sans validation de contenu ni transaction
`CarPositionController.php:19-50` — base64 accepté sans vérification de contenu réel, pas de transaction DB entre `CarPosition` et `CarPhoto`.
### [API] API-H-4 — `InfractionController::update` peut violer une contrainte NOT NULL en base
Validation `lieu` = `nullable`, colonne DB `NOT NULL` → crash SQL possible sur requête pourtant valide selon le FormRequest.
### [API] API-H-5 — Comparaison stricte du code OTP potentiellement toujours fausse
`AuthControllerApi.php:185` — `!==` entre chaîne DB et valeur potentiellement numérique côté client mobile.
### [API] API-H-6 — L'inscription n'est pas réellement liée à la vérification du code
`register()` vérifie l'existence d'un code non expiré, pas que `verifyCode()` a réussi — un compte peut être créé sans jamais soumettre le bon code.
### [Web] WEB-H-1 — `email_verified`/`verified` middleware est un no-op
`User` n'implémente pas `MustVerifyEmail` → le middleware `verified` appliqué sur toutes les routes protégées ne vérifie en réalité rien pour personne.
### [Web] WEB-H-2 — Routes cassées vers des méthodes de contrôleur inexistantes
`routes/web.php:74-76` pointent vers `save_agents`/`save_admin`/`save_autorites`, absentes de `UserController` → `BadMethodCallException` (500) au moindre appel.
### [Web] WEB-H-3 — Domaines d'images incohérents et codés en dur, à trois endroits différents
6 vues Blade pointent vers `https://backend.sendra.sn/storage/`, tandis que `SignalementRessource.php` (utilisé par la carte) pointe vers un domaine personnel tiers `https://sendra.mouhamadoufaye.tech/storage/` — ni l'un ni l'autre n'est le domaine de cette app (`app.sendra.sn`).
### [Web] WEB-H-4 — Checkbox "pluie" cassée : la donnée ne peut plus jamais être enregistrée
`show.blade.php:153-158` envoie `value="1"` au lieu de `value="pluie"` attendu par le contrôleur (`in_array('pluie', ...)` toujours faux) — bug de saisie silencieux sur un document à valeur légale/administrative.
### [Web] WEB-H-5 — Mot de passe par défaut identique pour tous les nouveaux comptes staff
`UserController.php:990` — `Hash::make('sendra2024@')` en dur, envoyé en clair par e-mail, sans garantie de changement forcé (le compte n'est pas explicitement désactivé à la création).
### [Infra] INFRA-H-1 — Adminer non mis à jour depuis ~5 ans
Fichier daté mai 2021 (≈ v4.8.1) — aucun correctif depuis, en plus d'être exposé publiquement (INFRA-C-1).

## 2.3 Moyens

- **API-M-1** — `ApprobationController` : aucun état "rejeté" distinct, `etat` forcé à `"EN COURS"` même en cas de refus.
- **API-M-2** — `EnlevementController` : l'enlèvement peut être enregistré sans approbation préalable (`is_approve` jamais vérifié).
- **API-M-3** — `statistiques()` charge des collections entières en mémoire juste pour les compter (`count(...->get())` au lieu de `->count()`), pas de pagination sur `InfractionController::index()`/`VehiculeController::index()`.
- **API-M-4** — URL de production codée en dur (`DommagesController.php:56`).
- **API-M-5** — `LOG_LEVEL=debug` en production, logging verbeux des réponses API Orange (identifiants potentiellement journalisés).
- **API-M-6** — Middleware JWT mort (`JwtMiddleware.php`, no-op non branché) + double vérification d'auth redondante dans `AuthControllerApi`.
- **API-M-7** — Formats de réponse d'erreur incohérents (`login()` renvoie un format différent du reste de l'API).
- **Web WEB-M-1** — Écran "Utilisateurs" mal étiqueté : affiche en réalité les comptes "Autorité préfecture" (`role_id=4`), pas les citoyens.
- **Web WEB-M-2** — Mass-assignment latent sur `CarPosition` (`$guarded = []`), non exploité aujourd'hui mais dangereux si un futur `create()`/`fill()` est ajouté.
- **Web WEB-M-3** — `APP_URL=http://localhost` en production (app réellement servie sur `app.sendra.sn`) + `TrustProxies` non configuré + cookie de session pas explicitement `Secure` — cluster de config à corriger ensemble.
- **Web WEB-M-4** — Upload de signature (`signaturestore()`) sans validation de contenu ni limite de taille, combiné à l'absence de contrôle de rôle (WEB-C-1) = n'importe quel compte peut remplir le stockage sur n'importe quel signalement.
- **Web WEB-M-5** — `UserController::test()` : route `/test` de développement laissée active, envoie les données de l'utilisateur connecté (y compris le hash du mot de passe) par e-mail à une adresse personnelle codée en dur.

## 2.4 Faibles / dette technique

| # | Système | Constat |
|---|---|---|
| API-L-1 | API | 9 copies datées de l'app entière dans `/var/www/` — aucune source de vérité claire (déploiement sans CI/CD basé sur git). |
| API-L-2 | API | `VehiculeController_bk.php` — fichier de backup avec le même nom de classe que le fichier actif. |
| API-L-3 | API | 20 des 24 `FormRequest` jamais branchées (`authorize() => false`, règles vides) — CRUD admin jamais terminé. |
| API-L-4 | API | Blocs de code entièrement commentés dans plusieurs controllers au lieu d'être supprimés (l'historique git suffit). |
| API-L-5 | API | Modèles `Agent`/`Secteur` sans table correspondante en base. |
| API-L-6 | API | Deux mécanismes OTP concurrents en base (`verification_codes`, `verifications`) dont un seul (`user_verification_codes`) est réellement utilisé. |
| API-L-7 | API | `laravel/sanctum` en dépendance et configuré comme guard, mais jamais utilisé (guard réel = `api`/JWT). |
| WEB-L-1 | Web | `AuthMail` envoie un attribut `nom` qui n'existe pas sur `User` → e-mail de bienvenue affichant "Bienvenue,  !". |
| WEB-L-2 | Web | `IsActiveMiddleware` : code mort après un `if/else` qui retourne déjà, pas de garde défensive sur `Auth::user()` null. |
| WEB-L-3 | Web | Fichiers Blade de sauvegarde laissés dans le dépôt (`show.blade copy.php`, `show.blade.save.php`). |
| WEB-L-4 | Web | Page de capture de signature autonome (`/signature`) orpheline, dupliquée par rapport à l'onglet intégré réellement utilisé ; JS associé contient ~70 lignes de code mort commenté. |
| WEB-L-5 | Web | Laravel 10 : fin de support déjà dépassée à la date de cet audit — à ne pas reconduire dans une refonte. |
| WEB-L-6 | Web | `AuthControllerApi.php` présent dans le back-office (attend un guard JWT jamais configuré ici) — copie-collé mort du code de l'API mobile. |

---

# Partie 3 — Constat transversal pour la refonte

**Le problème n°1 n'est pas un bug isolé, c'est l'absence structurelle de contrôle d'accès par rôle.** Sur les deux applications, la vérification d'identité (JWT côté API, session Sanctum côté back-office) fonctionne — mais *aucune des deux* ne vérifie ensuite ce que le rôle de l'utilisateur l'autorise à faire. Toute la "sécurité" par rôle actuellement observable est cosmétique (menus masqués côté Blade dans `sendraApp`) et se contourne en appelant directement l'URL/la route. C'est la cause commune de la majorité des findings critiques (API-C-3, WEB-C-1) et mérite d'être le premier principe d'architecture posé dans la refonte : **une policy/gate centralisée, vérifiée côté serveur sur chaque route, jamais seulement côté vue.**

**Le problème n°2 est la duplication non synchronisée entre les deux codebases.** Douze modèles Eloquent existent en double, pointant vers les mêmes tables, sans garantie de cohérence. Une refonte doit trancher explicitement : une seule application (monolithe) qui sert à la fois l'API mobile et le back-office ? Ou deux applications qui consomment une même couche de données/API interne partagée ? Le statu quo (deux copies indépendantes maintenues à la main) est la source de plusieurs incohérences déjà constatées (URLs d'images différentes selon l'app, `$guarded` différent sur `CarPosition`).

**Le problème n°3 est le scaffolding jamais terminé.** Huit entités (`Commune`, `Secteur`, `TProcedure`, `Constatation`, `MobileAppInformation`, `Verification`, `VerificationCode`, `Agent`) existent en base et dans le code (modèles + `FormRequest` avec règles réelles) sans aucune interface pour les gérer, dans aucune des deux apps. Avant la refonte, il faut trancher produit par produit : fonctionnalité encore souhaitée (à construire pour de vrai) ou dette à supprimer proprement (tables + modèles + requests) ?

**Ce qui fonctionne et doit être préservé fonctionnellement :** le workflow métier signalement → véhicule → infraction → approbation → enlèvement/dommages est cohérent et complet de bout en bout (citoyen signale via mobile, personnel traite via back-office), la génération PDF et la cartographie sont opérationnelles, le modèle de rôles à 5 niveaux correspond à un besoin métier réel et documenté par les données (comptes déjà répartis sur les 5 rôles en production).

---

# Partie 4 — Priorisation recommandée

**Avant tout (indépendant du calendrier de refonte, à faire cette semaine) :**
1. Supprimer `/test-env` et régénérer les identifiants Orange SMS (API-C-1).
2. Restreindre l'accès à Adminer (INFRA-C-1).
3. Corriger `delete-user` pour n'agir que sur son propre compte (API-C-2).
4. Ajouter `$hidden` au modèle `User` API (API-C-4) — une ligne, impact immédiat.
5. Désactiver l'auto-inscription sur le back-office (WEB-C-2).

**Court terme (avant d'ouvrir plus largement l'accès aux deux apps) :**
6. Contrôle de rôle serveur sur les routes métier des deux apps (API-C-3, WEB-C-1) — le chantier le plus structurant.
7. Retirer la clé statique SMS (API-C-5), corriger le mot de passe par défaut partagé (WEB-H-5).

**Dans le cadre de la refonte :**
8. Décider de l'architecture cible (monolithe vs. apps séparées + contrat d'API interne).
9. Trancher le sort des 8 entités scaffoldées jamais implémentées.
10. Migrer vers une version de Laravel supportée, nettoyer les ~9 copies de dépôt et mettre en place un déploiement basé sur git (fin de la copie manuelle de dossiers).

---

*Document basé sur une lecture directe du code servi en production (`backendSendra` et `sendraApp`), une inspection de la base `sendra`, et la lecture des vhosts Apache pour confirmer ce qui est réellement exposé. Aucune correction n'a été appliquée — ce rapport est un état des lieux destiné à préparer la refonte.*
