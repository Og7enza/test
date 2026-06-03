/// Statut d'une preuve.
enum CertificateStatus { draft, certifying, certified, failed }

/// Une preuve certifiée. Modernise l'ancien modèle `MintedImage`
/// (voir docs/BACKEND_API.md §7) en y ajoutant les champs probants manquants
/// (hash SHA-256, latitude/longitude).
class Certificate {
  const Certificate({
    required this.matricule,
    required this.name,
    required this.sha256Hex,
    required this.capturedAt,
    required this.certifiedAt,
    required this.latitude,
    required this.longitude,
    required this.locationLabel,
    required this.status,
    this.id,
    this.authorId,
    this.imageUrl,
    this.localImagePath,
    this.tokenId,
    this.contractAddress,
    this.txHash,
    this.chain,
    this.isArchived = false,
  });

  final String matricule;
  final String name;
  final String sha256Hex;
  final DateTime capturedAt;
  final DateTime certifiedAt;
  final double latitude;
  final double longitude;
  final String locationLabel;
  final CertificateStatus status;

  final String? id;
  final String? authorId;
  final String? imageUrl;
  final String? localImagePath;

  // NFT
  final String? tokenId;
  final String? contractAddress;
  final String? txHash;
  final String? chain;

  final bool isArchived;

  bool get isMinted => tokenId != null && tokenId!.isNotEmpty;

  Certificate copyWith({
    String? matricule,
    String? name,
    String? sha256Hex,
    DateTime? capturedAt,
    DateTime? certifiedAt,
    double? latitude,
    double? longitude,
    String? locationLabel,
    CertificateStatus? status,
    String? id,
    String? authorId,
    String? imageUrl,
    String? localImagePath,
    String? tokenId,
    String? contractAddress,
    String? txHash,
    String? chain,
    bool? isArchived,
  }) {
    return Certificate(
      matricule: matricule ?? this.matricule,
      name: name ?? this.name,
      sha256Hex: sha256Hex ?? this.sha256Hex,
      capturedAt: capturedAt ?? this.capturedAt,
      certifiedAt: certifiedAt ?? this.certifiedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      status: status ?? this.status,
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      tokenId: tokenId ?? this.tokenId,
      contractAddress: contractAddress ?? this.contractAddress,
      txHash: txHash ?? this.txHash,
      chain: chain ?? this.chain,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  /// Bridge depuis l'ancien `MintedImage` renvoyé par le backend d'origine.
  /// Utilisé plus tard par `ApiCertificationRepository`.
  factory Certificate.fromMintedImageJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v, DateTime fallback) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v)?.toUtc() ?? fallback;
      }
      return fallback;
    }

    final created = parseDate(json['createdAt'], DateTime.now().toUtc());
    return Certificate(
      id: json['_id']?.toString(),
      authorId: json['userId']?.toString(),
      matricule: json['matricule']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['image']?.toString(),
      sha256Hex: json['sha256']?.toString() ?? '',
      capturedAt: parseDate(json['time'], created),
      certifiedAt: created,
      latitude: (json['lat'] as num?)?.toDouble() ?? 0,
      longitude: (json['lng'] as num?)?.toDouble() ?? 0,
      locationLabel: json['location']?.toString() ?? '',
      status: CertificateStatus.certified,
      tokenId: json['tokenId']?.toString(),
      contractAddress: json['contractAddress']?.toString(),
      txHash: json['nftTransferHash']?.toString(),
      chain: 'Polygon',
      isArchived: json['isArchived'] == true,
    );
  }
}
