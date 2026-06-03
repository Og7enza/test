import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../application/account_providers.dart';
import '../domain/account.dart';

class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider);
    final notifier = ref.read(accountProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.brandGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 48),
                const SizedBox(height: 8),
                const Text(
                  'TruthCatcher Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  account.isPremium ? 'Plan actif' : '9,99 € / mois (démo)',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _Benefit(
            icon: Icons.photo_library_outlined,
            title: '100 photos',
            text: 'Un pool de 100 certifications (au lieu de 5).',
          ),
          const _Benefit(
            icon: Icons.group_outlined,
            title: '5 sous-comptes',
            text: 'Partagez votre pool avec jusqu’à 5 comptes liés.',
          ),
          const _Benefit(
            icon: Icons.tune,
            title: 'Confidentialité granulaire',
            text: 'Choisissez à la prise les infos partagées (adresse, GPS, heure).',
          ),
          const _Benefit(
            icon: Icons.lock_outline,
            title: 'Privé / Public',
            text: 'Définissez la visibilité et qui peut accéder à vos preuves.',
          ),
          const SizedBox(height: 16),
          if (!account.isPremium)
            FilledButton.icon(
              onPressed: () {
                notifier.upgrade();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bienvenue en Premium (démo) ✨')),
                );
              },
              icon: const Icon(Icons.workspace_premium),
              label: const Text('Passer Premium (démo)'),
            )
          else ...[
            _SubAccountsSection(account: account),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: notifier.downgrade,
              icon: const Icon(Icons.arrow_downward),
              label: const Text('Revenir au plan Free'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(text, style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubAccountsSection extends ConsumerWidget {
  const _SubAccountsSection({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Sous-comptes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                Text('${account.subAccounts.length}/5',
                    style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 8),
            if (account.subAccounts.isEmpty)
              const Text('Aucun sous-compte lié.',
                  style: TextStyle(color: AppColors.textMuted)),
            ...account.subAccounts.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(
                    (s.name.isNotEmpty ? s.name[0] : '?').toUpperCase(),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                title: Text(s.name),
                subtitle: Text(s.email),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () =>
                      ref.read(accountProvider.notifier).removeSubAccount(s.id),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (account.canAddSubAccount)
              OutlinedButton.icon(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Ajouter un sous-compte'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final res = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _AddSubAccountDialog(),
    );
    if (res == null) return;
    final err = ref
        .read(accountProvider.notifier)
        .addSubAccount(name: res.$1, email: res.$2);
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    }
  }
}

class _AddSubAccountDialog extends StatefulWidget {
  const _AddSubAccountDialog();

  @override
  State<_AddSubAccountDialog> createState() => _AddSubAccountDialogState();
}

class _AddSubAccountDialogState extends State<_AddSubAccountDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouveau sous-compte'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (_email.text.trim().isEmpty) return;
            Navigator.pop(context, (_name.text, _email.text));
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
