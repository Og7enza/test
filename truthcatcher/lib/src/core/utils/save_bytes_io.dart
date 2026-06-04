import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Écrit des octets JPEG dans un fichier temporaire et renvoie son chemin.
Future<String> saveTempJpg(Uint8List bytes) async {
  final dir = await getTemporaryDirectory();
  final file =
      File('${dir.path}/tc_${DateTime.now().microsecondsSinceEpoch}.jpg');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
