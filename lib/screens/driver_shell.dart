import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';


// lib/features/shell/driver_shell.dart
class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell> {
  int _currentIndex = 0;

  final _pages = const [
    DriverPollPage(),
    DriverSettingsPage(),
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

class DriverPollPage extends StatelessWidget {
  const DriverPollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Driver Poll Page'));
  }
}

class DriverSettingsPage extends ConsumerWidget {
  const DriverSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
        onPressed: () async {
          await ref.read(authServiceProvider).signOut();
        },
        child: const Text('Sign out'),
      ),
    );
  }
}