import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'ticket_screen.dart';

/// Мои билеты (для участника).
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final regs = appState.myRegistrations;
        return Scaffold(
          appBar: AppBar(title: const Text('Мои билеты')),
          body: regs.isEmpty
              ? const EmptyState(
                  icon: Icons.confirmation_number_outlined,
                  text: 'У вас пока нет билетов.\nЗарегистрируйтесь на мероприятие во вкладке «События».')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: regs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = regs[i];
                    final e = appState.eventById(r.eventId);
                    if (e == null) return const SizedBox.shrink();
                    return AppCard(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: const Icon(Icons.qr_code_2, size: 40),
                        title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${fmtDateTime(e.date)}\n${r.checkedIn ? "Посещение отмечено" : "Код ${r.code}"}'),
                        isThreeLine: true,
                        trailing: Icon(
                          r.checkedIn ? Icons.verified : Icons.chevron_right,
                          color: r.checkedIn ? Colors.green : null,
                        ),
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => TicketScreen(registrationId: r.id))),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
