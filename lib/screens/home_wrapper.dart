import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/specta_theme.dart';
import 'dashboard_screen.dart';
import 'gatekeeper_screen.dart';

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const GatekeeperScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: SpectaTheme.slateBg,
          currentIndex: _currentIndex,
          selectedItemColor: SpectaTheme.neonCyan,
          unselectedItemColor: SpectaTheme.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          elevation: 0,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.layoutDashboard),
              activeIcon: Icon(LucideIcons.layoutDashboard, color: SpectaTheme.neonCyan),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.scanLine),
              activeIcon: Icon(LucideIcons.scanLine, color: SpectaTheme.neonCyan),
              label: 'Scanner',
            ),
          ],
        ),
      ),
    );
  }
}
