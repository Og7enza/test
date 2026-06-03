import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Indique si l'onboarding a été vu (en mémoire pour la démo).
final onboardingSeenProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void complete() => state = true;
}
