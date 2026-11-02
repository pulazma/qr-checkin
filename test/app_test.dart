import 'package:flutter_test/flutter_test.dart';
import 'package:qr_checkin/core/utils.dart';
import 'package:qr_checkin/models/models.dart';

void main() {
  group('Валидаторы', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b.kz'), isNull);
    });
    test('пароль', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
    test('телефон необязателен, но проверяется', () {
      expect(Validators.phone(''), isNull);
      expect(Validators.phone('12'), isNotNull);
      expect(Validators.phone('+7 701 123 45 67'), isNull);
    });
    test('количество мест', () {
      expect(Validators.positiveInt('0'), isNotNull);
      expect(Validators.positiveInt('abc'), isNotNull);
      expect(Validators.positiveInt('25'), isNull);
    });
  });

  group('Модели', () {
    test('Event: сериализация туда-обратно', () {
      final e = Event(
        id: 'e1', title: 'Conf', description: 'd', location: 'Астана', category: 'Конференция',
        date: DateTime(2026, 11, 5, 10, 30), capacity: 50, organizerId: 'o1',
        organizerName: 'Орг', registered: 3,
      );
      final back = Event.fromJson('e1', e.toJson());
      expect(back.title, 'Conf');
      expect(back.date, e.date);
      expect(back.capacity, 50);
      expect(back.registered, 3);
    });

    test('Registration: QR-содержимое и отметка прихода', () {
      final r = Registration(
        id: 'e1_u1', eventId: 'e1', userId: 'u1', userName: 'Гость', userEmail: 'g@x.kz',
        organizerId: 'o1', code: 'ABC123', createdAt: DateTime(2026, 1, 1),
      );
      expect(r.qrPayload, 'QRREG|e1_u1|ABC123');
      expect(r.checkedIn, isFalse);
      final c = r.withCheckIn(DateTime(2026, 1, 2));
      expect(c.checkedIn, isTrue);
      expect(Registration.fromJson(c.id, c.toJson()).checkedIn, isTrue);
    });

    test('AppUser: роль сохраняется', () {
      const u = AppUser(id: 'u', name: 'Имя', email: 'a@b.kz', role: UserRole.organizer);
      expect(AppUser.fromJson('u', u.toJson()).role, UserRole.organizer);
    });
  });
}
