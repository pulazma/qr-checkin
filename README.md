# QR Check-in — регистрация участников мероприятий по QR-коду (Flutter + Firebase)

Курсовой проект по ПМ07 «Разработка мобильных приложений».

## 1. Настройка Firebase (один раз)

1. https://console.firebase.google.com → **Add project** (Google Analytics можно отключить).
2. **Build → Authentication → Get started → Sign-in method → Email/Password → Enable.**
3. **Build → Firestore Database → Create database** (любой регион, режим *Production*).
   Затем вкладка **Rules** → вставьте содержимое файла `firestore.rules` из проекта → **Publish**.
4. Установите инструменты (нужен Node.js, https://nodejs.org):
   ```
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   ```
   Если команда `flutterfire` не находится, добавьте в PATH папку `%LOCALAPPDATA%\Pub\Cache\bin` и перезапустите терминал.
5. В папке проекта:
   ```
   flutterfire configure
   ```
   Выберите свой проект и платформы **web** и **android** (windows не отмечайте).
   Команда создаст настоящий `lib/firebase_options.dart` (заменит заглушку).
6. ```
   flutter pub get
   flutter run -d chrome
   ```

> Android: если сборка ругается на minSdk, в `android/app/build.gradle(.kts)` поставьте `minSdk = 23`.

## 2. Камера для сканирования QR (только телефон)
- Android — `android/app/src/main/AndroidManifest.xml`, внутри `<manifest>`: `<uses-permission android:name="android.permission.CAMERA"/>`
- iOS — `ios/Runner/Info.plist`: ключ `NSCameraUsageDescription` с текстом-пояснением.
- В Chrome/на ПК используйте ручной ввод 6-значного кода с билета.

## 3. Где хранятся данные
| Что | Где |
|---|---|
| Логины и пароли | Firebase Authentication (пароли хешируются Google) |
| Профили (ФИО, телефон, роль) | Firestore, коллекция `users` |
| Мероприятия | Firestore, коллекция `events` |
| Билеты/регистрации | Firestore, коллекция `registrations` (id = `eventId_userId`) |

Просмотр данных: Firebase Console → Authentication / Firestore Database.

## 4. Сценарий демонстрации
Splash → Регистрация → Вход → Главная → Навигация → Профиль → Основной раздел → Выход.
1. Зарегистрируйте **организатора** → войдите → «События» → «Создать».
2. Выйдите, зарегистрируйте **участника** → «События» → «Зарегистрироваться» → «Билеты» → QR.
3. Снова организатором → «Сканер» → код с билета (или камера) → «Вход разрешён». Отметка появится у участника в реальном времени.

## 5. Архитектура
```
lib/
  main.dart, firebase_options.dart
  core/      theme.dart, utils.dart (валидаторы)
  models/    AppUser, Event, Registration
  services/  app_state.dart — ChangeNotifier: FirebaseAuth + Firestore (snapshots в реальном времени)
  screens/   splash, login, register, main_shell, home, events, event_detail,
             event_form, tickets, ticket, scanner, profile, edit_profile
  widgets/   common.dart
firestore.rules   правила безопасности Firestore
test/app_test.dart  unit-тесты (валидаторы, модели, QR-содержимое)
```
- State management: `ChangeNotifier` + `ListenableBuilder`.
- Защита от дублей и переполнения: транзакция Firestore при регистрации на мероприятие.
- Права доступа: участник видит только свои билеты, организатор — билеты своих мероприятий.

## 6. Соответствие критериям
Splash, регистрация с валидацией, вход с обработкой ошибок, сохранение сессии (FirebaseAuth),
главная, нижняя навигация, профиль + редактирование, мероприятия/билеты/сканер, выход,
CRUD (Firestore), поиск и фильтры, тесты (`flutter test`).
