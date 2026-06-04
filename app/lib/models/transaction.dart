import 'dart:convert';

import 'package:intl/intl.dart';

class Transaction {
  final String id;
  final String userId;
  final DateTime date;
  final String matricule;
  final String transactionId;
  final String stripeTransactionId;
  final String currency;
  final double amount;

  Transaction({
    required this.id,
    required this.userId,
    required this.date,
    required this.matricule,
    required this.transactionId,
    required this.stripeTransactionId,
    required this.currency,
    required this.amount,
  });

  Transaction copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? matricule,
    String? transactionId,
    String? stripeTransactionId,
    String? currency,
    double? amount,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      matricule: matricule ?? this.matricule,
      transactionId: transactionId ?? this.transactionId,
      stripeTransactionId: stripeTransactionId ?? this.stripeTransactionId,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'matricule': matricule,
      'transactionId': transactionId,
      'stripeTransactionId': stripeTransactionId,
      'currency': currency,
      'amount': amount,
    };
  }

  factory Transaction.fromMap(Map map) {
    DateFormat gmtFormat =
        DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", "en_US");

    final String today = gmtFormat.format(DateTime.now());
    DateTime date;
    try {
      date = gmtFormat.parse(map['date'] ?? today).toLocal();
    } catch (error) {
      date = DateTime.parse(map['date'] ?? today).toLocal();
    }
    return Transaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      date: date,
      matricule: map['matricule'] ?? '',
      transactionId: map['transactionId'] ?? '',
      stripeTransactionId: map['stripeTransactionId'] ?? '',
      currency: map['currency'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory Transaction.fromJson(String source) =>
      Transaction.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Transaction(id: $id, userId: $userId, date: $date, matricule: $matricule, transactionId: $transactionId, stripeTransactionId: $stripeTransactionId, currency: $currency, amount: $amount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Transaction &&
        other.id == id &&
        other.userId == userId &&
        other.date == date &&
        other.matricule == matricule &&
        other.transactionId == transactionId &&
        other.stripeTransactionId == stripeTransactionId &&
        other.currency == currency &&
        other.amount == amount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        date.hashCode ^
        matricule.hashCode ^
        transactionId.hashCode ^
        stripeTransactionId.hashCode ^
        currency.hashCode ^
        amount.hashCode;
  }
}
