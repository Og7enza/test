import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../utils/formatters.dart';

/// Incruste le matricule (+ date/lieu) en bas de la photo : un filigrane
/// visible et indélébile, pour que l'image **porte elle-même** son identifiant
/// recherchable. La photo tamponnée est celle affichée/partagée ; le hash de
/// preuve reste calculé sur l'image **originale**.
class StampService {
  const StampService();

  Future<Uint8List> stamp({
    required Uint8List bytes,
    required String matricule,
    required DateTime capturedAt,
    String? location,
  }) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final w = decoded.width;
    final h = decoded.height;
    final bandHeight = (h * 0.12).round().clamp(64, 480);
    final top = h - bandHeight;
    final padding = (w * 0.02).round().clamp(12, 48);

    // Bandeau semi-transparent
    img.fillRect(
      decoded,
      x1: 0,
      y1: top,
      x2: w,
      y2: h,
      color: img.ColorRgba8(41, 64, 131, 175),
    );

    final titleFont = w >= 1000 ? img.arial48 : img.arial24;

    // Matricule (gros)
    img.drawString(
      decoded,
      matricule,
      font: titleFont,
      x: padding,
      y: top + padding,
      color: img.ColorRgb8(255, 255, 255),
    );

    // Date + lieu (tronqué pour rester dans le cadre)
    final loc = location ?? '';
    final shortLoc = loc.length > 36 ? '${loc.substring(0, 36)}…' : loc;
    final subtitle = shortLoc.isEmpty
        ? formatDateTime(capturedAt)
        : '${formatDateTime(capturedAt)}  •  $shortLoc';

    img.drawString(
      decoded,
      subtitle,
      font: img.arial24,
      x: padding,
      y: top + padding + titleFont.lineHeight + 8,
      color: img.ColorRgb8(225, 225, 225),
    );

    // Signature applicative
    img.drawString(
      decoded,
      'TruthCatcher',
      font: img.arial14,
      x: padding,
      y: h - img.arial14.lineHeight - 8,
      color: img.ColorRgb8(180, 200, 255),
    );

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
  }
}
