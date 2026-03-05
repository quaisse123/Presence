import 'package:flutter/material.dart';
import 'package:frontend/Api/Header.dart';
import 'package:frontend/pages/profDash.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

// ─────────────────────────────────────────────
//  MAIN SCREEN — centralised navigation
// ─────────────────────────────────────────────

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const _primary = Color(0xFF1A73E8);
  static const _surface = Color.fromARGB(255, 0, 96, 192);

  final List<Widget> _pages = [
    const ProfDashPage(),
    const ProfDashPage(), // TODO: replace with SearchPage
    const ProfDashPage(), // TODO: replace with ProfilePage
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: MainHeader(
        userName: 'Quaisse',
        subtitle: 'Welcome back',
        onProfileTap: () {
          // TODO: open profile
        },
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: SalomonBottomBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              itemPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              items: [
                SalomonBottomBarItem(
                  icon: const Icon(Icons.event, size: 22),
                  title: const Text(
                    "Sessions",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  selectedColor: const Color(0xFF1A73E8),
                  unselectedColor: const Color(0xFF1A73E8).withOpacity(0.4),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.menu_book, size: 22),
                  title: const Text(
                    "Courses",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  selectedColor: const Color(0xFF1A73E8),
                  unselectedColor: const Color(0xFF1A73E8).withOpacity(0.4),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.search_rounded, size: 22),
                  title: const Text(
                    "Search",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  selectedColor: const Color(0xFF1A73E8),
                  unselectedColor: const Color(0xFF1A73E8).withOpacity(0.4),
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.person_outline_rounded, size: 22),
                  title: const Text(
                    "Profile",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  selectedColor: const Color(0xFF1A73E8),
                  unselectedColor: const Color(0xFF1A73E8).withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
