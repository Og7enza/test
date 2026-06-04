import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/file_image.dart';
import '../application/certificate_providers.dart';
import '../domain/certificate.dart';

/// Galerie des preuves — grille « masonry » (tuiles de hauteurs variées) avec
/// transition Hero vers le détail, dans l'esprit de l'app d'origine.
class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(certificatesProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          async.maybeWhen(
            data: (items) => 'Galerie (${items.length})',
            orElse: () => 'Galerie',
          ),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (items) {
          if (items.isEmpty) return const _EmptyGallery();
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(certificatesProvider.notifier).refresh(),
            child: MasonryGridView.count(
              physics: const AlwaysScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: items.length,
              itemBuilder: (context, i) =>
                  _GalleryTile(certificate: items[i], index: i),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.certificate, required this.index});

  final Certificate certificate;
  final int index;

  // Ratios variés -> hauteurs de tuiles variées (effet masonry).
  static const List<double> _ratios = [0.82, 1.25, 1.5, 0.95, 1.1, 0.78];

  @override
  Widget build(BuildContext context) {
    final c = certificate;
    final ratio = _ratios[index % _ratios.length];
    return GestureDetector(
      onTap: () => context.push('/certificate/${c.matricule}', extra: c),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Hero(
              tag: 'cert-${c.matricule}',
              child: AspectRatio(
                aspectRatio: ratio,
                child: _TileImage(path: c.localImagePath, url: c.imageUrl),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryDark.withOpacity(0.0),
                      AppColors.primaryDark.withOpacity(0.78),
                    ],
                  ),
                ),
                child: Text(
                  c.matricule,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (c.isMinted)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.verified, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}

class _TileImage extends StatelessWidget {
  const _TileImage({this.path, this.url});

  final String? path;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final local = localFileImage(path);
    if (local != null) return local;
    if (url != null && url!.isNotEmpty) {
      return Image.network(
        url!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(color: AppColors.primary.withOpacity(0.08)),
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primary.withOpacity(0.08),
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.textMuted),
        ),
      );
    }
    return Container(
      color: AppColors.primary.withOpacity(0.08),
      child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.collections_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Votre galerie est prête à prendre vie',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Capturez votre première preuve avec le bouton appareil photo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
