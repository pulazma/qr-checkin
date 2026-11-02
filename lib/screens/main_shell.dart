import 'package:flutter/material.dart';

import '../services/app_state.dart';
import 'events_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
import 'tickets_screen.dart';

/// Основная навигация (нижняя панель). Третья вкладка зависит от роли:
/// организатор — «Сканер», участник — «Мои билеты».
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (!appState.isLoggedIn) return const Scaffold(body: SizedBox());
        final org = appState.isOrganizer;
        final pages = <Widget>[
          HomeScreen(onOpenTab: (i) => setState(() => _index = i)),
          const EventsScreen(),
          org ? const ScannerScreen() : const TicketsScreen(),
          const ProfileScreen(),
        ];
        return Scaffold(
          body: pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              const NavigationDestination(
                  icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Главная'),
              const NavigationDestination(
                  icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'События'),
              NavigationDestination(
                icon: Icon(org ? Icons.qr_code_scanner : Icons.confirmation_number_outlined),
                selectedIcon: Icon(org ? Icons.qr_code_scanner : Icons.confirmation_number),
                label: org ? 'Сканер' : 'Билеты',
              ),
              const NavigationDestination(
                  icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Профиль'),
            ],
          ),
        );
      },
    );
  }
}
