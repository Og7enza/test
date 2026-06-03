import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Résultat d'une prise de position : coordonnées + précision + adresse lisible.
class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final String label;
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

    final label = await _reverseGeocode(position.latitude, position.longitude);
    return GeoFix(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      label: label,
    );
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
        label: 'Position simulée (démo)',
      );
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return _coords(lat, lng);
      final p = placemarks.first;
      final parts = <String?>[
        p.street,
        p.locality,
        p.administrativeArea,
        p.country,
      ].where((e) => e != null && e.trim().isNotEmpty).toList();
      return parts.isEmpty ? _coords(lat, lng) : parts.join(', ');
    } catch (_) {
      return _coords(lat, lng);
    }
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
