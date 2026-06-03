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
      : _hash = hashService ?? const HashService() {
    _seedDemo();
  }

  final HashService _hash;
  final List<Certificate> _store = [];
  final Random _rng = Random();

  /// Pré-remplit la galerie avec quelques preuves de démonstration.
  void _seedDemo() {
    final now = DateTime.now().toUtc();
    _store.addAll([
      Certificate(
        id: 'TC-DEMO-0001-AAAA',
        matricule: 'TC-DEMO-0001-AAAA',
        name: 'Compteur kilométrique',
        sha256Hex:
            'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2',
        capturedAt: now.subtract(const Duration(days: 2, hours: 1)),
        certifiedAt: now.subtract(const Duration(days: 2, hours: 1)),
        latitude: 48.8566,
        longitude: 2.3522,
        locationLabel: 'Paris, France',
        status: CertificateStatus.certified,
        imageUrl: 'https://picsum.photos/seed/tc1/800/1000',
        chain: 'Polygon',
        tokenId: '10241',
        contractAddress: '0xMOCK000000000000000000000000000000000000',
        txHash:
            '0x9f8e7d6c5b4a39281706f5e4d3c2b1a09f8e7d6c5b4a39281706f5e4d3c2b1a0',
      ),
      Certificate(
        id: 'TC-DEMO-0002-BBBB',
        matricule: 'TC-DEMO-0002-BBBB',
        name: 'État des lieux — salon',
        sha256Hex:
            'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3',
        capturedAt: now.subtract(const Duration(days: 1, hours: 5)),
        certifiedAt: now.subtract(const Duration(days: 1, hours: 5)),
        latitude: 45.7640,
        longitude: 4.8357,
        locationLabel: 'Lyon, France',
        status: CertificateStatus.certified,
        imageUrl: 'https://picsum.photos/seed/tc2/800/1000',
        chain: 'Polygon',
        tokenId: '10242',
        contractAddress: '0xMOCK000000000000000000000000000000000000',
        txHash:
            '0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b',
      ),
      Certificate(
        id: 'TC-DEMO-0003-CCCC',
        matricule: 'TC-DEMO-0003-CCCC',
        name: 'Livraison colis',
        sha256Hex:
            'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4',
        capturedAt: now.subtract(const Duration(days: 4)),
        certifiedAt: now.subtract(const Duration(days: 4)),
        latitude: 43.2965,
        longitude: 5.3698,
        locationLabel: 'Marseille, France',
        status: CertificateStatus.certified,
        imageUrl: 'https://picsum.photos/seed/tc3/800/1000',
        chain: 'Polygon',
        tokenId: '10243',
        contractAddress: '0xMOCK000000000000000000000000000000000000',
        txHash:
            '0x0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c4b5a69788796a5b4c3d2e1f0',
        isArchived: true,
      ),
    ]);
  }

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
  Future<List<Certificate>> fetchArchived() async {
    await _fakeLatency();
    final archived = _store.where((c) => c.isArchived).toList()
      ..sort((a, b) => b.certifiedAt.compareTo(a.certifiedAt));
    return List.unmodifiable(archived);
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
