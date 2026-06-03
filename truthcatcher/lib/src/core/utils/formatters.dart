import 'package:intl/intl.dart';

/// Helpers d'affichage (dates, hash, coordonnées).
String formatDateTime(DateTime dt) =>
    DateFormat('dd/MM/yyyy · HH:mm:ss').format(dt.toLocal());

String shortenHash(String hex, {int head = 10, int tail = 8}) {
  if (hex.length <= head + tail + 1) return hex;
  return '${hex.substring(0, head)}…${hex.substring(hex.length - tail)}';
}

String formatCoords(double lat, double lng) =>
    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
