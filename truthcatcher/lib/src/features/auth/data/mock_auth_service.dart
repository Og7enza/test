import '../domain/app_user.dart';
import '../domain/auth_service.dart';

/// Authentification simulée pour la démo. **Aucun backend, aucun mot de passe
/// réellement vérifié** : tout identifiant non vide ouvre une session.
class MockAuthService implements AuthService {
  const MockAuthService();

  static const String _demoWallet = '0xD3moA11ce0000000000000000000000000C47cher';

  Future<void> get _latency =>
      Future<void>.delayed(const Duration(milliseconds: 700));

  String _nameFromEmail(String email) {
    final local = email.contains('@') ? email.split('@').first : email;
    if (local.isEmpty) return 'Utilisateur';
    return local[0].toUpperCase() + local.substring(1);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    await _latency;
    return AppUser(
      id: 'demo-${email.hashCode}',
      name: _nameFromEmail(email),
      email: email,
      walletAddress: _demoWallet,
    );
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    await _latency;
    return const AppUser(
      id: 'demo-google',
      name: 'Demo Google',
      email: 'demo.google@truthcatcher.app',
      walletAddress: _demoWallet,
    );
  }

  @override
  Future<AppUser> signInWithApple() async {
    await _latency;
    return const AppUser(
      id: 'demo-apple',
      name: 'Demo Apple',
      email: 'demo.apple@truthcatcher.app',
      walletAddress: _demoWallet,
    );
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _latency;
    return AppUser(
      id: 'demo-${email.hashCode}',
      name: name.trim().isEmpty ? _nameFromEmail(email) : name.trim(),
      email: email,
      walletAddress: _demoWallet,
    );
  }

  @override
  Future<void> sendPasswordReset(String email) async => _latency;

  @override
  Future<void> signOut() async => _latency;

  @override
  Future<void> deleteAccount() async => _latency;
}
