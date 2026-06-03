import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../capture/domain/capture_draft.dart';
import '../../certificate/application/certificate_providers.dart';
import '../application/payment_providers.dart';

/// Étape de paiement **simulée** (démo) : encaisse un faux paiement puis
/// déclenche la certification (hash + matricule + mint NFT simulé).
class PaymentSimulationScreen extends ConsumerStatefulWidget {
  const PaymentSimulationScreen({required this.draft, super.key});

  final CaptureDraft draft;

  @override
  ConsumerState<PaymentSimulationScreen> createState() =>
      _PaymentSimulationScreenState();
}

class _PaymentSimulationScreenState
    extends ConsumerState<PaymentSimulationScreen> {
  bool _busy = false;
  String _step = '';

  Future<void> _payAndCertify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _step = 'Paiement (simulation)…';
    });
    try {
      await ref.read(paymentServiceProvider).pay(
            amount: AppConfig.demoMintPrice,
            currency: AppConfig.demoCurrency,
          );
      if (!mounted) return;
      setState(() => _step = 'Certification & mint NFT (simulation)…');

      final cert =
          await ref.read(certificatesProvider.notifier).certify(widget.draft);
      if (!mounted) return;
      context.go('/');
      context.push('/certificate/${cert.matricule}', extra: cert);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = AppConfig.demoMintPrice.toStringAsFixed(2);
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.workspace_premium_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Certification + NFT',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$price ${AppConfig.demoCurrency}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Paiement simulé pour la démo — aucun débit réel. '
                      'Le NFT est également simulé.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (_busy)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(_step, style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            FilledButton.icon(
              onPressed: _busy ? null : _payAndCertify,
              icon: const Icon(Icons.lock_outline),
              label: Text('Payer $price ${AppConfig.demoCurrency} (simulation)'),
            ),
          ],
        ),
      ),
    );
  }
}
