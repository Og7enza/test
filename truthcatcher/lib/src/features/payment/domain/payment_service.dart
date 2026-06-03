/// Résultat d'un paiement (simulé en démo).
class PaymentResult {
  const PaymentResult({
    required this.transactionId,
    required this.amount,
    required this.currency,
  });

  final String transactionId;
  final double amount;
  final String currency;
}

/// Contrat de paiement.
///
/// En démo : `MockPaymentService` (aucun débit réel). Plus tard : Stripe /
/// achats in-app via le backend (voir docs/BACKEND_API.md §6).
abstract interface class PaymentService {
  Future<PaymentResult> pay({required double amount, required String currency});
}
