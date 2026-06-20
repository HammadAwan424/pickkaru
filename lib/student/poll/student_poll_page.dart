import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/poll/models/DailyPollBoard.dart';
import '../../shared/poll/models/PollPeriod.dart';
import '../../shared/poll/models/PollConfig.dart';
import '../../core/auth/auth_provider.dart';
import '../student_core/providers/student_provider.dart';
import '../overrides/student_planning_page.dart';
import '../../shared/roster/roster_provider.dart';
import 'poll_provider.dart';
import 'widgets/poll_entry.dart';
import 'widgets/student_controls.dart';

class StudentPollPage extends ConsumerStatefulWidget {
  const StudentPollPage({super.key});

  @override
  ConsumerState<StudentPollPage> createState() => _StudentPollPageState();
}

class _StudentPollPageState extends ConsumerState<StudentPollPage> {
  final PageController _pageController = PageController();
  PollPeriod _period = PollPeriod.morning;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // These are guaranteed to be loaded by StudentGateway
    final user = ref.watch(currentUserProvider).requireValue!;
    final student = ref.watch(studentProvider(user.uid)).requireValue!;
    final driverId = student.assignedDriverId!;

    final configAsync = ref.watch(studentWatchPollConfigProvider(_period));
    final dailyBoardAsync = ref.watch(studentDailyBoardProvider(_period));

    return PollScaffold(
      title: 'Route poll',
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: 'Plan ahead',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentPlanningPage(
                  studentId: user.uid,
                  driverId: driverId,
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: PeriodSwitcher(
            period: _period,
            onChanged: _showPeriod,
          ),
        ),
      ],
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _period = PollPeriod.values[index];
                });
              },
              children: [
                PollPeriodView(
                  currentStudentId: user.uid,
                  currentDisplayName: user.displayName,
                  driverId: driverId,
                  period: PollPeriod.morning,
                ),
                PollPeriodView(
                  currentStudentId: user.uid,
                  currentDisplayName: user.displayName,
                  driverId: driverId,
                  period: PollPeriod.evening,
                ),
              ],
            ),
          ),
          if (configAsync.valueOrNull?.status != PollStatus.completed)
            StudentControls(
              period: _period,
              response: dailyBoardAsync.valueOrNull?.responses[user.uid],
              checkpoints: configAsync.valueOrNull?.checkpoints ?? const [],
            ),
        ],
      ),
    );
  }

  void _showPeriod(PollPeriod period) {
    final index = PollPeriod.values.indexOf(period);
    setState(() => _period = period);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }
}

class PollPeriodView extends ConsumerWidget {
  const PollPeriodView({
    required this.currentStudentId,
    required this.currentDisplayName,
    required this.driverId,
    required this.period,
  });

  final String currentStudentId;
  final String? currentDisplayName;
  final String driverId;
  final PollPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyBoardAsync = ref.watch(studentDailyBoardProvider(period));
    final rosterAsync = ref.watch(rosterProvider(driverId));
    final configAsync = ref.watch(studentWatchPollConfigProvider(period));

    if (dailyBoardAsync.isLoading ||
        rosterAsync.isLoading ||
        configAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dailyBoardAsync.hasError ||
        rosterAsync.hasError ||
        configAsync.hasError) {
      return ErrorState(message: 'Error loading board or roster.');
    }

    final dailyBoard = dailyBoardAsync.value;
    final rosterData = rosterAsync.valueOrNull;
    final config = configAsync.value;

    if (dailyBoard == null ||
        config == null ||
        config.status == PollStatus.uninitiated) {
      return EmptyState(
        message:
            "The driver has not initialized the ${period == PollPeriod.morning ? 'morning' : 'evening'} ride yet.",
      );
    }

    final assignedStudentIds = dailyBoard.responses.keys.toList();

    if (assignedStudentIds.isEmpty) {
      return const EmptyState(
          message: 'No students are assigned to this route.');
    }

    final roster = rosterData?.students.map(
          (studentId, entry) => MapEntry(
            studentId,
            PublicStudent(displayName: entry.displayName),
          ),
        ) ??
        <String, PublicStudent>{};

    return Column(
      children: [
        if (config.status == PollStatus.active)
          RideStatusBanner(
            driverId: driverId,
            period: period,
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemBuilder: (context, index) {
              final studentId = assignedStudentIds[index];
              final response = dailyBoard.responses[studentId];
              final publicStudent = roster[studentId] ??
                  PublicStudent(
                    displayName: studentId == currentStudentId
                        ? currentDisplayName
                        : null,
                  );

              return PollEntryRow(
                studentId: studentId,
                studentName: publicStudent.displayName ?? 'Student',
                response: response,
                isApproaching:
                    dailyBoard.approachingStudentIds.contains(studentId),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: assignedStudentIds.length,
          ),
        ),
      ],
    );
  }
}

class RideStatusBanner extends ConsumerWidget {
  const RideStatusBanner({
    required this.driverId,
    required this.period,
  });

  final String driverId;
  final PollPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.green.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ride is active — driver is on the way.',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Track ride — coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.map, size: 18),
            label: const Text('Track Ride'),
          ),
        ],
      ),
    );
  }
}

class PeriodSwitcher extends StatelessWidget {
  const PeriodSwitcher({
    required this.period,
    required this.onChanged,
  });

  final PollPeriod period;
  final ValueChanged<PollPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PollPeriod>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: PollPeriod.morning,
          icon: Icon(Icons.wb_twilight_outlined),
          label: Text('Morning'),
        ),
        ButtonSegment(
          value: PollPeriod.evening,
          icon: Icon(Icons.nights_stay_outlined),
          label: Text('Evening'),
        ),
      ],
      selected: {period},
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

class PollScaffold extends StatelessWidget {
  const PollScaffold({
    required this.child,
    this.title = 'Route poll',
    this.actions,
  });

  final Widget child;
  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(child: child),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
    );
  }
}

class PublicStudent {
  const PublicStudent({
    this.displayName,
  });

  final String? displayName;
}
