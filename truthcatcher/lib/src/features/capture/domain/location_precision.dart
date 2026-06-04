/// Niveau de précision de la localisation partagée publiquement
/// (granularité réservée aux comptes Premium).
enum LocationPrecision { full, cityCountry, countryOnly, hidden }

extension LocationPrecisionX on LocationPrecision {
  String get label => switch (this) {
        LocationPrecision.full => 'Adresse complète',
        LocationPrecision.cityCountry => 'Ville + Pays',
        LocationPrecision.countryOnly => 'Pays uniquement',
        LocationPrecision.hidden => 'Masquée',
      };

  String get shortLabel => switch (this) {
        LocationPrecision.full => 'Adresse',
        LocationPrecision.cityCountry => 'Ville+Pays',
        LocationPrecision.countryOnly => 'Pays',
        LocationPrecision.hidden => 'Masquée',
      };
}

/// Calcule la localisation effectivement partagée selon la précision choisie.
String sharedLocation({
  required LocationPrecision precision,
  required String fullLabel,
  required String city,
  required String country,
}) {
  switch (precision) {
    case LocationPrecision.full:
      return fullLabel;
    case LocationPrecision.cityCountry:
      return [city, country].where((e) => e.trim().isNotEmpty).join(', ');
    case LocationPrecision.countryOnly:
      return country;
    case LocationPrecision.hidden:
      return '';
  }
}
