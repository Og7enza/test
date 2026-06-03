import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/hash_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/stamp_service.dart';
import '../../../core/services/trusted_time_service.dart';
import '../../capture/domain/capture_draft.dart';
import '../data/mock_certification_repository.dart';
import '../domain/certificate.dart';
import '../domain/certification_repository.dart';

// --- Services ---
final hashServiceProvider = Provider<HashService>((ref) => const HashService());

final locationServiceProvider =
    Provider<LocationService>((ref) => const LocationService());

final trustedTimeServiceProvider =
    Provider<TrustedTimeService>((ref) => const DeviceTrustedTimeService());

final stampServiceProvider =
    Provider<StampService>((ref) => const StampService());

// --- Repository ---
// Mock aujourd'hui. Remplacer par ApiCertificationRepository quand le backend
// sera reconstruit (voir docs/ARCHITECTURE.md).
final certificationRepositoryProvider = Provider<CertificationRepository>(
  (ref) => MockCertificationRepository(
    hashService: ref.read(hashServiceProvider),
  ),
);

// --- Liste des certificats (galerie) ---
final certificatesProvider =
    AsyncNotifierProvider<CertificatesNotifier, List<Certificate>>(
  CertificatesNotifier.new,
);

class CertificatesNotifier extends AsyncNotifier<List<Certificate>> {
  @override
  Future<List<Certificate>> build() {
    return ref.watch(certificationRepositoryProvider).fetchCertificates();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(certificationRepositoryProvider).fetchCertificates(),
    );
  }

  Future<Certificate> certify(CaptureDraft draft) async {
    final cert = await ref.read(certificationRepositoryProvider).certify(draft);
    await refresh();
    return cert;
  }
}

// --- Preuves archivées ---
final archivedCertificatesProvider =
    FutureProvider.autoDispose<List<Certificate>>(
  (ref) => ref.read(certificationRepositoryProvider).fetchArchived(),
);

// --- Vérification par matricule (deeplink / recherche) ---
final verifyMatriculeProvider =
    FutureProvider.autoDispose.family<Certificate?, String>(
  (ref, matricule) =>
      ref.read(certificationRepositoryProvider).verifyByMatricule(matricule),
);
