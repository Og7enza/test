/// Configuration applicative centralisée.
class AppConfig {
  const AppConfig._();

  /// Base URL du backend d'origine (mort / à reconstruire).
  /// Voir docs/BACKEND_API.md.
  static const String apiBaseUrl = 'https://backend.truthcatcher.com/api/v1';

  /// Réseau de mint des NFT.
  static const String chainName = 'Polygon';

  /// Tolérance de dérive entre l'horloge de l'appareil et l'heure de confiance
  /// (reprend la logique anti-triche de l'app d'origine).
  static const Duration clockDriftTolerance = Duration(minutes: 1);

  /// Préfixe lisible des matricules (ex. `TC-XXXX-XXXX-XXXX`).
  static const String matriculePrefix = 'TC';
}
