import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/labeled_value.dart';
import '../../account/application/account_providers.dart';
import '../domain/capture_draft.dart';

/// Récapitulatif de la capture (image tamponnée + métadonnées) avant paiement,
/// avec réglages de confidentialité pour les comptes Premium.
class PreviewConfirmScreen extends ConsumerStatefulWidget {
  const PreviewConfirmScreen({required this.draft, super.key});

  final CaptureDraft draft;

  @override
  ConsumerState<PreviewConfirmScreen> createState() =>
      _PreviewConfirmScreenState();
}

class _PreviewConfirmScreenState extends ConsumerState<PreviewConfirmScreen> {
  final _nameController = TextEditingController();
  bool _shareAddress = true;
  bool _shareCoordinates = true;
  bool _shareTimestamp = true;
  bool _isPublic = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
    context.push(
      '/payment',
      extra: widget.draft.copyWith(
        name: _nameController.text,
        shareAddress: _shareAddress,
        shareCoordinates: _shareCoordinates,
        shareTimestamp: _shareTimestamp,
        isPublic: _isPublic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final isPremium = ref.watch(accountProvider).isPremium;
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
                    value: shortenHash(d.sha256Hex),
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
          const SizedBox(height: 12),
          if (isPremium) _privacyCard() else _premiumLockCard(),
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

  Widget _privacyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.tune, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Confidentialité (Premium)',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              dense: true,
              value: _shareAddress,
              onChanged: (v) => setState(() => _shareAddress = v),
              title: const Text('Partager l’adresse'),
            ),
            SwitchListTile(
              dense: true,
              value: _shareCoordinates,
              onChanged: (v) => setState(() => _shareCoordinates = v),
              title: const Text('Partager les coordonnées GPS'),
            ),
            SwitchListTile(
              dense: true,
              value: _shareTimestamp,
              onChanged: (v) => setState(() => _shareTimestamp = v),
              title: const Text('Partager l’horodatage précis'),
            ),
            const Divider(height: 8),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Text('Visibilité'),
                  const Spacer(),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.lock_outline),
                        label: Text('Privé'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.public),
                        label: Text('Public'),
                      ),
                    ],
                    selected: {_isPublic},
                    onSelectionChanged: (s) =>
                        setState(() => _isPublic = s.first),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumLockCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Premium : choisissez les infos partagées (adresse, GPS, '
                'heure) et la visibilité de la preuve.',
              ),
            ),
            TextButton(
              onPressed: () => context.push('/premium'),
              child: const Text('Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
