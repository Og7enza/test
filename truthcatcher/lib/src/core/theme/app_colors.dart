import 'package:flutter/material.dart';

/// Palette TruthCatcher (charte graphique officielle).
/// Aucun noir : les textes sombres utilisent le bleu marine.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1F73B9); // bleu
  static const Color primaryDark = Color(0xFF294083); // marine
  static const Color background = Color(0xFFF2F2F2); // gris clair
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF294083); // marine (pas de noir)
  static const Color textMuted = Color(0xFF6B7A99); // bleu-gris

  static const Color success = Color(0xFF2BB673);
  static const Color danger = Color(0xFFE3452D);

  /// Dégradé de marque (bleu → marine).
  static const List<Color> brandGradient = [primary, primaryDark];
}
