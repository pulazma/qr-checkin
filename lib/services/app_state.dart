import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';

enum CheckInStatus { ok, already, notFound, wrongEvent, error }

class CheckInResult {
  final CheckInStatus status;
  final Registration? registration;
  final Event? event;
  final String? message;
  const CheckInResult(this.status, {this.registration, this.event, this.message});
}

/// Состояние приложения поверх Firebase:
///  • Firebase Authentication — вход по email/паролю;
///  • Cloud Firestore — коллекции users, events, registrations.
/// Данные из Firestore приходят потоками (snapshots) и кэшируются в памяти,
/// поэтому экраны обновляются в реальном времени.
class AppState extends ChangeNotifier {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  AppUser? _profile;
  List<Event> _events = [];
  List<Registration> _regs = [];

  StreamSubscription? _authSub, _eventsSub, _regsSub;
  String? _sessionUid;
  Future<void>? _sessionFuture;
  bool _suppressAuth = false;

  // ---------- Инициализация ----------

  Future<void> init() async {
    final first = Completer<void>();
    _authSub = _auth.authStateChanges().listen((user) async {
      if (_suppressAuth) return;
      try {
        if (user == null) {
          await _clearSession();
        } else {
          await _startSession(user.uid);
        }
      } catch (e) {
        debugPrint('auth state error: $e');
      }
      if (!first.isCompleted) first.complete();
      notifyListeners();  
    });
    await first.future.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  Future<void> _startSession(String uid) {
    if (_sessionUid == uid && _sessionFuture != null) return _sessionFuture!;
    _sessionUid = uid;
    return _sessionFuture = _doStart(uid);
  }

  Future<void> _doStart(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      _profile = null;
      return;
    }
    final profile = AppUser.fromJson(uid, doc.data()!);
    _profile = profile;

    await _eventsSub?.cancel();
    await _regsSub?.cancel();

    _eventsSub = _db.collection('events').snapshots().listen((snap) {
      _events = snap.docs.map((d) => Event.fromJson(d.id, d.data())).toList();
      notifyListeners();
    }, onError: (e) => debugPrint('events stream: $e'));

    final regsQuery = profile.role == UserRole.organizer
        ? _db.collection('registrations').where('organizerId', isEqualTo: uid)
        : _db.collection('registrations').where('userId', isEqualTo: uid);
    _regsSub = regsQuery.snapshots().listen((snap) {
      _regs = snap.docs.map((d) => Registration.fromJson(d.id, d.data())).toList();
      notifyListeners();
    }, onError: (e) => debugPrint('registrations stream: $e'));
  }

  Future<void> _clearSession() async {
    await _eventsSub?.cancel();
    await _regsSub?.cancel();
    _eventsSub = null;
    _regsSub = null;
    _sessionUid = null;
    _sessionFuture = null;
    _profile = null;
    _events = [];
    _regs = [];
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _eventsSub?.cancel();
    _regsSub?.cancel();
    super.dispose();
  }

