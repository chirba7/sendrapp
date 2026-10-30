# Audit performance & sécurité EPAVIE — mode d'emploi (29/10/2026)

## Étape 1 — Diagnostic serveur (lecture seule, ~1 min)

PowerShell, depuis `C:\Projets\sendrapp\sendra\audit-perf` :

```powershell
scp .\diagnostic-serveur.sh root@<serveur>:/root/
ssh root@<serveur> "bash /root/diagnostic-serveur.sh > /dev/null; ls -t /root/diag-epavie-*.txt | head -1"
scp root@<serveur>:/root/diag-epavie-<date>.txt .
```

Si MySQL demande un mot de passe : `MYSQL_OPTS="-u root -p" bash /root/diagnostic-serveur.sh`.
Le script n'affiche aucun secret et ne modifie rien.

## Étape 2 — Comptes de test sur la PRÉPROD

```powershell
ssh root@<serveur> "mkdir -p /root/k6"
scp .\k6\comptes-test.php root@<serveur>:/root/k6/
ssh root@<serveur>
cd <dossier backend préprod>
sudo -u apache php artisan tinker --execute="require '/root/k6/comptes-test.php';"
exit
scp root@<serveur>:/tmp/k6-jetons.json .\k6\
```

200 citoyens (700000001…200) + 10 agents (700000901…910), mot de passe `K6-Epavie-2026`.
Le script refuse de tourner sur un `.env` de production.

## Étape 3 — k6 depuis Windows

```powershell
winget install k6 --source winget
cd C:\Projets\sendrapp\sendra\audit-perf\k6
k6 run -e SCENARIO=smoke  --summary-export=..\k6-smoke.json  charge-epavie.js
k6 run -e SCENARIO=charge --summary-export=..\k6-charge.json charge-epavie.js
k6 run -e SCENARIO=stress --summary-export=..\k6-stress.json charge-epavie.js
k6 run -e SCENARIO=pic    --summary-export=..\k6-pic.json    charge-epavie.js
k6 run -e SCENARIO=login  --summary-export=..\k6-login.json  charge-epavie.js
```

Ordre : **smoke d'abord** (si ça échoue, on corrige avant d'aller plus loin).
Pendant `stress`, arrêter (Ctrl+C) dès que les erreurs dépassent ~10 %.

**Pendant chaque test**, dans un second terminal SSH, enregistrer ce que fait le serveur :

```bash
vmstat 5 | tee /root/k6-vmstat-$(date +%H%M).txt
# et dans un 3e terminal :
watch -n5 "ps -C php-fpm,httpd -o rss= | awk '{s+=\$1;n++} END {print n\" process PHP, \"s/1024\" Mo\"}'; mysqladmin status"
```

### Précautions
- **Jamais sur `backend.sendra.sn`** (le script refuse). Si la préprod est sur la même machine
  que la prod, lancer `stress`/`pic`/`endurance` **le soir ou la nuit**.
- Le scénario crée de vrais signalements de test (description `k6-test`) ; `-e ECRITURE=0`
  pour un test en lecture seule.
- `login` va produire des **429** au-delà de 1 connexion/s : c'est voulu, c'est le limiteur
  par IP (point important — voir rapport).
- Si la connexion du poste sature (regarder `data_received` dans le résumé k6), le plafond
  mesuré est celui de la box, pas du serveur.

## Étape 4 — Nettoyage

```bash
sudo -u apache php artisan tinker --execute="\$nettoyer=true; require '/root/k6/comptes-test.php';"
rm /tmp/k6-jetons.json
```

Déposer les fichiers `diag-epavie-*.txt`, `k6-*.json` et `k6-vmstat-*.txt` dans ce dossier :
Claude les lit directement et chiffre la capacité.
