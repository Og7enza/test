import '../config/app_config.dart';

/// Source d'heure de confiance.
///
/// Aujourd'hui : horloge de l'appareil (placeholder, non probant seul).
/// Demain : endpoint serveur `GET /images/getTimeStamp` (voir BACKEND_API.md)
/// ou NTP signé, pour empêcher la falsification de l'horodatage.
abstract interface class TrustedTimeService {
  Future<DateTime> now();
}

/// Implémentation locale : renvoie l'heure de l'appareil (UTC).
class DeviceTrustedTimeService implements TrustedTimeService {
  const DeviceTrustedTimeService();

  @override
  Future<DateTime> now() async => DateTime.now().toUtc();
}

/// Contrôle de dérive d'horloge appareil vs heure de confiance.
class ClockDriftCheck {
  const ClockDriftCheck(this.tolerance);

  final Duration tolerance;

  bool isWithinTolerance(DateTime deviceTime, DateTime trustedTime) {
    final diff = deviceTime.toUtc().difference(trustedTime.toUtc()).abs();
    return diff <= tolerance;
  }

  static const ClockDriftCheck standard = ClockDriftCheck(
    AppConfig.clockDriftTolerance,
  );
}
