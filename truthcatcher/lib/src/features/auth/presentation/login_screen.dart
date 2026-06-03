import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../application/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      // La redirection du routeur gère la navigation après connexion.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authStateProvider.notifier);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.verified, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TruthCatcher',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Connectez-vous pour certifier vos photos',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec('Email', Icons.mail_outline),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: _dec('Mot de passe', Icons.lock_outline),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/reset'),
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => auth.signInWithEmail(
                        _email.text.trim(),
                        _password.text,
                      )),
              child: _busy ? const _Spinner() : const Text('Se connecter'),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ou', style: TextStyle(color: AppColors.textMuted)),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(auth.signInWithGoogle),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Continuer avec Google'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(auth.signInWithApple),
              icon: const Icon(Icons.apple),
              label: const Text('Continuer avec Apple'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pas encore de compte ?'),
                TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text("S'inscrire"),
                ),
              ],
            ),
            const Center(
              child: Text(
                'Démo : tout email / mot de passe fonctionne.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      );
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
}
