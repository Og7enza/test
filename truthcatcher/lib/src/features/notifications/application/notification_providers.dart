import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_notification.dart';

/// Liste des notifications (données de démo en mémoire).
final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);

/// Nombre de notifications non lues (pour le badge).
final unreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (items) => items.where((n) => !n.read).length,
    orElse: () => 0,
  );
});

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _seed();
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull ?? [];
    state = AsyncData([for (final n in current) n.copyWith(read: true)]);
  }

  List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        kind: NotificationKind.mint,
        title: 'Preuve certifiée',
        body: 'Votre photo « Compteur kilométrique » a été certifiée et mintée.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: 'n2',
        kind: NotificationKind.transfer,
        title: 'NFT transféré',
        body: 'Le NFT TC-DEMO-0002-BBBB a été transféré avec succès.',
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        read: true,
      ),
      AppNotification(
        id: 'n3',
        kind: NotificationKind.system,
        title: 'Bienvenue sur TruthCatcher',
        body: 'Capturez votre première preuve infalsifiable dès maintenant.',
        createdAt: now.subtract(const Duration(days: 3)),
        read: true,
      ),
    ];
  }
}
