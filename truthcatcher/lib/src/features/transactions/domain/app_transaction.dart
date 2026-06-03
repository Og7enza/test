enum TxType { mint, transfer }

/// Transaction d'achat (modernise l'ancien modèle `transaction`).
class AppTransaction {
  const AppTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.createdAt,
    this.matricule,
    this.status = 'Réussi',
  });

  final String id;
  final TxType type;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final String? matricule;
  final String status;
}
