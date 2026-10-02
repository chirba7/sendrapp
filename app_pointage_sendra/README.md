# Sendra Pointage

Application Flutter Android/iOS pour les employés. API par défaut : préproduction `https://backpreprod.sendra.sn/api`. L'adresse peut être changée au lancement :

```sh
flutter run --dart-define=SENDRA_API_BASE_URL=https://backpreprod.sendra.sn/api
```

Parcours : code SMS → inscription → liaison du téléphone avec biométrie native → validation en personne dans le back-office → affectation à un site et à un horaire → arrivée/départ après empreinte ou Face ID et position GPS précise. Un compte Sendra existant peut demander l’accès depuis l’application. Le serveur n’autorise qu’un téléphone par compte ; un changement exige une réinitialisation et une nouvelle validation par un responsable.

Le téléphone garde une clé dans le stockage protégé par la biométrie du système. À chaque pointage, cette clé signe un défi du serveur après vérification par empreinte ou Face ID. L’application ne récupère aucune empreinte ni photo du visage. Android 11 ou plus récent avec biométrie forte est requis ; iOS utilise les biométries actuellement enregistrées et invalide la clé si elles changent. Sur un téléphone partagé, toute biométrie enregistrée peut toutefois déverrouiller le compte : l’appareil doit être dédié à un seul employé. L’adresse IP ne sert pas à identifier le téléphone ; le GPS vérifie seulement le lieu du pointage.

Vérification locale : `flutter analyze` et `flutter test`. Le projet contient les cibles Android et iOS ; une compilation iOS nécessite macOS et Xcode. La signature de publication et la validation sur appareils réels sont encore à effectuer. La configuration serveur et les règles métier sont dans [`../procedures/POINTAGE.md`](../procedures/POINTAGE.md).

Si Gradle signale que `JniPlugin.class` existe déjà pendant `flutter run --profile`, fermez les autres compilations Flutter du projet puis régénérez les fichiers de build :

```sh
flutter clean
flutter pub get
flutter run --profile
```
