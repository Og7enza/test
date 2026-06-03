import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/account.dart';

/// État du compte (plan, quota, sous-comptes). Démo en mémoire.
final accountProvider =
    NotifierProvider<AccountNotifier, Account>(AccountNotifier.new);

class AccountNotifier extends Notifier<Account> {
  @override
  Account build() =>
      // 3 preuves de démo sont déjà présentes -> 3 photos consommées.
      const Account(plan: Plan.free, quotaUsed: 3);

  void upgrade() => state = state.copyWith(plan: Plan.premium);

  void downgrade() =>
      state = state.copyWith(plan: Plan.free, subAccounts: const []);

  void consumeQuota() => state = state.copyWith(quotaUsed: state.quotaUsed + 1);

  /// Ajoute un sous-compte. Renvoie un message d'erreur, ou `null` si OK.
  String? addSubAccount({required String name, required String email}) {
    if (!state.canAddSubAccount) {
      return 'Limite de ${state.maxSubAccounts} sous-comptes atteinte.';
    }
    final sub = SubAccount(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? email.trim() : name.trim(),
      email: email.trim(),
    );
    state = state.copyWith(subAccounts: [...state.subAccounts, sub]);
    return null;
  }

  void removeSubAccount(String id) => state = state.copyWith(
        subAccounts: state.subAccounts.where((s) => s.id != id).toList(),
      );
}
