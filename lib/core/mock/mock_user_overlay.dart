import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_service.dart';
import 'mock_users.dart';

class MockUserOverlay extends ConsumerStatefulWidget {
  const MockUserOverlay({super.key});

  @override
  ConsumerState<MockUserOverlay> createState() => _MockUserOverlayState();
}

class _MockUserOverlayState extends ConsumerState<MockUserOverlay> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_expanded)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Mock Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[...mockDriverTokens, ...mockStudentTokens].map((user) => InkWell(
                          onTap: () async {
                            setState(() => _expanded = false);
                            await ref.read(authServiceProvider).signInWithMock(user['token']!);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person, size: 16, color: Color(0xFF0D9488)),
                                const SizedBox(width: 8),
                                Text(
                                  user['label']!,
                                  style: const TextStyle(
                                    color: Color(0xFF0D9488),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                    const Divider(),
                    InkWell(
                      onTap: () async {
                        setState(() => _expanded = false);
                        await ref.read(authServiceProvider).signOut();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            FloatingActionButton(
              mini: true,
              backgroundColor: Colors.amber.shade700,
              elevation: 4,
              onPressed: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Icon(
                _expanded ? Icons.close : Icons.bug_report,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
