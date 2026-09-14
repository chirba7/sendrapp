#!/usr/bin/env bash
# Remet en place les 45 médias perdus début 2025 (photos de signalements et
# signatures de dommages), à partir des copies datées du backend dans /var/www.
#
#   bash restaurer-medias-2024.sh                              # SIMULATION : n'écrit rien
#   APPLIQUER=1 bash restaurer-medias-2024.sh                  # écrit
#   CIBLE=/chemin/storage/app/public bash restaurer-medias-2024.sh   # autre stockage (préprod)
#
# Garanties :
#  - ne supprime et n'écrase jamais rien : un fichier déjà présent est laissé tel quel ;
#  - chaque fichier copié est vérifié par son empreinte SHA-256 (manifeste ci-dessous,
#    établi le 11/09/2026 — voir sendra-refonte/docs/inventaire-medias.md) ;
#  - propriétaire, groupe et droits sont repris du dossier de destination ;
#  - la liste des fichiers créés est écrite dans /root/ : c'est aussi le retour arrière
#    (xargs -d '\n' rm -f < ce_fichier).
set -uo pipefail

CIBLE=${CIBLE:-/var/www/backendSendra/storage/app/public}
SOURCES=${SOURCES:-/var/www}
APPLIQUER=${APPLIQUER:-0}
JOURNAL=${JOURNAL:-/root/restauration-medias-2024-$(date +%Y%m%d-%H%M%S).txt}

[ -d "$CIBLE" ] || { echo "ARRET : stockage cible introuvable : $CIBLE" >&2; exit 1; }
[ "$APPLIQUER" = "1" ] && MODE="APPLICATION" || MODE="SIMULATION (rien n'est écrit)"
if [ "$APPLIQUER" = "1" ]; then
  # Le journal est le retour arrière : pas de journal, pas d'écriture.
  : >> "$JOURNAL" || { echo "ARRET : journal impossible à écrire : $JOURNAL" >&2; exit 1; }
fi
echo "== Restauration des médias 2024 — $MODE"
echo "   cible : $CIBLE"

SELINUX=0; command -v selinuxenabled >/dev/null 2>&1 && selinuxenabled && SELINUX=1
crees=0; presents=0; differents=0; erreurs=0

while read -r empreinte chemin copie; do
  [ -n "$empreinte" ] || continue
  source="$SOURCES/$copie/storage/app/public/$chemin"
  dest="$CIBLE/$chemin"

  if [ -e "$dest" ]; then
    if [ "$(sha256sum "$dest" | cut -d' ' -f1)" = "$empreinte" ]; then
      presents=$((presents+1)); echo "   déjà présent     $chemin"
    else
      differents=$((differents+1)); echo "   PRÉSENT, AUTRE CONTENU (laissé tel quel)  $chemin"
    fi
    continue
  fi

  if [ ! -f "$source" ] || [ "$(sha256sum "$source" | cut -d' ' -f1)" != "$empreinte" ]; then
    erreurs=$((erreurs+1)); echo "   ERREUR source absente ou empreinte différente : $source"
    continue
  fi

  dossier=$(dirname "$dest")
  if [ "$APPLIQUER" = "1" ]; then
    [ -d "$dossier" ] || { echo "   ERREUR dossier absent : $dossier"; erreurs=$((erreurs+1)); continue; }
    # Droits et propriétaire d'un fichier voisin (ce que l'application a écrit
    # elle-même) ; à défaut, ceux du dossier et 644.
    voisin=$(find "$dossier" -maxdepth 1 -type f -print -quit)
    ref=${voisin:-$dossier}
    mode=$([ -n "$voisin" ] && stat -c %a "$voisin" || echo 644)
    install -m "$mode" -o "$(stat -c %U "$ref")" -g "$(stat -c %G "$ref")" "$source" "$dest" \
      && [ "$(sha256sum "$dest" | cut -d' ' -f1)" = "$empreinte" ] \
      && { echo "$dest" >> "$JOURNAL"; crees=$((crees+1)); echo "   copié            $chemin  ← $copie"; } \
      || { erreurs=$((erreurs+1)); echo "   ERREUR copie : $chemin"; }
    [ "$SELINUX" = "1" ] && restorecon "$dest" 2>/dev/null
  else
    crees=$((crees+1)); echo "   serait copié     $chemin  ← $copie"
  fi
