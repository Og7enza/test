import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_image.dart';
import '../../../core/utils/formatters.dart';
import '../../account/application/account_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../certificate/application/certificate_providers.dart';
import '../../certificate/domain/certificate.dart';
import '../../notifications/application/notification_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final certs = ref.watch(certificatesProvider);
    final unread = ref.watch(unreadCountProvider);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 44,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset('assets/branding/tc_icon.png', height: 28),
        ),
        title: Text('Bonjour, ${user?.name ?? 'invité'}'),
        actions: [
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _QuotaDashboard(),
          const SizedBox(height: 24),
          const Text(
            'Preuves récentes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          certs.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Erreur : $e'),
            data: (items) => items.isEmpty
                ? const _EmptyHint()
                : Column(
                    children: items
                        .take(4)
                        .map((c) => _RecentTile(certificate: c))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QuotaDashboard extends ConsumerWidget {
  const _QuotaDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acc = ref.watch(accountProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PlanBadge(isPremium: acc.isPremium),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/premium'),
                child: Text(acc.isPremium ? 'Gérer' : 'Passer Premium'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${acc.quotaUsed}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              Text(
                ' / ${acc.quotaTotal} photos',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: acc.quotaFraction,
              minHeight: 10,
              backgroundColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${acc.quotaRemaining} restantes',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (acc.isPremium && acc.subAccounts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.group_outlined,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${acc.subAccounts.length}/5 sous-comptes partagent ce pool',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPremium ? AppColors.primary : AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.workspace_premium : Icons.person_outline,
            size: 16,
            color: isPremium ? Colors.white : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            isPremium ? 'PREMIUM' : 'FREE',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: isPremium ? Colors.white : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context) {
    final c = certificate;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push('/certificate/${c.matricule}', extra: c),
        leading: _Thumb(path: c.localImagePath, url: c.imageUrl),
        title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          c.matricule,
          style: const TextStyle(
            fontFamily: 'monospace',
            color: AppColors.primary,
          ),
        ),
        trailing: Text(
          formatDateTime(c.certifiedAt).split(' · ').first,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.path, this.url});

  final String? path;
  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    Widget child;
    final local = localFileImage(path, width: size, height: size);
    if (local != null) {
      child = local;
    } else if (url != null && url!.isNotEmpty) {
      child = Image.network(url!, width: size, height: size, fit: BoxFit.cover);
    } else {
      child = Container(
        width: size,
        height: size,
        color: AppColors.background,
        child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
      );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(10), child: child);
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Text(
        'Aucune preuve encore. Touchez le bouton appareil photo en bas '
        'pour certifier votre première photo.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}
