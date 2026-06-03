import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/labeled_value.dart';
import '../../certificate/application/certificate_providers.dart';
import '../domain/capture_draft.dart';

/// Récapitulatif de la capture avant certification (titre + métadonnées).
class PreviewConfirmScreen extends ConsumerStatefulWidget {
  const PreviewConfirmScreen({required this.draft, super.key});

  final CaptureDraft draft;

  @override
  ConsumerState<PreviewConfirmScreen> createState() =>
      _PreviewConfirmScreenState();
}

class _PreviewConfirmScreenState extends ConsumerState<PreviewConfirmScreen> {
  final _nameController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _certify() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final cert = await ref.read(certificatesProvider.notifier).certify(
            widget.draft.copyWith(name: _nameController.text),
          );
      if (!mounted) return;
      context.go('/');
      context.push('/certificate/${cert.matricule}', extra: cert);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la certification : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmer la preuve')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: File(d.imagePath).existsSync()
                  ? Image.file(File(d.imagePath), fit: BoxFit.cover)
                  : Container(color: AppColors.background),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Titre / légende',
              hintText: 'Ex. Compteur kilométrique',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  LabeledValue(
                    icon: Icons.fingerprint,
                    label: 'Empreinte SHA-256',
                    value: shortHash(d.sha256Hex),
                    monospace: true,
                  ),
                  LabeledValue(
                    icon: Icons.schedule,
                    label: 'Horodatage (confiance)',
                    value: formatDateTime(d.capturedAt),
                  ),
                  LabeledValue(
                    icon: Icons.place_outlined,
                    label: 'Localisation',
                    value: d.locationLabel.isEmpty
                        ? formatCoords(d.latitude, d.longitude)
                        : '${d.locationLabel}\n'
                            '${formatCoords(d.latitude, d.longitude)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _certify,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_outlined),
            label: Text(_busy ? 'Certification…' : 'Certifier & minter'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Le hash, l\'horodatage et la position sont figés au moment de la '
            'certification.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
