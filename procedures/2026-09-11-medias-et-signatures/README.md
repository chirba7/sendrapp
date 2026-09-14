# Procédure du 11/09/2026 — médias perdus et signatures du back-office

Deux interventions indépendantes sur le serveur, préparées avec la refonte
(`sendra-refonte/docs/inventaire-medias.md`, `inventaire-sendraapp.md` §5.3). À exécuter
**en SSH direct** (un agent IA risque de bloquer ces commandes sur une fausse alerte).

| | Quoi | Où | Risque |
|---|---|---|---|
| **A** | Remettre les 45 médias perdus début 2025 | prod + préprod, dès maintenant | Très faible : ajout de fichiers absents, rien n'est écrasé |
| **B** | Écrire les signatures du back-office dans le stockage du backend | **préprod d'abord** ; prod seulement avec le correctif de lecture | Faible : 3 fichiers de code + 1 variable, retour arrière prévu |

---

## A. Remettre les 45 médias

Script : `restaurer-medias-2024.sh` (manifeste SHA-256 intégré). Il ne supprime ni n'écrase
rien, vérifie chaque fichier par son empreinte, reprend le propriétaire et les droits des
fichiers voisins, et journalise dans `/root/` la liste des fichiers créés.

```bash
# 1. Déposer le script sur le serveur (depuis PowerShell sur le PC) :
#    scp C:\Projets\sendrapp\sendra\procedures\2026-09-11-medias-et-signatures\restaurer-medias-2024.sh root@<serveur>:/root/

# 2. Production — simulation, puis application :
bash /root/restaurer-medias-2024.sh
APPLIQUER=1 bash /root/restaurer-medias-2024.sh

# 3. Préproduction — même script, autre cible. Trouver le chemin du backend de préprod :
grep -hE "ServerName|DocumentRoot" /etc/httpd/conf.d/*.conf | grep -iA1 backpreprod
CIBLE=<racine du backend de préprod>/storage/app/public bash /root/restaurer-medias-2024.sh
CIBLE=<racine du backend de préprod>/storage/app/public APPLIQUER=1 bash /root/restaurer-medias-2024.sh
```

Attendu : `45 à copier` en simulation, puis `45 copiés, 0 erreurs`. Relancé, le script répond
`45 déjà présents` — il est rejouable sans effet.

Contrôle : ouvrir dans le back-office un signalement de fin novembre 2024 — sa photo doit
réapparaître. URL directe :
`https://backend.sendra.sn/storage/signalement/photo/car_photo674c69acbea77.png`.

Retour arrière : `xargs -d '\n' rm -f < /root/restauration-medias-2024-<date>.txt`
(ne supprime que ce que le script a créé).

---

## B. Signatures du back-office

**Le problème.** `signaturestore()` écrivait la signature sur le disque de `sendraApp`, alors
que la fiche du back-office et l'application mobile la lisent dans le stockage du backend. En
préprod (correctif de lecture déjà déployé), une signature faite au back-office n'est visible
nulle part. En prod, 4 signatures n'existent que sur le disque de `sendraApp`.

**Le correctif** (dépôt `sendra`, `sendraApp/`, non committé) :

| Fichier | Changement |
|---|---|
| `config/filesystems.php` | nouveau disque `backend`, racine `BACKEND_STORAGE_PATH` |
| `app/Http/Controllers/CarPositionController.php` | `signaturestore()` écrit sur le disque `backend` ; si l'écriture échoue, message d'erreur et **aucune** référence en base |
| `resources/views/carPosition/pdf.blade.php` | la signature est lue sur le disque `backend` et intégrée en data URI (DomPDF refuse de lire hors de `base_path()`) ; type lu dans le contenu |
| `.env.example` | documente `BACKEND_STORAGE_PATH` |
| `tests/Feature/SignalementWorkflowTest.php` | 3 tests : écriture côté backend, pas de référence si l'écriture échoue, PDF |

Suite `sendraApp` : 30 tests verts (8 ignorés, fonctions Jetstream désactivées).

### B.0 — Contrôles préalables (lecture seule)

```bash
APP=/var/www/sendraApp                      # préprod : racine du back-office de préprod
BACK=/var/www/backendSendra/storage/app/public   # préprod : stockage du backend de préprod

stat -c '%U:%G %a %C' $BACK/dommages        # propriétaire et contexte SELinux
ps -eo user,comm | grep -E 'httpd|php-fpm' | sort | uniq -c   # sous quel utilisateur tourne PHP
grep -rn open_basedir /etc/httpd /etc/php.ini /etc/php.d /etc/php-fpm.d 2>/dev/null
sudo -u apache test -w $BACK/dommages && echo "apache peut écrire" || echo "apache NE PEUT PAS écrire"
ls $APP/bootstrap/cache/config.php 2>/dev/null && echo "config en cache : penser à config:cache"
```

Si `open_basedir` limite `sendraApp` à son dossier, ou si l'utilisateur PHP ne peut pas écrire
dans `$BACK/dommages`, **s'arrêter** : le correctif renverrait une erreur à chaque signature (il
n'enregistre plus rien en silence).

### B.1 — Sauvegarde

```bash
SAUV=/root/backups/web_signatures_$(date +%Y%m%d_%H%M%S); mkdir -p $SAUV
cd $APP && cp --parents config/filesystems.php app/Http/Controllers/CarPositionController.php \
  resources/views/carPosition/pdf.blade.php .env $SAUV/
```

### B.2 — Déploiement

Déposer les 3 fichiers applicatifs (depuis le PC, comme d'habitude), puis :

```bash
cd $APP
grep -q '^BACKEND_STORAGE_PATH=' .env || echo "BACKEND_STORAGE_PATH=$BACK" >> .env
php -l app/Http/Controllers/CarPositionController.php
sudo -u apache php artisan config:clear        # ou config:cache si la config était en cache
sudo -u apache php artisan view:clear
sudo -u apache php artisan tinker --execute="echo config('filesystems.disks.backend.root');"
```

La dernière ligne doit afficher le chemin `$BACK`. Toujours lancer `artisan` **en tant
qu'apache** : lancé en root, il crée des fichiers de cache ou de log que l'application ne peut
plus écrire.

### B.3 — Rapatrier les signatures déjà faites au back-office

```bash
ls $APP/storage/app/public/dommages | wc -l
for f in $APP/storage/app/public/dommages/*.png; do
  [ -e "$BACK/dommages/${f##*/}" ] || sudo -u apache cp -p "$f" "$BACK/dommages/"
done
```

`cp` sans écrasement, originaux conservés.

### B.4 — Validation

1. Fiche d'un signalement dont la signature a été faite au back-office : l'image s'affiche.
2. Nouvelle signature sur un signalement de test : visible sur la fiche, dans le PDF et dans
   l'application mobile (`voirDommages`).
3. `ls -t $BACK/dommages | head -1` : le fichier le plus récent est la nouvelle signature.

### B.5 — Retour arrière

```bash
cp -r $SAUV/. $APP/
cd $APP && sudo -u apache php artisan config:clear && sudo -u apache php artisan view:clear
```

Les signatures recopiées en B.3 peuvent rester : ce sont des fichiers ajoutés.

### Règle pour la production

La prod n'a pas encore le correctif de **lecture** (`BACKEND_STORAGE_URL` dans les vues). Les
deux vont ensemble : **ne jamais déployer la lecture sans l'écriture**, sinon les 4 signatures
existantes du back-office deviennent invisibles. Déployer B en prod dans la même livraison que
le correctif de lecture, avec B.3 juste après.
