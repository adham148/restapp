import 'package:flutter/material.dart';

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
    StatisticsScreen(),
    CategoriesScreen(),
    VideoManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20), // زيادة نصف القطر لجعل التقوس أكثر وضوحاً
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
            elevation: 0, // إزالة الظل بالكامل
            selectedItemColor: Colors.red[700], // لون أحمر أكثر كثافة
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
                    size: _currentIndex == 0 ? 28 : 24, // تكبير الأيقونة عند التحديد
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
            ],
          ),
        ),
      ),
    );
  }
}

// Screens Placeholders
