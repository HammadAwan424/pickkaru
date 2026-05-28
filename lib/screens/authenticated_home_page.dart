import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/student_driver_assignment_page.dart';

class AuthenticatedHomePage extends ConsumerStatefulWidget {
  const AuthenticatedHomePage({super.key});

  @override
  ConsumerState<AuthenticatedHomePage> createState() =>
      _AuthenticatedHomePageState();
}

class _AuthenticatedHomePageState extends ConsumerState<AuthenticatedHomePage> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const LoginRedirectPage();
        }

        if (user.role == 'student') {
          return _buildStudentView(context, user);
        } else if (user.role == 'driver') {
          return _buildDriverView(context, user);
        }

        return const Scaffold(
          body: Center(child: Text('Unknown role')),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStudentView(
      BuildContext context, dynamic user) {
    // Check if driver is assigned
    if (user.assignedDriverId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pickkaru')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No driver assigned'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentDriverAssignmentPage(studentUid: user.uid),
                    ),
                  );
                },
                child: const Text('Assign a Driver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickkaru'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Polls view coming soon'),
      ),

    );
  }

  Widget _buildDriverView(BuildContext context, dynamic user) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickkaru — Driver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Driver view coming soon'),
      ),
    );
  }
}

class LoginRedirectPage extends ConsumerWidget {
  const LoginRedirectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
