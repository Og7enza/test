import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_payment_service.dart';
import '../domain/payment_service.dart';

/// Service de paiement. Mock en démo — à remplacer par Stripe/IAP via backend.
final paymentServiceProvider =
    Provider<PaymentService>((ref) => const MockPaymentService());
