/// Helper multiplateforme pour afficher une image de fichier local.
/// Sur le web (pas de `dart:io`), renvoie toujours `null`.
export 'file_image_stub.dart' if (dart.library.io) 'file_image_io.dart';
