import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';

/// Электронный билет с QR-кодом.
class TicketScreen extends StatelessWidget {
  final String registrationId;
  const TicketScreen({required this.registrationId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final reg = appState.registrationById(registrationId);
        final event = reg == null ? null : appState.eventById(reg.eventId);
        if (reg == null || event == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.error_outline, text: 'Билет не найден'));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('QR-билет')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(children: [
                      Text(event.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('${fmtDateTime(event.date)}\n${event.location}',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kPrimary.withOpacity(0.25), width: 2),
                        ),
                        child: QrImageView(
                          data: reg.qrPayload,
                          version: QrVersions.auto,
                          size: 240,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(reg.code,
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 6)),
                      Text('Резервный код для ручного ввода', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const Divider(height: 32),
                      Row(children: [
                        const Icon(Icons.person_outline),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reg.userName)),
                      ]),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: reg.checkedIn ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(reg.checkedIn ? Icons.verified : Icons.hourglass_bottom,
                              color: reg.checkedIn ? Colors.green.shade700 : Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Text(
                            reg.checkedIn ? 'Вход выполнен в ${fmtTime(reg.checkedInAt!)}' : 'Ожидает проверки на входе',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
