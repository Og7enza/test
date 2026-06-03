import 'dart:typed_data';

/// Brouillon de preuve : tout ce qui est capturé localement AVANT certification
/// (photo, empreinte, géolocalisation, horodatage de confiance).
class CaptureDraft {
  const CaptureDraft({
    required this.imagePath,
    required this.bytes,
    required this.sha256Hex,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.locationLabel,
    this.name = '',
  });

  final String imagePath;
  final Uint8List bytes;
  final String sha256Hex;
  final DateTime capturedAt;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String locationLabel;
  final String name;

  CaptureDraft copyWith({String? name}) => CaptureDraft(
        imagePath: imagePath,
        bytes: bytes,
        sha256Hex: sha256Hex,
        capturedAt: capturedAt,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        locationLabel: locationLabel,
        name: name ?? this.name,
      );
}
