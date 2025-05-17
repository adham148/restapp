import 'package:flutter/material.dart';

import 'Complaints_management_screen.dart';
import 'UserManagementScreen.dart';
import 'add_sections_screen.dart';
import 'add_videos_screen.dart';
import 'dashboard.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    StatsScreen(),
    const CategoriesScreen(),
    const VideoManagementScreen(),
    const UserManagementScreen(), // Added user management screen
    const ComplaintsScreen(), // Added complaints management screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: Colors.red[700],
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.home,
                    size: _currentIndex == 0 ? 28 : 24,
                  ),
                ),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.category,
                    size: _currentIndex == 1 ? 28 : 24,
                  ),
                ),
                label: 'الأقسام',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.video_library,
                    size: _currentIndex == 2 ? 28 : 24,
                  ),
                ),
                label: 'الفيديوهات',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.people,
                    size: _currentIndex == 3 ? 28 : 24,
                  ),
                ),
                label: 'المستخدمين',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.report,
                    size: _currentIndex == 4 ? 28 : 24,
                  ),
                ),
                label: 'الشكاوي',
              ),
            ],
          ),
        ),
      ),
    );
  }
}







