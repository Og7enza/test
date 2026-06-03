import '../domain/payment_service.dart';

/// Paiement simulé pour la démo : patiente brièvement puis renvoie un faux
/// identifiant de transaction. **Aucun débit réel.**
class MockPaymentService implements PaymentService {
  const MockPaymentService();

  @override
  Future<PaymentResult> pay({
    required double amount,
    required String currency,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return PaymentResult(
      transactionId: 'demo_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      currency: currency,
    );
  }
}
