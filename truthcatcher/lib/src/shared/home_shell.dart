import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../features/certificate/presentation/gallery_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/verify/presentation/verify_screen.dart';

/// Coquille principale : barre du bas blanche à encoche avec FAB caméra centré
/// (look de l'app d'origine) + onglets Accueil · Galerie · Recherche · Profil.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    GalleryScreen(),
    VerifyScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'capture-fab',
        elevation: 2,
        backgroundColor: Colors.white,
        shape: const StadiumBorder(
          side: BorderSide(color: AppColors.primary, width: 2),
        ),
        onPressed: () => context.push('/capture'),
        child: const Icon(Icons.photo_camera, color: AppColors.primary),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 70,
        color: Colors.white,
        elevation: 10,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, 'Accueil', Icons.home_outlined, Icons.home),
            _navItem(1, 'Galerie', Icons.collections_outlined, Icons.collections),
            const SizedBox(width: 56),
            _navItem(2, 'Recherche', Icons.search, Icons.search),
            _navItem(3, 'Profil', Icons.person_outline, Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, String label, IconData icon, IconData active) {
    final selected = _index == i;
    final color = selected ? AppColors.primary : const Color(0xFFAEAEAE);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (_index != i) {
          HapticFeedback.lightImpact();
          setState(() => _index = i);
        }
      },
      child: SizedBox(
        width: 66,
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? active : icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
