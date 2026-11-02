import 'package:flutter/material.dart';

const eventCategories = ['Конференция', 'Семинар', 'Хакатон', 'Мастер-класс', 'Встреча'];

String _two(int n) => n.toString().padLeft(2, '0');

String fmtDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';
String fmtTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
String fmtDateTime(DateTime d) => '${fmtDate(d)}, ${fmtTime(d)}';

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Валидаторы полей форм.
class Validators {
  static String? required(String? v, [String field = 'Поле']) =>
      (v == null || v.trim().isEmpty) ? '$field не заполнено' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Введите email';
    final ok = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(v.trim());
    return ok ? null : 'Некорректный email';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Введите пароль';
    if (v.length < 6) return 'Минимум 6 символов';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // необязательное
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    return (digits.length >= 10 && digits.length <= 15) ? null : 'Некорректный номер';
  }

  static String? positiveInt(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n <= 0) return 'Введите число больше 0';
    if (n > 100000) return 'Слишком большое число';
    return null;
  }
}
