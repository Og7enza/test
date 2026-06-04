/// Helper multiplateforme pour sauver une image temporaire.
/// Sur le web (pas de `dart:io`), renvoie une chaîne vide.
export 'save_bytes_stub.dart' if (dart.library.io) 'save_bytes_io.dart';
