class Strings {
  //? Buttons
  static const String next = 'SUIVANT';
  static const String skip = 'Skip';
  static const String submit = 'ENVOYER';
  static const String okay = 'Continuer';
  static const String signaler = 'SIGNALER';

  static const String backButton = 'assets/images/others/back-button.png';
  static const String backButtonWhite =
      'assets/images/others/back-button-white.png';
  static const String otpImage = 'assets/images/others/OTP.png';
  static const String resetPasswordImage =
      'assets/images/others/reset-password.png';
  static const String congratulationsImage =
      'assets/images/others/congratulations.png';

  static const String pleaseFillOutTheField = 'Please fill out the field';

  static const String password = 'Mot de passe';

  //? otp verification screen
  static const String otpVerification = 'Vérification du numéro';
  static const String enterTheCodeSentTo =
      'Entrez le code envoyé par Whatsapp au';

  //? reset password screen
  static const String resetPassword = 'Modifier mot de passe';
  static const String resetPasswordDescription =
      'Your identity has been verified, Set your new Password';
  static const String newPassword = 'Nouveau mot de passe';
  static const String enterNewPassword = 'Nouveau mot de passe';
  static const String confirmPassword = 'Confirmer le mot de passe';
  static const String enterConfirmPassword = 'Confirmer le mot de passe';

  //?reset password congratulations screen
  static const String resetPassCongTitle = 'Mot de passe modifié';
  static const String resetPassCongDes =
      'Votre mot de passe a été modifié avec succès.';

  static const String name = 'Prénom et Nom';

  //? home screen
  static const String home = 'Participations';

  static const String send = 'Send';
  static const String request = 'Request';
  static const String signalement = 'Signalement';
  static const String details = 'Détails du signalement';

  // Backend de préprod distant — remplace le backend local Docker comme
  // cible par défaut de l'app.
  static const String apiHostProd = 'https://backpreprod.sendra.sn';

  static String apiHost = apiHostProd;
  static String get apiURI => '$apiHost/api/';

  //?profile screen
  static const String profile = 'Profil';
  static const String userId = '@';
  static const String changePassword = 'Mot de passe';

  //? change password screen
  static const String oldPassword = 'Mot de passe actuel';

  static const String address = 'Address';

  static const String description = 'Description';

  //? send money success screen
  static const String success = 'Success!';

  static const String titre = 'Titre';

  static const String support = 'Support';
  static const String aboutUs = 'A propos';
  static const String signOut = 'Déconnexion';

  //? about screen
  static const String aboutUsPartOne =
      "1. Définitions\n-Application : désigne l'application mobile Epavie.\n-Utilisateur : désigne toute personne qui utilise l'application.\n-Service : désigne les fonctionnalités et services offerts par l'application.\n-Données Personnelles : désigne les informations relatives à une personne physique identifiée ou identifiable.\n\n2. Responsabilités de l'Utilisateur\nLes utilisateurs sont responsables de l'exactitude des informations qu'ils fournissent et doivent utiliser l'application conformément aux lois en vigueur. Toute utilisation abusive ou frauduleuse de l'application peut entraîner la résiliation de l'accès au service.\n\n3. Propriété Intellectuelle\nTous les contenus présents sur l'application, y compris les textes, images et logiciels, sont protégés par des droits de propriété intellectuelle. Toute reproduction ou utilisation non autorisée de ces contenus est strictement interdite.\n\n4. Limitations de Responsabilité\nL'entreprise ne peut être tenue responsable des dysfonctionnements de l'application, des pertes de données, ou de tout autre dommage résultant de l'utilisation de l'application.";
  static const String aboutUsPartTwo =
      "5. Modification des CGU\nNous nous réservons le droit de modifier les présentes CGU à tout moment. Les utilisateurs seront informés des modifications via l'application ou par tout autre moyen approprié.\n\n6. Conditions de Résiliation\nLes utilisateurs peuvent résilier leur accès au service à tout moment en supprimant leur compte. Nous nous réservons également le droit de résilier l'accès au service en cas de violation des présentes CGU.\n\n7. Service Client et Support\nPour toute question ou assistance, les utilisateurs peuvent contacter notre service client à l'adresse support@epavie.com.";

  static const String aboutUsPartThree =
      "1. Collecte et Utilisation des Données Personnelles\nNous collectons des données personnelles pour fournir et améliorer nos services. Ces données incluent, mais ne sont pas limitées à, les informations de compte, les préférences de l'utilisateur et les données de navigation. Les utilisateurs ont le droit d'accéder à leurs données personnelles, de les rectifier et de les supprimer en contactant notre service client.\n\n2. Sécurité des Données\nNous mettons en œuvre des mesures de sécurité appropriées pour protéger les données personnelles des utilisateurs contre toute perte, utilisation abusive ou accès non autorisé.";
  static const String aboutUsPartFour =
      "3. Partage des Données\nNous ne partageons pas les données personnelles des utilisateurs avec des tiers, sauf si cela est nécessaire pour fournir nos services ou si la loi l'exige.\n\n4. Conservation des Données\nNous conservons les données personnelles des utilisateurs aussi longtemps que nécessaire pour fournir nos services et conformément aux lois applicables.\n\n5. Droit d'Accès et de Rectification\nLes utilisateurs ont le droit d'accéder à leurs données personnelles, de les rectifier, de demander leur suppression ou de s'opposer à leur traitement. Pour exercer ces droits, les utilisateurs peuvent contacter notre service client à l'adresse support@epavie.com.";
  static const String copyright = 'CopyRight © 2023 SENDRA';
  static const String websiteLink = 'www.sendra.sn';

  static const String cartoItem = 'Cartographie';
}
