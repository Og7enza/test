import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../application/transaction_providers.dart';
import '../domain/app_transaction.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(transactionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes transactions')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Aucune transaction.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _TxTile(items[i]),
          );
        },
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile(this.tx);

  final AppTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isMint = tx.type == TxType.mint;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Icon(
            isMint ? Icons.verified_outlined : Icons.swap_horiz,
            color: AppColors.primary,
          ),
        ),
        title: Text(isMint ? 'Certification + NFT' : 'Transfert de NFT'),
        subtitle: Text(
          '${tx.matricule ?? ''}\n${formatDateTime(tx.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${tx.amount.toStringAsFixed(2)} ${tx.currency}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              tx.status,
              style: const TextStyle(fontSize: 11, color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }
}
