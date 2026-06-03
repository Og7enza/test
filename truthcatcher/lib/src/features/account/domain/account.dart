/// Plan d'abonnement.
enum Plan { free, premium }

/// Sous-compte rattaché à un compte Premium (partage le pool de photos).
class SubAccount {
  const SubAccount({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;
}

/// Compte utilisateur (plan, quota de photos, sous-comptes).
/// Démo : tout est simulé en mémoire.
class Account {
  const Account({
    this.plan = Plan.free,
    this.quotaUsed = 0,
    this.subAccounts = const [],
  });

  final Plan plan;
  final int quotaUsed;
  final List<SubAccount> subAccounts;

  bool get isPremium => plan == Plan.premium;

  /// Pool de photos selon le plan.
  int get quotaTotal => isPremium ? 100 : 5;
  int get quotaRemaining => (quotaTotal - quotaUsed).clamp(0, quotaTotal);
  double get quotaFraction =>
      quotaTotal == 0 ? 0 : (quotaUsed / quotaTotal).clamp(0.0, 1.0);

  /// Nombre maximum de sous-comptes (Premium uniquement).
  int get maxSubAccounts => isPremium ? 5 : 0;
  bool get canAddSubAccount => subAccounts.length < maxSubAccounts;

  Account copyWith({
    Plan? plan,
    int? quotaUsed,
    List<SubAccount>? subAccounts,
  }) =>
      Account(
        plan: plan ?? this.plan,
        quotaUsed: quotaUsed ?? this.quotaUsed,
        subAccounts: subAccounts ?? this.subAccounts,
      );
}
