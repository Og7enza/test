import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/premium_screen.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/reset_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/capture/domain/capture_draft.dart';
import '../../features/capture/presentation/capture_screen.dart';
import '../../features/capture/presentation/preview_confirm_screen.dart';
import '../../features/certificate/domain/certificate.dart';
import '../../features/certificate/presentation/certificate_detail_screen.dart';
import '../../features/onboarding/application/onboarding_providers.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/payment/presentation/payment_simulation_screen.dart';
import '../../features/profile/presentation/archive_screen.dart';
import '../../features/profile/presentation/info_page_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/legal_texts.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../shared/home_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final loggedIn = ref.watch(authStateProvider) != null;
  final onboardingSeen = ref.watch(onboardingSeenProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final atOnboarding = loc == '/onboarding';
      final atAuth =
          loc == '/login' || loc == '/signup' || loc == '/reset';

      if (!onboardingSeen) {
        return atOnboarding ? null : '/onboarding';
      }
      if (!loggedIn) {
        return atAuth ? null : '/login';
      }
      if (atOnboarding || atAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/reset',
        builder: (context, state) => const ResetScreen(),
      ),
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
        path: '/payment',
        builder: (context, state) =>
            PaymentSimulationScreen(draft: state.extra! as CaptureDraft),
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
      GoRoute(
        path: '/profile/help',
        builder: (context, state) =>
            const InfoPageScreen(title: 'Aide', body: kHelpText),
      ),
      GoRoute(
        path: '/profile/privacy',
        builder: (context, state) => const InfoPageScreen(
          title: 'Confidentialité',
          body: kPrivacyText,
        ),
      ),
      GoRoute(
        path: '/profile/terms',
        builder: (context, state) => const InfoPageScreen(
          title: 'Conditions générales',
          body: kTermsText,
        ),
      ),
      GoRoute(
        path: '/profile/archive',
        builder: (context, state) => const ArchiveScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
    ],
  );
});