done <<'MANIFESTE'
620268e8046cf1e9cdc364ad5449f8a47ead4b0c3c3d83313af139f755ebbc10  signalement/photo/car_photo66daf8306a600.png  backendSendra_17012025
61469ac1e1263ff60241ce42cf5905677555a8b707b0a72681d4bfb9b3bce378  signalement/photo/car_photo66ddd5012d536.png  backendSendra_17012025
a7de9b15e61c567de67964f0911293c9dedd0821d96c708e406cabe7e39c3e6d  signalement/photo/car_photo66eb1c5d75617.png  backendSendra_17012025
9ea4897205eed2db382c5eb015b5893bc879833b3948b47595ce7a62ad9fc1a1  signalement/photo/car_photo6707d177c9586.png  backendSendra_17012025
cc62141de3e5166f6f3cd624feae99953d74e45ffc5b33b61c472f29b98d797e  signalement/photo/car_photo67182071335ad.png  backendSendra_17012025
ee8cee4beaee6209ef6700c355e5ca6a3c7061a4951f396c82c818cfe7d74369  signalement/photo/car_photo671821577351d.png  backendSendra_17012025
490440ddf86725a12d33be8869273e32126a2b3927b527eb89478f27f5a5ef7f  signalement/photo/car_photo671821abe6910.png  backendSendra_17012025
b4f18682691fd08e3408baf95b41fca18b2b82372260e8f4efdb99fb525aca0a  signalement/photo/car_photo67183d3971746.png  backendSendra_17012025
ae7b7e00e27ee7cd463c99d4ce9f6348785ceef3b9221239762113369726036e  signalement/photo/car_photo67183d5acdcff.png  backendSendra_17012025
f8f87b1fd7ffa62f8fce089228c7390e35f5d42409bd1d208d08e9aad454b708  signalement/photo/car_photo6732207197723.png  backendSendra_17012025
e609bd8caae670f9dbaa7accc365cc32fb73fbc2be36a10ea632114cc1fd88de  signalement/photo/car_photo673267849d75d.png  backendSendra_17012025
d9cd3c7478279193c8166c03b4f62d124a5f59a97d2e629e0d7e6e69104e93e1  signalement/photo/car_photo67422c7679710.png  backendSendra_25112024
baf23685895405de4947fa931b0f26ef40b8acafbe941c7f2e36e9f974bada50  signalement/photo/car_photo6745e15d362a3.png  backendSendra_17012025
7c3ea061fa278aaea05702c9641c7a1cf53ff41d62b3c8a5d132616db25cb2c9  signalement/photo/car_photo67474cd8b9f5f.png  backendsendra_Aboubacry
c45e228d1fd714f85fc9ad3b4dbb2f5941d1f8576e40a67457e9fc796710faba  signalement/photo/car_photo6747a1956949f.png  backendsendra_Aboubacry
4bcff16dd98ddeb3f919599c052937a273a5ca6465e7f7d53567e90606224826  signalement/photo/car_photo6748dd3c80fd5.png  backendSendra_17012025
d70e84337e02390f805ae4bce0f14cd76ea94385a0324b1e2f58fba0304bc2cf  signalement/photo/car_photo6748e4c796821.png  backendSendra_17012025
5e40b54507f0439c9b5ef5f644808607790f98ac35d1f2e64aa56f958be7a9a6  signalement/photo/car_photo674c69acbea77.png  backendSendra_17012025
b4715a0775f5c5d063f3e6d961d98572c0b00f7cfb632bc4fa44a491038030b2  signalement/photo/car_photo674c6a470c037.png  backendSendra_17012025
8dbddbf4d39bd4d9ce622bed4bae07a8f9ccb3e9475c26cf22b23b9f48a54193  signalement/photo/car_photo674c6ca4441fe.png  backendSendra_17012025
3fe115f3696d7c5daa721ce31a47bb539d8b0c13e5bf49311cd690d99e4647c3  signalement/photo/car_photo674c6e199d4df.png  backendSendra_17012025
333ea995bc6adf58d65db0775d8d2825921a267af7ecd250a4082539fa1d1435  signalement/photo/car_photo674c6f5678042.png  backendSendra_17012025
7f723f7a9ba8b7138da1a8e1e76be1adefc5441da210d93d4a7ab449c981a46f  signalement/photo/car_photo674c72700765d.png  backendSendra_17012025
981719a6571dc2255bebd92d15ca929853ca9f31ad21be715a2155cad8c69714  signalement/photo/car_photo674c739f096e0.png  backendSendra_17012025
e8f4204e8cafa6703c7240292473c13f71612f20fcb1ae310397c32ed3511fe1  signalement/photo/car_photo674c765bb7f3e.png  backendSendra_17012025
a28acd9f0736692cecea62b8cf440e0870df9c9fe5d22bbb896ae2f302e494c9  signalement/photo/car_photo674c7784b7094.png  backendSendra_17012025
ef8732046bc099cfc49b800bf7da4615998c8d4e8365b25738b7ae5f87ab2995  signalement/photo/car_photo674c77e0f28e9.png  backendSendra_17012025
e3a1b94d9f5c47b7bb39d7a7ee543d6265079e099a4d0991c761c9ebd1d6c3ad  signalement/photo/car_photo674c7837677b3.png  backendSendra_17012025
5d6a438ae9fb9256767a0b1b8135909009cae25feafa7f048275553b5f950f52  signalement/photo/car_photo674c787a4c715.png  backendSendra_17012025
51d8a088dd02c3abf3c1a52642bb50bfbb5971cbd84ff8a00da46ddf6028483b  signalement/photo/car_photo674c790b0a21c.png  backendSendra_17012025
bc9e9714d0b5272e790349cf26aecf7bff355cd8a342795e162097d461457bbc  signalement/photo/car_photo674c79f89b8b4.png  backendSendra_17012025
994f2eaef722f5559e7d25beeacef6a70e551f837e475d2dfbaa43d7864b752d  signalement/photo/car_photo6750375a7346f.png  backendSendra_17012025
42d393cf283222f1f4210436455381a192a76ba7307c1f9f84a989a9006848d0  signalement/photo/car_photo67509b87b7ad8.png  backendSendra_17012025
58c766d975bc54a4764ccab6c908aab8043b30df44b68fa9588108fabe79b5bf  signalement/photo/car_photo6755c1dfd4194.png  backendSendra_17012025
9aa721c8d83ca6c663c17c0e3138de36903c9f96d9787d44714371dd8a248b5f  signalement/photo/car_photo67646d94230c0.png  backendSendra_17012025
99d18c63670ddb613da0a0a6df733314a100795f8ad3395d26aedb83afdaaa21  signalement/photo/car_photo676da05790b9e.png  backendSendra_17012025
732830faa1b3106f9b527b773274302b63364001dd43b4bea9db34451e0ea6da  signalement/photo/car_photo676de578df704.png  backendSendra_17012025
b79fe401c8ed38be3138356582d4d0f9f41261b14cbe881d37ae7f19483707ee  signalement/photo/car_photo676eb6bb3c153.png  backendSendra_17012025
a37e41e2b1a967c42bc77af0f3460d2ce5f2bc5be9fda6cb5c615929a6a7538f  signalement/photo/car_photo6772bdf96001f.png  backendSendra_17012025
faf6672f6a101afe6629a54a67aac8eac13304a42dc416988db7a57dd47553ef  signalement/photo/car_photo67768e6f73863.png  backendSendra_17012025
5ba75cac89a24050dc47f849c13fde6c00a4e9a5a473f53358066ca7e067bf82  dommages/dommages6745b419e78fe.png  backendSendra_17012025
5ba75cac89a24050dc47f849c13fde6c00a4e9a5a473f53358066ca7e067bf82  dommages/dommages6748d69225dd0.png  backendsendra_Aboubacry
5ba75cac89a24050dc47f849c13fde6c00a4e9a5a473f53358066ca7e067bf82  dommages/dommages6748ddcf95154.png  backendSendra_17012025
7473814a213115dab561f32ed04c1e7a1d835c65713de34daacf0148d1532747  dommages/dommages6749c09a1c24d.png  backendSendra_17012025
79f8311b54705e87e9908a7e03be4dd1a70540c535ad5a5d9e6d9002f7893f25  dommages/dommages677aba20676e7.png  backendSendra_17012025
MANIFESTE

echo
echo "== Bilan : $crees $( [ "$APPLIQUER" = "1" ] && echo copiés || echo 'à copier' ), $presents déjà présents, $differents présents avec un autre contenu, $erreurs erreurs"
[ "$APPLIQUER" = "1" ] && [ "$crees" -gt 0 ] && echo "   Fichiers créés (et retour arrière) : $JOURNAL"
[ "$erreurs" -eq 0 ]
