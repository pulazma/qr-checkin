import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../models/models.dart';
import '../services/app_state.dart';

/// Создание и редактирование мероприятия (Create / Update).
class EventFormScreen extends StatefulWidget {
  final Event? event;
  const EventFormScreen({this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.event?.title ?? '');
  late final _desc = TextEditingController(text: widget.event?.description ?? '');
  late final _location = TextEditingController(text: widget.event?.location ?? '');
  late final _capacity = TextEditingController(text: '${widget.event?.capacity ?? 50}');
  late String _category = widget.event?.category ?? eventCategories.first;
  late DateTime _date = widget.event?.date ?? DateTime.now().add(const Duration(days: 7, hours: 1));

  bool get _editing => widget.event != null;

  @override
  void dispose() {
    for (final c in [_title, _desc, _location, _capacity]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (t != null) setState(() => _date = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final capacity = int.parse(_capacity.text.trim());
    if (_editing) {
      final e = widget.event!;
      final err = await appState.updateEvent(Event(
        id: e.id,
        title: _title.text.trim(),
        description: _desc.text.trim(),
        location: _location.text.trim(),
        category: _category,
        date: _date,
        capacity: capacity,
        organizerId: e.organizerId,
      ));
      if (!mounted) return;
      if (err != null) {
        showSnack(context, err, error: true);
        return;
      }
      showSnack(context, 'Изменения сохранены');
    } else {
      final err = await appState.addEvent(
        title: _title.text,
        description: _desc.text,
        location: _location.text,
        category: _category,
        date: _date,
        capacity: capacity,
      );
      if (!mounted) return;
      if (err != null) {
        showSnack(context, err, error: true);
        return;
      }
      showSnack(context, 'Мероприятие создано');
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Редактирование' : 'Новое мероприятие')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Название *'),
                      validator: (v) => Validators.required(v, 'Название'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Категория'),
                      items: eventCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _category = v ?? _category),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _location,
                      decoration: const InputDecoration(labelText: 'Место проведения *', prefixIcon: Icon(Icons.place_outlined)),
                      validator: (v) => Validators.required(v, 'Место'),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(fmtDate(_date)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(fmtTime(_date)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Количество мест *', prefixIcon: Icon(Icons.people_outline)),
                      validator: Validators.positiveInt,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _desc,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Описание', alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _save, child: Text(_editing ? 'Сохранить' : 'Создать')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
