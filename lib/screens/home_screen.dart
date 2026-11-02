import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tab) onOpenTab;
  const HomeScreen({required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser!;
        final org = appState.isOrganizer;
        final now = DateTime.now();
        final upcoming = (org ? appState.myEvents : appState.allEvents).where((e) => e.date.isAfter(now)).toList();
        final firstName = user.name.split(' ').first;

        return Scaffold(
          appBar: AppBar(title: const Text('QR Check-in')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(colors: [kPrimary, kAccent]),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Привет, $firstName!',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        org
                            ? 'Создавайте мероприятия и отмечайте гостей по QR-коду.'
                            : 'Записывайтесь на мероприятия и получайте QR-билет.',
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 64),
                ]),
              ),
              const SizedBox(height: 14),
              Row(
                children: org
                    ? [
                        Expanded(
                            child: StatCard(
                                icon: Icons.event, value: '${appState.myEvents.length}', label: 'Мероприятий')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.how_to_reg,
                                value: '${appState.totalRegistrationsForMyEvents}',
                                label: 'Регистраций')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.verified,
                                value: '${appState.totalCheckedInForMyEvents}',
                                label: 'Пришло')),
                      ]
                    : [
                        Expanded(
                            child: StatCard(
                                icon: Icons.confirmation_number,
                                value: '${appState.myRegistrations.length}',
                                label: 'Мои билеты')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.event_available, value: '${upcoming.length}', label: 'Предстоит')),
                        const SizedBox(width: 10),
                        Expanded(
                            child: StatCard(
                                icon: Icons.verified,
                                value: '${appState.myRegistrations.where((r) => r.checkedIn).length}',
                                label: 'Посещено')),
                      ],
              ),
              const SectionTitle('Быстрые действия'),
              Row(children: [
                Expanded(
                  child: _Action(
                    icon: org ? Icons.qr_code_scanner : Icons.confirmation_number,
                    label: org ? 'Сканировать' : 'Мои билеты',
                    onTap: () => onOpenTab(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Action(
                    icon: org ? Icons.add_circle_outline : Icons.search,
                    label: org ? 'Создать событие' : 'Найти событие',
                    onTap: () {
                      if (org) {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventFormScreen()));
                      } else {
                        onOpenTab(1);
                      }
                    },
                  ),
                ),
              ]),
              SectionTitle(
                org ? 'Мои ближайшие события' : 'Ближайшие события',
                trailing: TextButton(onPressed: () => onOpenTab(1), child: const Text('Все')),
              ),
              if (upcoming.isEmpty)
                const EmptyState(icon: Icons.event_busy, text: 'Предстоящих мероприятий пока нет')
              else
                ...upcoming.take(3).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: EventCard(
                        event: e,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id))),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(children: [
            Icon(icon, size: 30, color: cs.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}
