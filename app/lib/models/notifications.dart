import 'dart:convert';

import 'package:flutter/foundation.dart';

class Notifications {
  final String id;
  final String userId;
  final int type;
  final DateTime date;
  final String title;
  final String message;
  final String? matricule;
  final Map? data;
  bool isArchived;

  Notifications({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.matricule,
    required this.data,
    required this.date,
    required this.isArchived,
  });

  Notifications copyWith({
    String? id,
    String? userId,
    int? type,
    String? title,
    String? message,
    String? matricule,
    Map? data,
    bool? isArchived,
    DateTime? date,
  }) {
    return Notifications(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      matricule: matricule ?? this.matricule,
      data: data ?? this.data,
      isArchived: isArchived ?? this.isArchived,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'matricule': matricule,
      'data': data,
      'isArchived': isArchived,
      'date': date,
    };
  }

  factory Notifications.fromMap(Map<String, dynamic> map) {
    return Notifications(
      id: map['_id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type']?.toInt() ?? 0,
      title: map['title'] ?? '',
      isArchived: map['isArchived'] ?? false,
      message: map['message'] ?? '',
      date: DateTime.parse(map['date'] ?? ''),
      matricule: map['matricule'] ?? '',
      data: Map.from(map['data'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory Notifications.fromJson(String source) =>
      Notifications.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Notifications(id: $id, userId: $userId, type: $type, title: $title, message: $message, matricule: $matricule, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Notifications &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.isArchived == isArchived &&
        other.matricule == matricule &&
        mapEquals(other.data, data);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        title.hashCode ^
        message.hashCode ^
        matricule.hashCode ^
        isArchived.hashCode ^
        data.hashCode;
  }
}
