import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_image.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/labeled_value.dart';
import '../../capture/domain/location_precision.dart';
import '../application/certificate_providers.dart';
import '../domain/certificate.dart';

/// Détail d'une preuve. Si `certificate` n'est pas fourni (deeplink / recherche),
/// la preuve est résolue à partir du matricule.
class CertificateDetailScreen extends ConsumerWidget {
  const CertificateDetailScreen({
    required this.matricule,
    this.certificate,
    super.key,
  });

  final String matricule;
  final Certificate? certificate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget body;
    if (certificate != null) {
      body = _DetailBody(certificate: certificate!);
    } else {
      final async = ref.watch(verifyMatriculeProvider(matricule));
      body = async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (cert) => cert == null
            ? _NotFound(matricule: matricule)
            : _DetailBody(certificate: cert),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Preuve certifiée')),
      body: body,
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    final c = certificate;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (c.localImagePath != null || (c.imageUrl?.isNotEmpty ?? false))
          Hero(
            tag: 'cert-${c.matricule}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _Image(path: c.localImagePath, url: c.imageUrl),
            ),
          ),
        const SizedBox(height: 16),
        _MatriculeBanner(matricule: c.matricule),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                LabeledValue(
                  icon: Icons.label_outline,
                  label: 'Titre',
                  value: c.name,
                ),
                LabeledValue(
                  icon: Icons.fingerprint,
                  label: 'Empreinte SHA-256',
                  value: c.sha256Hex.isEmpty ? '—' : c.sha256Hex,
                  monospace: true,
                ),
                LabeledValue(
                  icon: Icons.schedule,
                  label: 'Capturé le',
                  value: formatDateTime(c.capturedAt),
                ),
                LabeledValue(
                  icon: Icons.verified_user_outlined,
                  label: 'Certifié le',
                  value: formatDateTime(c.certifiedAt),
                ),
                LabeledValue(
                  icon: Icons.place_outlined,
                  label: 'Localisation partagée',
                  value: _locationText(c),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.token_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.isMinted
                            ? 'NFT — ${c.chain ?? ''}'
                            : 'NFT non minté',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                LabeledValue(
                  icon: Icons.tag,
                  label: 'Token ID',
                  value: c.tokenId ?? '—',
                  monospace: true,
                ),
                LabeledValue(
                  icon: Icons.account_balance_outlined,
                  label: 'Contrat',
                  value:
                      c.contractAddress == null ? '—' : shortenHash(c.contractAddress!),
                  monospace: true,
                ),
                LabeledValue(
                  icon: Icons.receipt_long_outlined,
                  label: 'Transaction',
                  value: c.txHash == null ? '—' : shortenHash(c.txHash!),
                  monospace: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      c.isPublic ? Icons.public : Icons.lock_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.isPublic ? 'Preuve publique' : 'Preuve privée',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      'Loc : ${c.locationPrecision.shortLabel}',
                      c.locationPrecision != LocationPrecision.hidden,
                    ),
                    _chip('Coordonnées GPS', c.shareCoordinates),
                    _chip('Horodatage', c.shareTimestamp),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Share.share(
            'Preuve TruthCatcher\n'
            'Matricule : ${c.matricule}\n'
            'SHA-256 : ${c.sha256Hex}',
            subject: 'Preuve TruthCatcher ${c.matricule}',
          ),
          icon: const Icon(Icons.ios_share),
          label: const Text('Partager la preuve'),
        ),
      ],
    );
  }
}

String _locationText(Certificate c) {
  final loc = c.publicLocation;
  final coords =
      c.shareCoordinates ? formatCoords(c.latitude, c.longitude) : '';
  if (loc.isEmpty && coords.isEmpty) return 'Masquée';
  if (loc.isEmpty) return coords;
  if (coords.isEmpty) return loc;
  return '$loc\n$coords';
}

Widget _chip(String label, bool on) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: on ? AppColors.primary.withOpacity(0.12) : AppColors.background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          on ? Icons.check_circle : Icons.cancel,
          size: 14,
          color: on ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}

class _MatriculeBanner extends StatelessWidget {
  const _MatriculeBanner({required this.matricule});

  final String matricule;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Matricule', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  matricule,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: matricule));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Matricule copié')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Image extends StatelessWidget {
  const _Image({this.path, this.url});

  final String? path;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final local = localFileImage(path);
    if (local != null) return local;
    if (url != null && url!.isNotEmpty) {
      return Image.network(url!, fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.matricule});

  final String matricule;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Aucune preuve trouvée',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Le matricule « $matricule » ne correspond à aucune preuve.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
