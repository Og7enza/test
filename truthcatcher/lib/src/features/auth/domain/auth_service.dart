import 'app_user.dart';

/// Contrat d'authentification.
///
/// En démo : `MockAuthService` (n'importe quel identifiant fonctionne, aucun
/// backend). Plus tard : Firebase Auth (Google/Apple) + `/users/*` du backend.
abstract interface class AuthService {
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
  Future<void> deleteAccount();
}
