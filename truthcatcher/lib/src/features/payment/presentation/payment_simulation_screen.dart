import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../capture/domain/capture_draft.dart';
import '../../certificate/application/certificate_providers.dart';
import '../../coupon/application/coupon_providers.dart';
import '../../coupon/domain/coupon.dart';
import '../application/payment_providers.dart';

/// Étape de paiement **simulée** (démo) : coupon optionnel, faux paiement, puis
/// certification (hash + matricule + mint NFT simulé).
class PaymentSimulationScreen extends ConsumerStatefulWidget {
  const PaymentSimulationScreen({required this.draft, super.key});

  final CaptureDraft draft;

  @override
  ConsumerState<PaymentSimulationScreen> createState() =>
      _PaymentSimulationScreenState();
}

class _PaymentSimulationScreenState
    extends ConsumerState<PaymentSimulationScreen> {
  final _couponController = TextEditingController();
  Coupon? _coupon;
  bool _couponBusy = false;
  bool _busy = false;
  String _step = '';

  double get _basePrice => AppConfig.demoMintPrice;
  double get _finalPrice => _coupon?.apply(_basePrice) ?? _basePrice;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty || _couponBusy) return;
    setState(() => _couponBusy = true);
    try {
      final coupon = await ref.read(couponServiceProvider).verify(code);
      if (!mounted) return;
      setState(() => _coupon = coupon);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            coupon == null
                ? 'Coupon invalide'
                : 'Coupon appliqué : -${coupon.percentOff}%',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _couponBusy = false);
    }
  }

  Future<void> _payAndCertify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _step = 'Paiement (simulation)…';
    });
    try {
      await ref.read(paymentServiceProvider).pay(
            amount: _finalPrice,
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Échec : $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = AppConfig.demoCurrency;
    final hasCoupon = _coupon != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (hasCoupon)
                    Text(
                      '${_basePrice.toStringAsFixed(2)} $cur',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textMuted,
                      ),
                    ),
                  Text(
                    '${_finalPrice.toStringAsFixed(2)} $cur',
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Coupon (ex. DEMO10)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _couponBusy ? null : _applyCoupon,
                child: _couponBusy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Appliquer'),
              ),
            ],
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
          const SizedBox(height: 24),
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
                  Text(_step,
                      style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          FilledButton.icon(
            onPressed: _busy ? null : _payAndCertify,
            icon: const Icon(Icons.lock_outline),
            label: Text('Payer ${_finalPrice.toStringAsFixed(2)} $cur (simulation)'),
          ),
        ],
      ),
    );
  }
}
