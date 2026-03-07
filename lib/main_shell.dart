import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/feed_screen.dart';
import 'screens/friends_search_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/dares_screen.dart';
import 'screens/ai_settings_screen.dart';
import 'screens/profile_screen.dart';
import 'providers/navigation_provider.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFA855F7);
    const backgroundDark = Color(0xFF0F0814);

    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: navProvider.selectedIndex,
            children: const [
              FeedScreen(),
              FriendsSearchScreen(),
              DaresScreen(),
              AiSettingsScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: backgroundDark,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: BottomNavigationBar(
              currentIndex: navProvider.selectedIndex,
              onTap: (index) => navProvider.setTab(index),
              backgroundColor: Colors.transparent,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.white38,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Feed',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bolt_outlined),
                  activeIcon: Icon(Icons.bolt),
                  label: 'Dares',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.auto_awesome_outlined),
                  activeIcon: Icon(Icons.auto_awesome),
                  label: 'AI',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
