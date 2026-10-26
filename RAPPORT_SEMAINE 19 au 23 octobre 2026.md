# Rapport d’activité — Plateforme Sendra

**Période :** du 19 au 23 octobre 2026  
**Périmètre :** Sendra Citoyen, application agent, back-office de préproduction et site web.

## Synthèse

La semaine a été consacrée à la revue des parcours de la plateforme Sendra et à la définition des corrections attendues après une présentation avec le CEO et l’encadreur du projet. Une seconde présentation, le jeudi 22 octobre, a apporté des demandes complémentaires sur la simplicité du signalement, la prise en charge par l’agent, les procès-verbaux et le site web. La refonte du site a démarré. Les applications et le circuit métier doivent encore être testés par le personnel Sendra avant validation des choix fonctionnels.

## 1. Corrections retenues après la première présentation

### Parcours communs et compte utilisateur

- Mettre à jour les logos et les icônes des applications.
- Investiguer la non-réception des SMS contenant le code OTP sur les numéros Free commençant par **76**.
- Corriger l’affichage de la saisie du code OTP dans le parcours « Mot de passe oublié ». Après une réinitialisation réussie, afficher une confirmation en français avec le nouveau logo.
- Revoir les conditions générales d’utilisation et la politique de confidentialité.
- Permettre, depuis le profil, la modification de la photo, du prénom et du nom.

### Sendra Citoyen

- Limiter le signalement à **une photo**, au lieu de cinq.
- Centrer la carte sur la position de l’utilisateur. Le bouton de localisation doit revenir à cette position, et non à la vue générale du Sénégal.
- Corriger les débordements sur les petits écrans et respecter la zone occupée par la barre de navigation du téléphone.
- Montrer au citoyen les étapes d’avancement de son signalement, notamment l’envoi pour approbation et la décision de l’autorité.

### Application agent

- Adapter les écrans aux petites tailles et corriger les débordements.
- Autoriser l’ajout de photos lors de la constatation, en distinguant les photos du citoyen de celles de l’agent.
- Laisser la plaque d’immatriculation en saisie libre, sans format imposé bloquant.
- Revoir les champs « type » et « catégorie » du véhicule et remonter le champ « pays étranger » dans le formulaire.
- Placer « État général » juste avant « Détails du véhicule ». N’afficher les détails que si l’état est « moyen » ou « dégradé » et retirer « châssis non réparable » des choix.
- Dans « Infraction », proposer les **13 motifs** dans une liste déroulante, accompagnée d’un champ « Explication ».
- Dans « Constatation / Dommages », afficher la légende **X = bris, O = enfoncement, V = rayure**, puis ajouter une description des pièces manquantes du véhicule ou de la moto.

### Transmission, approbation et procès-verbal

- Après « Envoyer pour approbation », laisser la confirmation visible jusqu’à l’action « Quitter » de l’agent.
- Rendre le signalement transmis non modifiable par l’agent et afficher à sa place un récapitulatif détaillé.
- Produire un procès-verbal (PV) consultable par l’autorité, avec décision de validation ou de refus, et répercuter le statut dans l’application citoyenne.

### Back-office et missions

- Revoir les rôles et ajouter un rôle **Opérateur** pour la création des missions et des opérations associées.
- Renommer « Mission directe » en « Mission ponctuelle ».
- Permettre, dans une mission, la prise en charge d’un véhicule découvert en infraction alors qu’il n’avait pas été signalé auparavant.

## 2. Compléments de la présentation du jeudi 22 octobre

**Parcours citoyen.** La page d’accueil doit mettre en avant un grand bouton « Signaler » et des entrées visuelles distinctes pour voiture, moto et camion. Les informations de base superflues doivent être retirées. La politique de confidentialité doit être accessible par un lien. Le parcours de retour et la navigation par glissement entre écrans doivent être clarifiés. L’écran de bienvenue ne doit apparaître qu’une seule fois. Il faut aussi définir le traitement des signalements en doublon et les conditions dans lesquelles un citoyen peut voir les signalements d’autres personnes.

**Constatation et prise en charge par l’agent.** Le bouton « Prendre en charge » doit être explicite. L’adresse précise doit être affichée en lecture seule lorsque sa modification n’est pas autorisée. Les photos doivent pouvoir être limitées, consultées et supprimées facilement, sur tous les formats d’écran. Des annotations prédéfinies sont demandées, avec une étape de relecture avant validation.

**Approbation et documents.** L’agent doit pouvoir consulter, signer et télécharger le PV. Le signalement doit passer au statut « En cours » dès la demande d’approbation. L’autorité doit disposer d’actions claires « Oui » et « Non » pour sa décision, voir les informations non modifiables comme telles, et accéder au PV de constatation ainsi qu’au PV d’enlèvement. Les titres et libellés présentés au citoyen et à l’autorité sont à harmoniser.

**Site web.** La refonte engagée doit améliorer la présentation de Sendra, l’accès WhatsApp, la recherche d’un véhicule depuis la page de contact et les formulaires. Elle doit aussi expliquer la procédure de vente aux enchères ou de mise en destruction.

## 3. Travaux engagés et vérifications à poursuivre

L’identité visuelle des deux applications, le démarrage, l’écran de bienvenue et plusieurs écrans d’accès ont fait l’objet de premiers correctifs. Le parcours des missions a également été ajusté pour que le réceptionniste voie les véhicules prévus mais non enlevés, avec leur motif, y compris lorsqu’aucun véhicule n’arrive à la fourrière. Ces éléments devront être confirmés dans les essais du personnel. Les autres points ci-dessus constituent le périmètre de correction et de validation ; leur présence dans ce rapport ne signifie pas qu’ils sont tous livrés.

Les vérifications prioritaires portent sur la réception des SMS Free 76, la lisibilité sur petits écrans, la cohérence des statuts entre agent, autorité et citoyen, la distinction des photos selon leur auteur et la production des PV. Les circuits de validation doivent être testés de bout en bout avant d’être considérés comme finalisés.

## 4. Décisions attendues

1. Fournir la liste officielle des 13 motifs d’infraction et les règles de saisie des champs « type », « catégorie » et « pays étranger ».
2. Définir précisément les droits du rôle Opérateur et des autres rôles, ainsi que le circuit de signature, d’approbation et de refus des PV.
3. Valider les statuts et messages visibles par le citoyen à chaque étape, y compris les doublons et la visibilité éventuelle des signalements d’autrui.
4. Décrire la prise en charge d’un véhicule non signalé, le contenu du récapitulatif, du PV de constatation et du PV d’enlèvement.
5. Confirmer la procédure métier de vente aux enchères ou de mise en destruction à publier sur le site.

## 5. Prochaines étapes

Une nouvelle présentation est attendue **jeudi 29 octobre 2026** pour montrer l’avancement des applications et de la refonte du site. D’ici là, les APK seront partagés avec le personnel Sendra. Les rôles nécessaires — agent, citoyen, administrateur et autres profils retenus — seront attribués aux testeurs. Leurs retours seront recueillis à l’aide d’un questionnaire, puis regroupés et exploités lors de la prochaine réunion pour prioriser les corrections restantes.
