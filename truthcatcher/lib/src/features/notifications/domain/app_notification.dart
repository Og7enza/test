enum NotificationKind { mint, transfer, system }

/// Notification in-app (modernise l'ancien modèle `notifications`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.kind = NotificationKind.system,
    this.read = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationKind kind;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        kind: kind,
        read: read ?? this.read,
      );
}
