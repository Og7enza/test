import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_image.dart';
import '../../../core/utils/formatters.dart';
import '../../certificate/application/certificate_providers.dart';
import '../../certificate/domain/certificate.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(archivedCertificatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Archives')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aucune preuve archivée.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _ArchivedTile(certificate: items[i]),
          );
        },
      ),
    );
  }
}

class _ArchivedTile extends ConsumerWidget {
  const _ArchivedTile({required this.certificate});

  final Certificate certificate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = certificate;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: _Thumb(path: c.localImagePath, url: c.imageUrl),
        title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${c.matricule}\n${formatDateTime(c.certifiedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.unarchive_outlined),
          tooltip: 'Désarchiver',
          onPressed: () async {
            await ref
                .read(certificationRepositoryProvider)
                .unarchive(c.matricule);
            ref.invalidate(archivedCertificatesProvider);
            await ref.read(certificatesProvider.notifier).refresh();
          },
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
