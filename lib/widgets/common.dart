export '../core/theme.dart' show AppCard;
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          colors: [kPrimary, kAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Icon(Icons.qr_code_2_rounded, color: Colors.white, size: size * 0.6),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
}

IconData categoryIcon(String c) {
  switch (c) {
    case 'Семинар':
      return Icons.school_rounded;
    case 'Хакатон':
      return Icons.code_rounded;
    case 'Мастер-класс':
      return Icons.build_rounded;
    case 'Встреча':
      return Icons.groups_rounded;
    default:
      return Icons.mic_rounded;
  }
}

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  const EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final taken = event.registered;
    final mine = appState.myRegistrationFor(event.id) != null;
    final past = event.date.isBefore(DateTime.now());
    return AppCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Icon(categoryIcon(event.category), color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(fmtDateTime(event.date), style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    Text(event.location, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      _Tag('$taken/${event.capacity} мест', cs.secondaryContainer),
                      _Tag(event.category, Colors.grey.shade200),
                      if (mine) _Tag('Вы записаны', Colors.green.shade100),
                      if (past) _Tag('Прошло', Colors.orange.shade100),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );
}
