import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

/// Список мероприятий с поиском и фильтрацией по категории.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _query = '';
  String? _category;
  bool _hidePast = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final org = appState.isOrganizer;
        final now = DateTime.now();
        final q = _query.trim().toLowerCase();
        final events = (org ? appState.myEvents : appState.allEvents).where((e) {
          if (_category != null && e.category != _category) return false;
          if (_hidePast && e.date.isBefore(now)) return false;
          if (q.isEmpty) return true;
          return e.title.toLowerCase().contains(q) ||
              e.location.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          appBar: AppBar(title: Text(org ? 'Мои мероприятия' : 'Мероприятия')),
          floatingActionButton: org
              ? FloatingActionButton.extended(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EventFormScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('Создать'),
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Поиск по названию, месту, описанию',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _query = '')),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Предстоящие'),
                        selected: _hidePast,
                        onSelected: (v) => setState(() => _hidePast = v),
                      ),
                    ),
                    ...[null, ...eventCategories].map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c ?? 'Все'),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                        )),
                  ],
                ),
              ),
              Expanded(
                child: events.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off,
                        text: org && appState.myEvents.isEmpty
                            ? 'У вас пока нет мероприятий.\nНажмите «Создать».'
                            : 'Ничего не найдено')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => EventCard(
                          event: events[i],
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: events[i].id))),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
