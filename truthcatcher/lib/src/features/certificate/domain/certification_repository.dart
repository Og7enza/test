import '../../capture/domain/capture_draft.dart';
import 'certificate.dart';

/// Contrat d'accès aux preuves.
///
/// Implémenté en local par `MockCertificationRepository` aujourd'hui, par
/// `ApiCertificationRepository` (backend) demain — sans changer l'UI.
/// Chaque méthode correspond à une route documentée dans docs/BACKEND_API.md.
abstract interface class CertificationRepository {
  /// Heure de confiance. → `GET /images/getTimeStamp`
  Future<DateTime> trustedTimestamp();

  /// Mes preuves certifiées. → `GET /images/all`
  Future<List<Certificate>> fetchCertificates();

  /// Mes preuves archivées. → `GET /images/archive`
  Future<List<Certificate>> fetchArchived();

  /// Certifie une capture (hash + matricule + mint). → `POST /images/upload`
  Future<Certificate> certify(CaptureDraft draft);

  /// Vérifie une preuve par son matricule. → `GET /images/searchImage/{matricule}`
  Future<Certificate?> verifyByMatricule(String matricule);

  /// Archive une preuve. → `POST /images/archive/{matricule}`
  Future<void> archive(String matricule);

  /// Désarchive une preuve. → `PATCH /images/unArchive/{matricule}`
  Future<void> unarchive(String matricule);
}
