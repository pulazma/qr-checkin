import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await appState.init();
  } catch (e) {
    runApp(_SetupErrorApp('$e'));
    return;
  }
  runApp(const QrCheckInApp());
}

class QrCheckInApp extends StatelessWidget {
  const QrCheckInApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Check-in',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}

class _SetupErrorApp extends StatelessWidget {
  final String message;
  const _SetupErrorApp(this.message);

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Не удалось подключиться к Firebase',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const Text('Выполните «flutterfire configure» и перезапустите приложение.',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
}
