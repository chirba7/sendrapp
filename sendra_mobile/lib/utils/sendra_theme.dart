import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Charte visuelle commune aux applications epaVie (Pro et Citoyen).
///
/// La police Inter est embarquée dans l'application (assets/fonts) : plus de
/// téléchargement au démarrage via google_fonts, donc pas de « saut » de
/// texte ni d'attente réseau sur le terrain.
class SendraTheme {
  static const fontFamily = 'Inter';

  // Couleurs de marque
  static const green = Color(0xFF07883F);
  static const greenDark = Color(0xFF06703A);
  static const forest = Color(0xFF075C32);
  static const greenSoft = Color(0xFFE3F3EA);

  // Neutres
  static const surface = Color(0xFFF5F7F6);
  static const card = Colors.white;
  static const ink = Color(0xFF15201A);
  static const muted = Color(0xFF5F6B65);
  static const border = Color(0xFFE1E8E4);

  // Statuts (mêmes teintes partout : liste, filtres, détails, carte)
  static const statusSignale = Color(0xFFD93025);
  static const statusEnCours = Color(0xFFE37400);
  static const statusResolu = Color(0xFF188038);
  static const statusNonResolu = Color(0xFFC5221F);
  static const statusRejete = Color(0xFF5F6368);
  static const amber = Color(0xFFF59E0B);

  static const radius = 16.0;

  /// Style des barres système : icônes sombres sur fond clair.
  static const overlayLight = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  /// Style des barres système sur fond vert (splash).
  static const overlayGreen = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: forest,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      brightness: Brightness.light,
    ).copyWith(
      primary: green,
      onPrimary: Colors.white,
      secondary: forest,
      surface: Colors.white,
      onSurface: ink,
      surfaceTint: Colors.transparent,
      outline: border,
      outlineVariant: border,
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
    );

    final text = base.textTheme
        .copyWith(
          headlineSmall: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, height: 1.25),
          titleLarge: const TextStyle(
              fontSize: 19, fontWeight: FontWeight.w700, height: 1.3),
          titleMedium: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
          titleSmall: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.45),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.45),
          bodySmall: const TextStyle(fontSize: 12.5, height: 1.4),
          labelLarge: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: .1),
        )
        .apply(
          fontFamily: fontFamily,
          bodyColor: ink,
          displayColor: ink,
        );

    final roundedShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // Transitions de page légères et cohérentes sur Android et iOS.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: .5,
        shadowColor: Color(0x1A000000),
        backgroundColor: Colors.white,
        foregroundColor: ink,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayLight,
        iconTheme: IconThemeData(color: ink, size: 24),
        actionsIconTheme: IconThemeData(color: ink, size: 24),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: ink, size: 22),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: green,
        collapsedIconColor: muted,
        shape: Border(),
        collapsedShape: Border(),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: border),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: green,
        titleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: ink),
        subtitleTextStyle: TextStyle(
            fontFamily: fontFamily, fontSize: 13.5, color: muted, height: 1.4),
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 10,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        labelStyle: const TextStyle(color: muted),
        floatingLabelStyle:
            const TextStyle(color: green, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: muted.withValues(alpha: .75)),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: green, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: statusSignale),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: statusSignale, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: green.withValues(alpha: .35),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: roundedShape,
          textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 15.5,
              fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: roundedShape,
          textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 15.5,
              fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: green,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          side: const BorderSide(color: green, width: 1.3),
          shape: roundedShape,
          textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 15.5,
              fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: green,
          minimumSize: const Size(48, 44),
          textStyle: const TextStyle(
              fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: green,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 5,
        extendedTextStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w700),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: greenSoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? green : muted,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontFamily: fontFamily,
              fontSize: 12.5,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? green : muted,
            )),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        // Puce sélectionnée : fond vert clair + texte vert foncé (lisible).
        selectedColor: greenSoft,
        side: const BorderSide(color: border),
        labelStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: ink),
        secondaryLabelStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: forest),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: ink),
        contentTextStyle: const TextStyle(
            fontFamily: fontFamily, fontSize: 15, height: 1.45, color: muted),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(24))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(
            fontFamily: fontFamily, color: Colors.white, fontSize: 14.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: green,
        linearTrackColor: greenSoft,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? green : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? green : muted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? green : null),
      ),
    );
  }

  /// Couleur, libellé et icône d'un statut de signalement.
  static ({Color color, String label, IconData icon}) status(String? etat) {
    switch (etat) {
      case 'SIGNALE':
        return (
          color: statusSignale,
          label: 'Signalé',
          icon: Icons.flag_rounded
        );
      case 'EN COURS':
        return (
          color: statusEnCours,
          label: 'En cours',
          icon: Icons.timelapse_rounded
        );
      case 'ENLEVE':
        return (
          color: statusResolu,
          label: 'Résolu',
          icon: Icons.check_circle_rounded
        );
      case 'NON RESOLU':
        return (
          color: statusNonResolu,
          label: 'Non résolu',
          icon: Icons.report_rounded
        );
      case 'REJETE':
        return (
          color: statusRejete,
          label: 'Rejeté',
          icon: Icons.block_rounded
        );
      default:
        return (color: muted, label: 'Inconnu', icon: Icons.help_outline);
    }
  }
}
