import 'package:flutter/material.dart';

import '../features/polls/student_poll_page.dart';
import '../features/settings/student_settings_page.dart';

// lib/features/shell/student_shell.dart
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _currentIndex = 0;

  final _pages = [
    const StudentPollPage(),
    const StudentSettingsPage(),
  ];

  @override
Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.poll), label: 'Poll'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// StudentSettingsPage moved to lib/features/settings/student_settings_page.dart