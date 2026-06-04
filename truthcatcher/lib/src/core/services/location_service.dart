import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Résultat d'une prise de position : coordonnées + précision + adresse
/// (complète, plus ville et pays séparés pour la granularité Premium).
class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.label,
    this.city = '',
    this.country = '',
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final String label;
  final String city;
  final String country;
}

/// Accès GPS + reverse-geocoding. Vérifie permissions et service activé.
class LocationService {
  const LocationService();

  Future<GeoFix> currentFix() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('Le service de localisation est désactivé.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException('Permission de localisation refusée.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return _resolve(position.latitude, position.longitude, position.accuracy);
  }

  /// Variante « démo » : ne lève jamais d'exception. En cas de refus de
  /// permission ou de GPS indisponible, renvoie une position simulée afin que
  /// le parcours de certification reste démontrable de bout en bout.
  Future<GeoFix> currentFixOrSimulated() async {
    try {
      return await currentFix();
    } catch (_) {
      return const GeoFix(
        latitude: 48.85837,
        longitude: 2.29448,
        accuracy: 0,
        label: 'Champ de Mars, Paris, France (simulé)',
        city: 'Paris',
        country: 'France',
      );
    }
  }

  Future<GeoFix> _resolve(double lat, double lng, double accuracy) async {
    var label = _coords(lat, lng);
    var city = '';
    var country = '';
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        city = (p.locality?.trim().isNotEmpty ?? false)
            ? p.locality!.trim()
            : (p.subAdministrativeArea?.trim() ?? '');
        country = p.country?.trim() ?? '';
        final parts = <String?>[
          p.street,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((e) => e != null && e.trim().isNotEmpty).toList();
        if (parts.isNotEmpty) label = parts.join(', ');
      }
    } catch (_) {
      // On garde les coordonnées brutes comme label.
    }
    return GeoFix(
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
      label: label,
      city: city,
      country: country,
    );
  }

  String _coords(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
