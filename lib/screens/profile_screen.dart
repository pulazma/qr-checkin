import 'package:flutter/material.dart';

import '../models/models.dart';

import '../services/app_state.dart';
import '../widgets/common.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Для доступа к разделам потребуется снова войти.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await appState.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final u = appState.currentUser;
        if (u == null) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Профиль')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Center(
                child: Column(children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: cs.primaryContainer,
                    child: Text(u.name.characters.first.toUpperCase(),
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
                  ),
                  const SizedBox(height: 12),
                  Text(u.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Chip(label: Text(u.role.title), backgroundColor: cs.secondaryContainer, side: BorderSide.none),
                ]),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(children: [
                  _Row(Icons.email_outlined, 'Email', u.email),
                  const Divider(height: 1),
                  _Row(Icons.phone_outlined, 'Телефон', u.phone.isEmpty ? 'Не указан' : u.phone),
                  const Divider(height: 1),
                  _Row(Icons.business_outlined, 'Организация', u.organization.isEmpty ? 'Не указана' : u.organization),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.event,
                    value: appState.isOrganizer
                        ? '${appState.myEvents.length}'
                        : '${appState.myRegistrations.length}',
                    label: appState.isOrganizer ? 'Моих событий' : 'Билетов',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    icon: Icons.verified,
                    value: appState.isOrganizer
                        ? '${appState.totalCheckedInForMyEvents}'
                        : '${appState.myRegistrations.where((r) => r.checkedIn).length}',
                    label: appState.isOrganizer ? 'Гостей отмечено' : 'Посещено',
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                icon: const Icon(Icons.edit),
                label: const Text('Редактировать профиль'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                ),
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Выйти'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      );
}
