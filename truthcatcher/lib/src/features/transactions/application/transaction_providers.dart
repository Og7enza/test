import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_transaction.dart';

/// Historique des transactions (données de démo en mémoire).
final transactionsProvider =
    FutureProvider<List<AppTransaction>>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));
  final now = DateTime.now();
  return [
    AppTransaction(
      id: 't1',
      type: TxType.mint,
      amount: 2.99,
      currency: 'EUR',
      createdAt: now.subtract(const Duration(hours: 2)),
      matricule: 'TC-DEMO-0001-AAAA',
    ),
    AppTransaction(
      id: 't2',
      type: TxType.transfer,
      amount: 4.99,
      currency: 'EUR',
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      matricule: 'TC-DEMO-0002-BBBB',
    ),
    AppTransaction(
      id: 't3',
      type: TxType.mint,
      amount: 2.99,
      currency: 'EUR',
      createdAt: now.subtract(const Duration(days: 4)),
      matricule: 'TC-DEMO-0003-CCCC',
    ),
  ];
});
