import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Экран-заставка: логотип, название, переход на следующий экран.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), _next);
  }

  void _next() {
    if (!mounted) return;
    final target = appState.isLoggedIn ? const MainShell() : const LoginScreen();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => target,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1B4B), kPrimary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _ctrl,
          child: ScaleTransition(
            scale: Tween(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 120),
                const SizedBox(height: 28),
                const Text('QR Check-in',
                    style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('Регистрация участников мероприятий по QR-коду',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15)),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
