import 'dart:typed_data';

/// Brouillon de preuve : tout ce qui est capturé localement AVANT certification
/// (photo, empreinte, géolocalisation, horodatage), plus les choix de
/// confidentialité (Premium) : quelles infos sont partagées et la visibilité.
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
    this.shareAddress = true,
    this.shareCoordinates = true,
    this.shareTimestamp = true,
    this.isPublic = true,
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

  // Confidentialité (Premium)
  final bool shareAddress;
  final bool shareCoordinates;
  final bool shareTimestamp;
  final bool isPublic;

  CaptureDraft copyWith({
    String? name,
    bool? shareAddress,
    bool? shareCoordinates,
    bool? shareTimestamp,
    bool? isPublic,
  }) =>
      CaptureDraft(
        imagePath: imagePath,
        bytes: bytes,
        sha256Hex: sha256Hex,
        capturedAt: capturedAt,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        locationLabel: locationLabel,
        name: name ?? this.name,
        shareAddress: shareAddress ?? this.shareAddress,
        shareCoordinates: shareCoordinates ?? this.shareCoordinates,
        shareTimestamp: shareTimestamp ?? this.shareTimestamp,
        isPublic: isPublic ?? this.isPublic,
      );
}
