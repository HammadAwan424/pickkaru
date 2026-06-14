import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poll.dart';
import '../providers/auth_provider.dart';
import '../providers/poll_provider.dart';

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

class DriverPollPage extends ConsumerWidget {
  const DriverPollPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Not signed in')));
        }

        final pollsAsync = ref.watch(driverPollsProvider(user.uid));

        return Scaffold(
          appBar: AppBar(title: const Text('Driver Poll')),
          body: pollsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (polls) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PollControlCard(
                    title: 'Morning Poll',
                    poll: polls.morning,
                    driverId: user.uid,
                    period: PollPeriod.morning,
                  ),
                  const SizedBox(height: 16),
                  _PollControlCard(
                    title: 'Evening Poll',
                    poll: polls.evening,
                    driverId: user.uid,
                    period: PollPeriod.evening,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PollControlCard extends ConsumerWidget {
  final String title;
  final Poll poll;
  final String driverId;
  final PollPeriod period;

  const _PollControlCard({
    required this.title,
    required this.poll,
    required this.driverId,
    required this.period,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = switch (poll.status) {
      PollStatus.uninitiated => colors.surfaceContainerHighest,
      PollStatus.active => Colors.green,
      PollStatus.completed => colors.outline,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    poll.status.name,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${poll.responses.length} students',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (poll.status == PollStatus.uninitiated)
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(pollActionsProvider).startRide(
                            driverId: driverId,
                            period: period,
                          );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Ride'),
                  ),
                if (poll.status == PollStatus.active) ...[
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(pollActionsProvider).completeRide(
                            driverId: driverId,
                            period: period,
                          );
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Complete Ride'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navigation — coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.navigation),
                    label: const Text('Navigation'),
                  ),
                ],
                if (poll.status == PollStatus.completed)
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(pollActionsProvider).startRide(
                            driverId: driverId,
                            period: period,
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Restart'),
                  ),
              ],
            ),
            if (poll.status == PollStatus.active &&
                poll.approachingStudentIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Approaching: ${poll.approachingStudentIds.length} student(s)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
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
