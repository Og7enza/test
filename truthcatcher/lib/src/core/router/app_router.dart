import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/capture/domain/capture_draft.dart';
import '../../features/capture/presentation/capture_screen.dart';
import '../../features/capture/presentation/preview_confirm_screen.dart';
import '../../features/certificate/domain/certificate.dart';
import '../../features/certificate/presentation/certificate_detail_screen.dart';
import '../../shared/home_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const CaptureScreen(),
      ),
      GoRoute(
        path: '/preview',
        builder: (context, state) =>
            PreviewConfirmScreen(draft: state.extra! as CaptureDraft),
      ),
      GoRoute(
        path: '/certificate/:matricule',
        builder: (context, state) => CertificateDetailScreen(
          matricule: state.pathParameters['matricule']!,
          certificate: state.extra as Certificate?,
        ),
      ),
      // Deeplink historique : https://.../nftDetails/{matricule}
      GoRoute(
        path: '/nftDetails/:matricule',
        builder: (context, state) => CertificateDetailScreen(
          matricule: state.pathParameters['matricule']!,
        ),
      ),
    ],
  );
});
