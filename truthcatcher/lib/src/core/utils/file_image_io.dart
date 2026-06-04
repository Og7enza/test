import 'dart:io';

import 'package:flutter/widgets.dart';

/// Affiche une image depuis un fichier local (mobile/desktop).
/// Renvoie `null` si le chemin est vide ou le fichier absent.
Widget? localFileImage(
  String? path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
}) {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return Image.file(file, fit: fit, width: width, height: height);
}
