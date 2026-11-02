import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'event_form_screen.dart';
import 'ticket_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({required this.eventId});

  Future<void> _register(BuildContext context) async {
    final err = await appState.registerForEvent(eventId);
    if (!context.mounted) return;
    if (err != null) {
      showSnack(context, err, error: true);
    } else {
      showSnack(context, 'Вы зарегистрированы! QR-билет доступен ниже.');
    }
  }

  Future<void> _cancel(BuildContext context, Registration reg) async {
    final ok = await _confirm(context, 'Отменить регистрацию?', 'Ваш QR-билет станет недействительным.');
    if (ok != true) return;
    final err = await appState.cancelRegistration(reg.id);
    if (context.mounted) showSnack(context, err ?? 'Регистрация отменена', error: err != null);
  }

  Future<void> _delete(BuildContext context, Event e) async {
    final ok = await _confirm(context, 'Удалить мероприятие?', 'Будут удалены и все регистрации участников.');
    if (ok != true) return;
    final err = await appState.deleteEvent(e.id);
    if (!context.mounted) return;
    if (err != null) {
      showSnack(context, err, error: true);
      return;
    }
    Navigator.of(context).pop();
    showSnack(context, 'Мероприятие удалено');
  }

  Future<bool?> _confirm(BuildContext context, String title, String text) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Да'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final e = appState.eventById(eventId);
        if (e == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.event_busy, text: 'Мероприятие удалено'));
        }
        final isOwner = appState.isOrganizer && e.organizerId == appState.currentUser?.id;
        final regs = appState.registrationsOf(e.id);
        final myReg = appState.myRegistrationFor(e.id);
        final full = e.registered >= e.capacity;
        final cs = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Мероприятие'),
            actions: [
              if (isOwner) ...[
                IconButton(
                  tooltip: 'Редактировать',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => EventFormScreen(event: e))),
                ),
                IconButton(
                  tooltip: 'Удалить',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(context, e),
                ),
              ],
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Chip(
                      avatar: Icon(categoryIcon(e.category), size: 18),
                      label: Text(e.category),
                      backgroundColor: cs.primaryContainer,
                      side: BorderSide.none,
                    ),
                    const SizedBox(height: 8),
                    Text(e.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 14),
                    _Info(Icons.calendar_month, fmtDateTime(e.date)),
                    _Info(Icons.place, e.location),
                    _Info(Icons.people, 'Занято ${e.registered} из ${e.capacity} мест'),
                    if (e.organizerName.isNotEmpty) _Info(Icons.badge, 'Организатор: ${e.organizerName}'),
                    if (e.description.isNotEmpty) ...[
                      const Divider(height: 28),
                      Text(e.description, style: const TextStyle(height: 1.4)),
                    ],
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              if (!appState.isOrganizer) ...[
                if (myReg == null)
                  FilledButton.icon(
                    onPressed: full ? null : () => _register(context),
                    icon: const Icon(Icons.how_to_reg),
                    label: Text(full ? 'Мест нет' : 'Зарегистрироваться'),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => TicketScreen(registrationId: myReg.id))),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('Показать QR-билет'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: () => _cancel(context, myReg), child: const Text('Отменить регистрацию')),
                ],
              ],
              if (isOwner) ...[
                SectionTitle(
                  'Участники (${regs.length})',
                  trailing: Text('Пришло: ${appState.checkedInCount(e.id)}',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700)),
                ),
                if (regs.isEmpty)
                  const EmptyState(icon: Icons.group_off, text: 'Пока никто не зарегистрировался')
                else
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < regs.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          _ParticipantTile(reg: regs[i]),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Info(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ]),
      );
}

class _ParticipantTile extends StatelessWidget {
  final Registration reg;
  const _ParticipantTile({required this.reg});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text((reg.userName.isEmpty ? '?' : reg.userName).characters.first.toUpperCase())),
      title: Text(reg.userName.isEmpty ? 'Неизвестный' : reg.userName),
      subtitle: Text(
        reg.checkedIn ? 'Отмечен в ${fmtTime(reg.checkedInAt!)} · ${reg.code}' : 'Код ${reg.code} · не пришёл',
      ),
      trailing: IconButton(
        tooltip: reg.checkedIn ? 'Снять отметку' : 'Отметить вручную',
        icon: Icon(
          reg.checkedIn ? Icons.check_circle : Icons.radio_button_unchecked,
          color: reg.checkedIn ? Colors.green : Colors.grey,
        ),
        onPressed: () => appState.toggleCheckIn(reg.id),
      ),
    );
  }
}
