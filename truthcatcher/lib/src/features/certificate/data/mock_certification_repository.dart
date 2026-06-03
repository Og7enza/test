import 'dart:math';

import '../../../core/config/app_config.dart';
import '../../../core/services/hash_service.dart';
import '../../capture/domain/capture_draft.dart';
import '../domain/certificate.dart';
import '../domain/certification_repository.dart';

/// Implémentation 100 % locale (sans backend) : calcule le matricule à partir du
/// hash, simule un mint NFT « gas-free », et stocke les preuves en mémoire.
///
/// Permet de démontrer toute l'UX immédiatement. À remplacer par
/// `ApiCertificationRepository` quand le backend existera (voir ARCHITECTURE.md §5).
class MockCertificationRepository implements CertificationRepository {
  MockCertificationRepository({HashService? hashService})
      : _hash = hashService ?? const HashService();

  final HashService _hash;
  final List<Certificate> _store = [];
  final Random _rng = Random();

  @override
  Future<DateTime> trustedTimestamp() async => DateTime.now().toUtc();

  @override
  Future<List<Certificate>> fetchCertificates() async {
    await _fakeLatency();
    final visible = _store.where((c) => !c.isArchived).toList()
      ..sort((a, b) => b.certifiedAt.compareTo(a.certifiedAt));
    return List.unmodifiable(visible);
  }

  @override
  Future<Certificate> certify(CaptureDraft draft) async {
    await _fakeLatency(ms: 900);
    final certifiedAt = DateTime.now().toUtc();
    final matricule = _hash.deriveMatricule(
      sha256Hex: draft.sha256Hex,
      capturedAt: draft.capturedAt,
    );
    final certificate = Certificate(
      id: matricule,
      matricule: matricule,
      name: draft.name.trim().isEmpty ? 'Sans titre' : draft.name.trim(),
      sha256Hex: draft.sha256Hex,
      capturedAt: draft.capturedAt,
      certifiedAt: certifiedAt,
      latitude: draft.latitude,
      longitude: draft.longitude,
      locationLabel: draft.locationLabel,
      localImagePath: draft.imagePath,
      status: CertificateStatus.certified,
      // Mint NFT simulé (gas-free) — remplacé par le vrai mint Polygon plus tard.
      chain: AppConfig.chainName,
      tokenId: _fakeTokenId(),
      contractAddress: '0xMOCK000000000000000000000000000000000000',
      txHash: _fakeHashHex(64),
    );
    _store.add(certificate);
    return certificate;
  }

  @override
  Future<Certificate?> verifyByMatricule(String matricule) async {
    await _fakeLatency();
    final normalized = matricule.trim().toUpperCase();
    for (final c in _store) {
      if (c.matricule.toUpperCase() == normalized) return c;
    }
    return null;
  }

  @override
  Future<void> archive(String matricule) async {
    _replace(matricule, (c) => c.copyWith(isArchived: true));
  }

  @override
  Future<void> unarchive(String matricule) async {
    _replace(matricule, (c) => c.copyWith(isArchived: false));
  }

  void _replace(String matricule, Certificate Function(Certificate) update) {
    final i = _store.indexWhere((c) => c.matricule == matricule);
    if (i != -1) _store[i] = update(_store[i]);
  }

  String _fakeTokenId() => _rng.nextInt(1 << 31).toString();

  String _fakeHashHex(int len) {
    const hex = '0123456789abcdef';
    return '0x${List.generate(len, (_) => hex[_rng.nextInt(16)]).join()}';
  }

  Future<void> _fakeLatency({int ms = 350}) =>
      Future<void>.delayed(Duration(milliseconds: ms));
}
