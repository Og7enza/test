import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../config/app_config.dart';

/// Empreinte cryptographique on-device + dérivation du matricule.
class HashService {
  const HashService();

  /// SHA-256 (hex) des octets d'une image.
  String sha256Hex(Uint8List bytes) => sha256.convert(bytes).toString();

  /// Matricule public lisible, déterministe, dérivé du hash + de l'instant.
  /// Format : `TC-XXXX-XXXX-XXXX` (alphabet Crockford base32, sans I/L/O/U).
  String deriveMatricule({
    required String sha256Hex,
    required DateTime capturedAt,
  }) {
    final seed = utf8.encode(
      '$sha256Hex|${capturedAt.toUtc().toIso8601String()}',
    );
    final digest = sha256.convert(seed).bytes;
    final buffer = StringBuffer();
    for (var i = 0; i < 12; i++) {
      buffer.write(_alphabet[digest[i] % _alphabet.length]);
      if (i == 3 || i == 7) buffer.write('-');
    }
    return '${AppConfig.matriculePrefix}-$buffer';
  }

  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
}