  // ---------- Вспомогательное ----------

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Некорректный email';
      case 'user-not-found':
        return 'Пользователь не найден';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль';
      case 'email-already-in-use':
        return 'Пользователь с таким email уже существует';
      case 'weak-password':
        return 'Слишком простой пароль (минимум 6 символов)';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже';
      case 'network-request-failed':
        return 'Нет соединения с интернетом';
      case 'operation-not-allowed':
        return 'В Firebase не включён вход по Email/Password';
      default:
        return 'Ошибка входа: ${e.code}';
    }
  }

  String _fbError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Нет прав доступа (проверьте правила Firestore)';
      case 'unavailable':
        return 'Нет соединения с сервером';
      default:
        return 'Ошибка Firebase: ${e.code}';
    }
  }

  Future<String?> _guard(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } on FirebaseException catch (e) {
      return _fbError(e);
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  String _newCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => alphabet[r.nextInt(alphabet.length)]).join();
  }

  // ---------- Геттеры ----------

  AppUser? get currentUser => _profile;
  bool get isLoggedIn => _profile != null;
  bool get isOrganizer => _profile?.role == UserRole.organizer;

  List<Event> get allEvents {
    final list = List<Event>.from(_events);
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  List<Event> get myEvents => allEvents.where((e) => e.organizerId == _profile?.id).toList();

  /// Билеты текущего участника.
  List<Registration> get myRegistrations {
    final list = _regs.where((r) => r.userId == _profile?.id).toList();
    list.sort((a, b) {
      final ea = eventById(a.eventId)?.date ?? DateTime(2100);
      final eb = eventById(b.eventId)?.date ?? DateTime(2100);
      return ea.compareTo(eb);
    });
    return list;
  }

  Event? eventById(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  Registration? registrationById(String id) {
    for (final r in _regs) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Регистрации на мероприятие (полный список доступен организатору).
  List<Registration> registrationsOf(String eventId) {
    final list = _regs.where((r) => r.eventId == eventId).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  int checkedInCount(String eventId) => _regs.where((r) => r.eventId == eventId && r.checkedIn).length;

  Registration? myRegistrationFor(String eventId) {
    for (final r in _regs) {
      if (r.eventId == eventId && r.userId == _profile?.id) return r;
    }
    return null;
  }

  int get totalRegistrationsForMyEvents => isOrganizer ? _regs.length : 0;
  int get totalCheckedInForMyEvents => isOrganizer ? _regs.where((r) => r.checkedIn).length : 0;

  // ---------- Аутентификация ----------

  /// Регистрация нового аккаунта. Возвращает текст ошибки или null при успехе.
  /// После регистрации пользователь выходит и входит через экран авторизации.
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String organization = '',
    required UserRole role,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      return 'Заполните обязательные поля';
    }
    _suppressAuth = true;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final uid = cred.user!.uid;
      await _db.collection('users').doc(uid).set(AppUser(
            id: uid,
            name: name.trim(),
            email: email.trim().toLowerCase(),
            phone: phone.trim(),
            organization: organization.trim(),
            role: role,
          ).toJson());
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } on FirebaseException catch (e) {
      return _fbError(e);
    } catch (e) {
      return 'Ошибка: $e';
    } finally {
      _suppressAuth = false;
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      await _startSession(cred.user!.uid);
      if (_profile == null) {
        await _auth.signOut();
        return 'Профиль пользователя не найден в базе данных';
      }
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } on FirebaseException catch (e) {
      return _fbError(e);
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _clearSession();
    notifyListeners();
  }

  Future<String?> updateProfile({required String name, String phone = '', String organization = ''}) async {
    final u = _profile;
    if (u == null) return 'Войдите в аккаунт';
    return _guard(() async {
      await _db.collection('users').doc(u.id).update({
        'name': name.trim(),
        'phone': phone.trim(),
        'organization': organization.trim(),
      });
      _profile = u.copyWith(name: name.trim(), phone: phone.trim(), organization: organization.trim());
      notifyListeners();
    });
  }

  // ---------- Мероприятия (CRUD) ----------

  Future<String?> addEvent({
    required String title,
    required String description,
    required String location,
    required String category,
    required DateTime date,
    required int capacity,
  }) async {
    final u = _profile;
    if (u == null) return 'Войдите в аккаунт';
    return _guard(() async {
      final ref = _db.collection('events').doc();
      await ref.set(Event(
        id: ref.id,
        title: title.trim(),
        description: description.trim(),
        location: location.trim(),
        category: category,
        date: date,
        capacity: capacity,
        organizerId: u.id,
        organizerName: u.name,
      ).toJson());
    });
  }

  Future<String?> updateEvent(Event updated) async {
    final cur = eventById(updated.id);
    if (cur == null) return 'Мероприятие не найдено';
    if (updated.capacity < cur.registered) {
      return 'Вместимость не может быть меньше числа регистраций (${cur.registered})';
    }
    return _guard(() => _db.collection('events').doc(updated.id).update({
          'title': updated.title,
          'description': updated.description,
          'location': updated.location,
          'category': updated.category,
          'date': updated.date.millisecondsSinceEpoch,
          'capacity': updated.capacity,
        }));
  }

  Future<String?> deleteEvent(String eventId) {
    return _guard(() async {
      final batch = _db.batch();
      for (final r in _regs.where((r) => r.eventId == eventId)) {
        batch.delete(_db.collection('registrations').doc(r.id));
      }
      batch.delete(_db.collection('events').doc(eventId));
      await batch.commit();
    });
  }

  // ---------- Регистрации ----------

  Future<String?> registerForEvent(String eventId) async {
    final user = _profile;
    if (user == null) return 'Войдите в аккаунт';
    final evRef = _db.collection('events').doc(eventId);
    final regRef = _db.collection('registrations').doc('${eventId}_${user.id}');
    String? problem;
    final err = await _guard(() async {
      await _db.runTransaction((tx) async {
        final ev = await tx.get(evRef);
        if (!ev.exists) {
          problem = 'Мероприятие не найдено';
          return;
        }
        final existing = await tx.get(regRef);
        if (existing.exists) {
          problem = 'Вы уже зарегистрированы';
          return;
        }
        final data = ev.data()!;
        final capacity = (data['capacity'] as num).toInt();
        final taken = ((data['registered'] ?? 0) as num).toInt();
        if (taken >= capacity) {
          problem = 'Свободных мест нет';
          return;
        }
        tx.set(
          regRef,
          Registration(
            id: regRef.id,
            eventId: eventId,
            userId: user.id,
            userName: user.name,
            userEmail: user.email,
            organizerId: (data['organizerId'] ?? '') as String,
            code: _newCode(),
            createdAt: DateTime.now(),
          ).toJson(),
        );
        tx.update(evRef, {'registered': FieldValue.increment(1)});
      });
    });
    return err ?? problem;
  }

  Future<String?> cancelRegistration(String regId) async {
    final reg = registrationById(regId);
    if (reg == null) return null;
    return _guard(() async {
      final batch = _db.batch();
      batch.delete(_db.collection('registrations').doc(regId));
      if (eventById(reg.eventId) != null) {
        batch.update(_db.collection('events').doc(reg.eventId), {'registered': FieldValue.increment(-1)});
      }
      await batch.commit();
    });
  }

  // ---------- Check-in (отметка прихода по QR) ----------

  /// [raw] — содержимое QR (`QRREG|id|code`) или просто 6-значный код.
  /// Организатор видит только регистрации на свои мероприятия.
  Future<CheckInResult> checkIn(String raw, {String? onlyEventId}) async {
    final input = raw.trim();
    Registration? found;
    final parts = input.split('|');
    for (final r in _regs) {
      if (parts.length == 3 && parts[0] == 'QRREG') {
        if (r.id == parts[1] && r.code == parts[2]) found = r;
      } else if (r.code == input.toUpperCase()) {
        found = r;
      }
    }
    if (found == null) return const CheckInResult(CheckInStatus.notFound);
    final reg = found;
    final event = eventById(reg.eventId);

    if (onlyEventId != null && onlyEventId != reg.eventId) {
      return CheckInResult(CheckInStatus.wrongEvent, registration: reg, event: event);
    }
    if (reg.checkedIn) {
      return CheckInResult(CheckInStatus.already, registration: reg, event: event);
    }
    final now = DateTime.now();
    final err = await _guard(() => _db
        .collection('registrations')
        .doc(reg.id)
        .update({'checkedInAt': now.millisecondsSinceEpoch}));
    if (err != null) return CheckInResult(CheckInStatus.error, message: err);
    return CheckInResult(CheckInStatus.ok, registration: reg.withCheckIn(now), event: event);
  }

  /// Ручная отметка/снятие отметки организатором.
  Future<String?> toggleCheckIn(String regId) {
    final r = registrationById(regId);
    if (r == null) return Future.value('Билет не найден');
    return _guard(() => _db.collection('registrations').doc(regId).update({
          'checkedInAt': r.checkedIn ? null : DateTime.now().millisecondsSinceEpoch,
        }));
  }
}

/// Глобальный экземпляр состояния.
final appState = AppState();
