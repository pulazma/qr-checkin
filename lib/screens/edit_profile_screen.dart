import 'package:flutter/material.dart';

import '../core/utils.dart';
import '../services/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: appState.currentUser!.name);
  late final _phone = TextEditingController(text: appState.currentUser!.phone);
  late final _org = TextEditingController(text: appState.currentUser!.organization);

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _org.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final err = await appState.updateProfile(name: _name.text, phone: _phone.text, organization: _org.text);
    if (!mounted) return;
    if (err != null) {
      showSnack(context, err, error: true);
      return;
    }
    showSnack(context, 'Профиль обновлён');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование профиля')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'ФИО', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) {
                      final r = Validators.required(v, 'ФИО');
                      if (r != null) return r;
                      return v!.trim().length < 3 ? 'Слишком короткое имя' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: appState.currentUser!.email,
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Email (нельзя изменить)', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Телефон', prefixIcon: Icon(Icons.phone_outlined)),
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _org,
                    decoration: const InputDecoration(labelText: 'Организация', prefixIcon: Icon(Icons.business_outlined)),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: _save, child: const Text('Сохранить')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
