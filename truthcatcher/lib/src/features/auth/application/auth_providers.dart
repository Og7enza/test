import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_auth_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_service.dart';

final authServiceProvider =
    Provider<AuthService>((ref) => const MockAuthService());

/// État d'authentification courant (`null` = déconnecté).
final authStateProvider =
    NotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

class AuthNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  AuthService get _service => ref.read(authServiceProvider);

  Future<void> signInWithEmail(String email, String password) async {
    state = await _service.signInWithEmail(email, password);
  }

  Future<void> signInWithGoogle() async {
    state = await _service.signInWithGoogle();
  }

  Future<void> signInWithApple() async {
    state = await _service.signInWithApple();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = await _service.signUp(name: name, email: email, password: password);
  }

  Future<void> sendPasswordReset(String email) =>
      _service.sendPasswordReset(email);

  Future<void> signOut() async {
    await _service.signOut();
    state = null;
  }

  Future<void> deleteAccount() async {
    await _service.deleteAccount();
    state = null;
  }
}
