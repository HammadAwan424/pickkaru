import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/poll/models/DailyPollBoard.dart';
import '../../shared/roster/Roster.dart';
import '../../core/auth/auth_provider.dart';
import '../../poll_provider.dart';
import '../../shared/roster/roster_provider.dart';

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

class DriverPollPage extends StatefulWidget {
  const DriverPollPage({super.key});

  @override
  State<DriverPollPage> createState() => _DriverPollPageState();
}

class _DriverPollPageState extends State<DriverPollPage> {
  PollPeriod _selectedPeriod = PollPeriod.morning;
  bool _isInitializing = false;

  String _formatHeaderDate(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final userAsync = ref.watch(currentUserProvider);
        return userAsync.when(
          loading: () => const Scaffold(
            backgroundColor: Color(0xFFF3F4F6),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
              ),
            ),
          ),
          error: (e, _) => Scaffold(
            backgroundColor: const Color(0xFFF3F4F6),
            body: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
          ),
          data: (user) {
            if (user == null) {
              return const Scaffold(
                backgroundColor: Color(0xFFF3F4F6),
                body: Center(child: Text('Not signed in', style: TextStyle(fontWeight: FontWeight.bold))),
              );
            }

            final activeDateAsync = ref.watch(activeDateProvider(user.uid));
            final driverPollsAsync = ref.watch(driverPollsProvider(user.uid));

            final polls = driverPollsAsync.valueOrNull;
            final isMorningActive = polls?.morning.status == PollStatus.active;
            final isEveningActive = polls?.evening.status == PollStatus.active;

            final currentPeriod = isMorningActive
                ? PollPeriod.morning
                : (isEveningActive ? PollPeriod.evening : _selectedPeriod);

            final activeDateObj = activeDateAsync.valueOrNull;
            final activeDate = activeDateObj?.date ?? DateTime.now();
            final today = DateTime(activeDate.year, activeDate.month, activeDate.day);

            final dailyBoardAsync = ref.watch(dailyBoardProvider(DailyBoardArgs(
              driverId: user.uid,
              period: currentPeriod,
              date: today,
            )));

            final parentPollAsync = ref.watch(pollProvider(currentPeriod));

            final rosterAsync = ref.watch(rosterProvider(user.uid));

            if (parentPollAsync.hasError) {
              return Scaffold(
                backgroundColor: const Color(0xFFF3F4F6),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error loading poll config: ${parentPollAsync.error}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            if (rosterAsync.hasError) {
              return Scaffold(
                backgroundColor: const Color(0xFFF3F4F6),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error loading roster: ${rosterAsync.error}',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF3F4F6),
              body: SafeArea(
                child: Stack(
                  children: [
                    // Main Scrollable Content
                    CustomScrollView(
                      slivers: [
                        // Custom Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatHeaderDate(today),
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Command Center',
                                          style: TextStyle(
                                            color: Color(0xFF1F2937),
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SelectableText(
                                          'Driver ID: ${user.uid}',
                                          style: const TextStyle(
                                            color: Color(0xFF0D9488),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Soft, premium sign out icon button
                                    IconButton(
                                      onPressed: () async {
                                        await ref.read(authServiceProvider).signOut();
                                      },
                                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                                        padding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Custom Period Switcher Tab Bar
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E7EB),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _PeriodTabButton(
                                          title: 'Morning Ride',
                                          isSelected: currentPeriod == PollPeriod.morning,
                                          isDisabled: isEveningActive,
                                          onTap: () {
                                            setState(() {
                                              _selectedPeriod = PollPeriod.morning;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: _PeriodTabButton(
                                          title: 'Evening Ride',
                                          isSelected: currentPeriod == PollPeriod.evening,
                                          isDisabled: isMorningActive,
                                          onTap: () {
                                            setState(() {
                                              _selectedPeriod = PollPeriod.evening;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Main body content dependent on stream states
                        dailyBoardAsync.when(
                          loading: () => const SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                              ),
                            ),
                          ),
                          error: (err, _) => SliverFillRemaining(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'Error loading daily board: $err',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                          data: (dailyBoard) {
                            if (dailyBoard == null) {
                              // Render Uninitialized View
                              return SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D9488).withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 64,
                                            color: Color(0xFF0D9488),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          "Today's Ride is Not Initialized",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          "Set up the student roster and boarding map for this period to start tracking.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        ElevatedButton(
                                          onPressed: _isInitializing
                                              ? null
                                              : () async {
                                                  setState(() => _isInitializing = true);
                                                  try {
                                                    await ref.read(pollActionsProvider).initializeDailyBoard(
                                                          driverId: user.uid,
                                                          period: _selectedPeriod,
                                                          date: today,
                                                        );
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Failed to initialize: $e'),
                                                        backgroundColor: Colors.redAccent,
                                                      ),
                                                    );
                                                  } finally {
                                                    if (mounted) {
                                                      setState(() => _isInitializing = false);
                                                    }
                                                  }
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF0D9488),
                                            foregroundColor: Colors.white,
                                            elevation: 2,
                                            shadowColor: const Color(0xFF0D9488).withOpacity(0.4),
                                            minimumSize: const Size(220, 56),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(28),
                                            ),
                                          ),
                                          child: _isInitializing
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.bolt_rounded, size: 20),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      "Initialize Today's Ride",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            // If dailyBoard is initialized
                            final roster = rosterAsync.value;
                            final parentPoll = parentPollAsync.value;
                            final status = parentPoll?.status ?? PollStatus.uninitiated;

                            // Calculate Stats
                            final responses = dailyBoard.responses;
                            final totalResponses = responses.length;
                            final ridingCount = responses.values.where((r) => r.answer == true).length;
                            final boardedCount = responses.values.where((r) => r.boarded == true).length;
                            final notRidingCount = responses.values.where((r) => r.answer == false).length;
                            final noResponseCount = responses.values.where((r) => r.answer == null).length;

                            final sortedEntries = responses.entries.toList();
                            sortedEntries.sort((a, b) {
                              final nameA = roster?.students[a.key]?.displayName ?? a.key;
                              final nameB = roster?.students[b.key]?.displayName ?? b.key;
                              return nameA.toLowerCase().compareTo(nameB.toLowerCase());
                            });

                            return SliverPadding(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  // Stats Summary Card
                                  _StatsSummaryCard(
                                    status: status,
                                    ridingCount: ridingCount,
                                    boardedCount: boardedCount,
                                    notRidingCount: notRidingCount,
                                    noResponseCount: noResponseCount,
                                  ),
                                  const SizedBox(height: 20),

                                  // Approaching Student Banner
                                  if (dailyBoard.approachingStudentIds.isNotEmpty) ...[
                                    _ApproachingBanner(
                                      studentIds: dailyBoard.approachingStudentIds,
                                      roster: roster,
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Roster Title
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Roster list ($totalResponses students)',
                                        style: const TextStyle(
                                          color: Color(0xFF1F2937),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Students list
                                  if (sortedEntries.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                                      child: Center(
                                        child: Text(
                                          "No students assigned to this driver.",
                                          style: TextStyle(color: Colors.grey.shade500),
                                        ),
                                      ),
                                    )
                                  else
                                    ...sortedEntries.map((entry) {
                                      final studentId = entry.key;
                                      final response = entry.value;
                                      final displayName = roster?.students[studentId]?.displayName ?? studentId;
                                      
                                      return _StudentRosterCard(
                                        studentId: studentId,
                                        displayName: displayName,
                                        response: response,
                                        period: currentPeriod,
                                        driverId: user.uid,
                                        date: today,
                                        isLocked: status == PollStatus.completed,
                                      );
                                    }),
                                ]),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    // Floating Bottom Action Bar (when dailyBoard is initialized)
                    dailyBoardAsync.maybeWhen(
                      data: (dailyBoard) {
                        if (dailyBoard == null) return const SizedBox.shrink();
                        final parentPoll = parentPollAsync.value;
                        final status = parentPoll?.status ?? PollStatus.uninitiated;
                        return _BottomActionBar(
                          driverId: user.uid,
                          period: _selectedPeriod,
                          status: status,
                          date: today,
                          approachingIds: dailyBoard.approachingStudentIds,
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PeriodTabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PeriodTabButton({
    required this.title,
    required this.isSelected,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    if (isSelected) {
      textColor = Colors.white;
    } else if (isDisabled) {
      textColor = Colors.grey.shade400;
    } else {
      textColor = const Color(0xFF4B5563);
    }

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDisabled ? Colors.grey.shade300 : const Color(0xFF0D9488))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatsSummaryCard extends StatelessWidget {
  final PollStatus status;
  final int ridingCount;
  final int boardedCount;
  final int notRidingCount;
  final int noResponseCount;

  const _StatsSummaryCard({
    required this.status,
    required this.ridingCount,
    required this.boardedCount,
    required this.notRidingCount,
    required this.noResponseCount,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status design elements
    final statusColor = switch (status) {
      PollStatus.uninitiated => Colors.grey,
      PollStatus.active => const Color(0xFF0D9488),
      PollStatus.completed => const Color(0xFFF97316),
    };

    final statusText = switch (status) {
      PollStatus.uninitiated => 'Inactive Route',
      PollStatus.active => 'Active Route',
      PollStatus.completed => 'Completed',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ride Status',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == PollStatus.active) ...[
                      _PulsingDot(color: statusColor),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 18),
          Row(
            children: [
              _StatItem(
                label: 'Riding',
                count: ridingCount,
                color: const Color(0xFF0D9488),
              ),
              _StatDivider(),
              _StatItem(
                label: 'Boarded',
                count: boardedCount,
                color: const Color(0xFF0D9488),
                isSolid: true,
              ),
              _StatDivider(),
              _StatItem(
                label: 'Not Riding',
                count: notRidingCount,
                color: Colors.grey.shade500,
              ),
              if (noResponseCount > 0) ...[
                _StatDivider(),
                _StatItem(
                  label: 'No Reply',
                  count: noResponseCount,
                  color: const Color(0xFFF97316),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSolid;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isSolid ? color : const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproachingBanner extends StatelessWidget {
  final List<String> studentIds;
  final Roster? roster;

  const _ApproachingBanner({
    required this.studentIds,
    this.roster,
  });

  @override
  Widget build(BuildContext context) {
    final names = studentIds
        .map((id) => roster?.students[id]?.displayName ?? id)
        .join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Orange soft background
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: Color(0xFFF97316),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Approaching Students',
                  style: TextStyle(
                    color: Color(0xFFEA580C),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  names,
                  style: const TextStyle(
                    color: Color(0xFFC2410C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentRosterCard extends ConsumerWidget {
  final String studentId;
  final String displayName;
  final PollResponse response;
  final PollPeriod period;
  final String driverId;
  final DateTime date;
  final bool isLocked;

  const _StudentRosterCard({
    required this.studentId,
    required this.displayName,
    required this.response,
    required this.period,
    required this.driverId,
    required this.date,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Setup background avatar colors based on status
    final String initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    Color statusBadgeColor;
    String statusBadgeText;
    IconData statusIcon;

    if (response.answer == true) {
      statusBadgeColor = const Color(0xFF0D9488); // Teal
      statusBadgeText = 'Riding';
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (response.answer == false) {
      statusBadgeColor = Colors.grey.shade500;
      statusBadgeText = 'Not Riding';
      statusIcon = Icons.cancel_outlined;
    } else {
      statusBadgeColor = const Color(0xFFF97316); // Orange
      statusBadgeText = 'No Reply';
      statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: response.boarded
            ? Border.all(color: const Color(0xFF0D9488).withOpacity(0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Initials Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: response.boarded
                ? const Color(0xFF0D9488)
                : statusBadgeColor.withOpacity(0.1),
            child: Text(
              initials,
              style: TextStyle(
                color: response.boarded ? Colors.white : statusBadgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Student Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: const Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: response.boarded ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusBadgeColor),
                    const SizedBox(width: 4),
                    Text(
                      statusBadgeText,
                      style: TextStyle(
                        color: statusBadgeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (period == PollPeriod.evening && response.checkpoint != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          response.checkpoint!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Boarding Action Toggle
          if (response.answer != false) ...[
            _BoardToggleButton(
              isBoarded: response.boarded,
              isDisabled: isLocked,
              onChanged: isLocked
                  ? (val) {}
                  : (newValue) {
                      ref.read(pollActionsProvider).updateStudentBoarded(
                            driverId: driverId,
                            period: period,
                            studentId: studentId,
                            date: date,
                            boarded: newValue,
                          );
                    },
            ),
          ] else
            // Explicitly show X / Disabled state for Non-riders
            Icon(Icons.remove_circle_outline_rounded, color: Colors.grey.shade300, size: 28),
        ],
      ),
    );
  }
}

class _BoardToggleButton extends StatelessWidget {
  final bool isBoarded;
  final bool isDisabled;
  final ValueChanged<bool> onChanged;

  const _BoardToggleButton({
    required this.isBoarded,
    this.isDisabled = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDisabled ? Colors.grey.shade400 : const Color(0xFF0D9488);
    return GestureDetector(
      onTap: isDisabled ? null : () => onChanged(!isBoarded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isBoarded
              ? activeColor
              : (isDisabled ? Colors.grey.shade100 : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activeColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBoarded ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 16,
              color: isBoarded ? Colors.white : activeColor,
            ),
            const SizedBox(width: 6),
            Text(
              isBoarded ? 'Boarded' : 'Board',
              style: TextStyle(
                color: isBoarded ? Colors.white : activeColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends ConsumerWidget {
  final String driverId;
  final PollPeriod period;
  final PollStatus status;
  final DateTime date;
  final List<String> approachingIds;

  const _BottomActionBar({
    required this.driverId,
    required this.period,
    required this.status,
    required this.date,
    required this.approachingIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status-dependent Controls
            if (status == PollStatus.uninitiated)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(pollActionsProvider).startRide(
                          driverId: driverId,
                          period: period,
                        );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              )
            else if (status == PollStatus.active) ...[
              // Ping Next Student Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final pingedUid = await ref
                          .read(pollActionsProvider)
                          .markNextStudentApproaching(
                            driverId: driverId,
                            period: period,
                            date: date,
                          );

                      if (context.mounted) {
                        if (pingedUid != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pinged next student!'),
                              backgroundColor: const Color(0xFFF97316),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All active students are already boarded or approaching.'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('Alert Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // End Route Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('End Ride'),
                          content: const Text('Are you sure you want to end this ride?'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                ref.read(pollActionsProvider).completeRide(
                                      driverId: driverId,
                                      period: period,
                                      date: date,
                                    );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('End Ride'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('End Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Navigation Button
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Navigation coming soon.')),
                    );
                  },
                  icon: const Icon(Icons.navigation_rounded, color: Color(0xFF0D9488)),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ] else if (status == PollStatus.completed)
              const Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFFF97316)),
                      SizedBox(width: 8),
                      Text(
                        'Route Completed & Locked',
                        style: TextStyle(
                          color: Color(0xFFF97316),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline_rounded, color: Color(0xFF0D9488)),
                        SizedBox(width: 16),
                        Text(
                          'Driver Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () async {
                        await ref.read(authServiceProvider).signOut();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
