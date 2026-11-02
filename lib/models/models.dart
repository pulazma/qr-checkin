enum UserRole { participant, organizer }

extension UserRoleX on UserRole {
  String get title => this == UserRole.organizer ? 'Организатор' : 'Участник';
}

/// Профиль пользователя (коллекция `users`, id документа = uid Firebase Auth).
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String organization;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.organization = '',
    required this.role,
  });

  AppUser copyWith({String? name, String? phone, String? organization}) => AppUser(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        organization: organization ?? this.organization,
        role: role,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'organization': organization,
        'role': role.name,
      };

  factory AppUser.fromJson(String id, Map<String, dynamic> j) => AppUser(
        id: id,
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        organization: (j['organization'] ?? '') as String,
        role: UserRole.values.byName((j['role'] ?? 'participant') as String),
      );
}

/// Мероприятие (коллекция `events`).
class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final String category;
  final DateTime date;
  final int capacity;
  final String organizerId;
  final String organizerName;
  final int registered; // сколько мест занято

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.date,
    required this.capacity,
    required this.organizerId,
    this.organizerName = '',
    this.registered = 0,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'date': date.millisecondsSinceEpoch,
        'capacity': capacity,
        'organizerId': organizerId,
        'organizerName': organizerName,
        'registered': registered,
      };

  factory Event.fromJson(String id, Map<String, dynamic> j) => Event(
        id: id,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        location: (j['location'] ?? '') as String,
        category: (j['category'] ?? 'Конференция') as String,
        date: DateTime.fromMillisecondsSinceEpoch((j['date'] as num).toInt()),
        capacity: (j['capacity'] as num).toInt(),
        organizerId: (j['organizerId'] ?? '') as String,
        organizerName: (j['organizerName'] ?? '') as String,
        registered: ((j['registered'] ?? 0) as num).toInt(),
      );
}

/// Регистрация участника = "билет" с QR-кодом (коллекция `registrations`).
/// id документа = `<eventId>_<userId>` — один участник не может записаться дважды.
class Registration {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userEmail;
  final String organizerId;
  final String code;
  final DateTime createdAt;
  final DateTime? checkedInAt;

  const Registration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.organizerId,
    required this.code,
    required this.createdAt,
    this.checkedInAt,
  });

  bool get checkedIn => checkedInAt != null;

  /// Содержимое QR-кода.
  String get qrPayload => 'QRREG|$id|$code';

  Registration withCheckIn(DateTime? time) => Registration(
        id: id,
        eventId: eventId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        organizerId: organizerId,
        code: code,
        createdAt: createdAt,
        checkedInAt: time,
      );

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'organizerId': organizerId,
        'code': code,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'checkedInAt': checkedInAt?.millisecondsSinceEpoch,
      };

  factory Registration.fromJson(String id, Map<String, dynamic> j) => Registration(
        id: id,
        eventId: (j['eventId'] ?? '') as String,
        userId: (j['userId'] ?? '') as String,
        userName: (j['userName'] ?? '') as String,
        userEmail: (j['userEmail'] ?? '') as String,
        organizerId: (j['organizerId'] ?? '') as String,
        code: (j['code'] ?? '') as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(((j['createdAt'] ?? 0) as num).toInt()),
        checkedInAt: j['checkedInAt'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((j['checkedInAt'] as num).toInt()),
      );
}
