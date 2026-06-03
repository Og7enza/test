import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/labeled_value.dart';
import '../domain/capture_draft.dart';

/// Récapitulatif de la capture (image tamponnée + métadonnées) avant paiement.
class PreviewConfirmScreen extends StatefulWidget {
  const PreviewConfirmScreen({required this.draft, super.key});

  final CaptureDraft draft;

  @override
  State<PreviewConfirmScreen> createState() => _PreviewConfirmScreenState();
}

class _PreviewConfirmScreenState extends State<PreviewConfirmScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
    context.push(
      '/payment',
      extra: widget.draft.copyWith(name: _nameController.text),
    );
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
          const SizedBox(height: 8),
          const Text(
            'Le matricule est déjà incrusté sur la photo ci-dessus.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                    label: 'Empreinte SHA-256 (image originale)',
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
            onPressed: _continue,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continuer'),
          ),
        ],
      ),
    );
  }
}
