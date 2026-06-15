import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../models/poll.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/poll_provider.dart';
import '../../providers/roster_provider.dart';
import '../../providers/student_provider.dart';
import 'student_planning_page.dart';

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
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const _PollScaffold(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _PollScaffold(
        child: _ErrorState(message: 'Could not load your profile: $error'),
      ),
      data: (user) {
        if (user == null) {
          return const _PollScaffold(
            child: _EmptyState(message: 'Sign in to view your route poll.'),
          );
        }

        final studentAsync = ref.watch(studentProvider(user.uid));
        return studentAsync.when(
          loading: () => const _PollScaffold(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _PollScaffold(
            child: _ErrorState(
                message: 'Could not load your student record: $error'),
          ),
          data: (student) {
            final driverId = student?.assignedDriverId;
            if (driverId == null || driverId.isEmpty) {
              return const _PollScaffold(
                child: _EmptyState(message: 'No driver is assigned yet.'),
              );
            }

            final activeDateAsync = ref.watch(activeDateProvider(driverId));
            final driverAsync = ref.watch(driverProvider(driverId));
            final pollsAsync = ref.watch(driverPollsProvider(driverId));

            return activeDateAsync.when(
              loading: () => const _PollScaffold(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _PollScaffold(
                child: _ErrorState(message: 'Could not load active date: $error'),
              ),
              data: (activeDate) {
                final morningDailyBoardAsync = ref.watch(dailyBoardProvider(DailyBoardArgs(
                  driverId: driverId,
                  period: PollPeriod.morning,
                  date: activeDate,
                )));

                final eveningDailyBoardAsync = ref.watch(dailyBoardProvider(DailyBoardArgs(
                  driverId: driverId,
                  period: PollPeriod.evening,
                  date: activeDate,
                )));

                return _PollScaffold(
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
                      child: _PeriodSwitcher(
                        period: _period,
                        onChanged: _showPeriod,
                      ),
                    ),
                  ],
                  child: driverAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _ErrorState(
                      message: 'Could not load your driver route: $error',
                    ),
                    data: (driver) {
                      if (driver == null) {
                        return const _EmptyState(
                            message: 'Driver route was not found.');
                      }

                      return pollsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => _ErrorState(
                          message: 'Could not load today\'s polls: $error',
                        ),
                        data: (polls) {
                          return morningDailyBoardAsync.when(
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (error, _) => _ErrorState(
                              message: 'Error loading morning ride board: $error',
                            ),
                            data: (morningDailyBoard) {
                              return eveningDailyBoardAsync.when(
                                loading: () =>
                                    const Center(child: CircularProgressIndicator()),
                                error: (error, _) => _ErrorState(
                                  message: 'Error loading evening ride board: $error',
                                ),
                                data: (eveningDailyBoard) {
                                  final poll = _period == PollPeriod.morning
                                      ? polls.morning
                                      : polls.evening;

                                  final currentDailyBoard = _period == PollPeriod.morning
                                      ? morningDailyBoard
                                      : eveningDailyBoard;

                                  final rosterAsync = ref.watch(rosterProvider(driverId));
                                  final roster = rosterAsync.valueOrNull?.students.map(
                                        (studentId, entry) => MapEntry(
                                          studentId,
                                          _PublicStudent(
                                            displayName: entry.displayName,
                                          ),
                                        ),
                                      ) ?? <String, _PublicStudent>{};

                                  return Column(
                                    children: [
                                      if (poll.status == PollStatus.active && currentDailyBoard != null)
                                        _RideStatusBanner(
                                          driverId: driverId,
                                          period: _period,
                                        ),
                                      Expanded(
                                        child: PageView(
                                          controller: _pageController,
                                          onPageChanged: (index) {
                                            setState(() {
                                              _period = PollPeriod.values[index];
                                            });
                                          },
                                          children: [
                                            _PollPeriodView(
                                              driverId: driverId,
                                              currentStudentId: user.uid,
                                              currentDisplayName: user.displayName,
                                              assignedStudentIds: driver.assignedStudents,
                                              roster: roster,
                                              period: PollPeriod.morning,
                                              dailyBoard: morningDailyBoard,
                                              checkpoints: polls.morning.checkpoints ?? const [],
                                              targetDate: activeDate,
                                              isLocked: polls.morning.status == PollStatus.completed,
                                            ),
                                            _PollPeriodView(
                                              driverId: driverId,
                                              currentStudentId: user.uid,
                                              currentDisplayName: user.displayName,
                                              assignedStudentIds: driver.assignedStudents,
                                              roster: roster,
                                              period: PollPeriod.evening,
                                              dailyBoard: eveningDailyBoard,
                                              checkpoints: polls.evening.checkpoints ?? const [],
                                              targetDate: activeDate,
                                              isLocked: polls.evening.status == PollStatus.completed,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
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

class _RideStatusBanner extends ConsumerWidget {
  const _RideStatusBanner({
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

class _PollPeriodView extends ConsumerWidget {
  const _PollPeriodView({
    required this.driverId,
    required this.currentStudentId,
    required this.currentDisplayName,
    required this.assignedStudentIds,
    required this.roster,
    required this.period,
    required this.dailyBoard,
    required this.checkpoints,
    required this.targetDate,
    required this.isLocked,
  });

  final String driverId;
  final String currentStudentId;
  final String currentDisplayName;
  final List<String> assignedStudentIds;
  final Map<String, _PublicStudent> roster;
  final PollPeriod period;
  final Poll? dailyBoard;
  final List<String> checkpoints;
  final DateTime targetDate;
  final bool isLocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (dailyBoard == null) {
      return _EmptyState(
        message: "The driver has not initialized the ${period == PollPeriod.morning ? 'morning' : 'evening'} ride yet.",
      );
    }

    if (assignedStudentIds.isEmpty) {
      return const _EmptyState(
          message: 'No students are assigned to this route.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemBuilder: (context, index) {
        final studentId = assignedStudentIds[index];
        final response = dailyBoard!.responses[studentId];
        final publicStudent = roster[studentId] ??
            _PublicStudent(
              displayName:
                  studentId == currentStudentId ? currentDisplayName : null,
            );

        return _StudentPollRow(
          driverId: driverId,
          studentId: studentId,
          isCurrentStudent: studentId == currentStudentId,
          publicStudent: publicStudent,
          period: period,
          checkpoints: checkpoints,
          response: response,
          isApproaching: dailyBoard!.approachingStudentIds.contains(studentId),
          targetDate: targetDate,
          isLocked: isLocked,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: assignedStudentIds.length,
    );
  }
}

class _StudentPollRow extends ConsumerStatefulWidget {
  const _StudentPollRow({
    required this.driverId,
    required this.studentId,
    required this.isCurrentStudent,
    required this.publicStudent,
    required this.period,
    required this.checkpoints,
    required this.response,
    required this.isApproaching,
    required this.targetDate,
    required this.isLocked,
  });

  final String driverId;
  final String studentId;
  final bool isCurrentStudent;
  final _PublicStudent publicStudent;
  final PollPeriod period;
  final List<String> checkpoints;
  final PollResponse? response;
  final bool isApproaching;
  final DateTime targetDate;
  final bool isLocked;

  @override
  ConsumerState<_StudentPollRow> createState() => _StudentPollRowState();
}

class _StudentPollRowState extends ConsumerState<_StudentPollRow> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final response = widget.response;
    final tint = _rowTint(colors, response, widget.isApproaching);
    final displayName = widget.publicStudent.displayName?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.background,
        border: Border.all(color: tint.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: tint.avatarBackground,
                  foregroundColor: tint.avatarForeground,
                  child: Text(_initialFor(displayName, widget.studentId)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName == null || displayName.isEmpty
                            ? 'Student'
                            : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  response: response,
                  isApproaching: widget.isApproaching,
                ),
              ],
            ),
            if (widget.isCurrentStudent) ...[
              const SizedBox(height: 12),
              _StudentControls(
                answer: response?.answer,
                boarded: response?.boarded == true,
                period: widget.period,
                checkpoints: widget.checkpoints,
                checkpoint: response?.checkpoint,
                isSaving: _isSaving,
                isLocked: widget.isLocked,
                canMarkBoarded: response != null,
                onAnswerChanged: (answer) => _save(
                  () => ref.read(pollActionsProvider).updateStudentResponse(
                        driverId: widget.driverId,
                        period: widget.period,
                        studentId: widget.studentId,
                        date: widget.targetDate,
                        answer: answer,
                      ),
                ),
                onCheckpointChanged: widget.period == PollPeriod.evening
                    ? (checkpoint) => _save(
                            () => ref
                                .read(pollActionsProvider)
                                .updateStudentResponse(
                                  driverId: widget.driverId,
                                  period: widget.period,
                                  studentId: widget.studentId,
                                  date: widget.targetDate,
                                  updateAnswer: false,
                                  checkpoint: checkpoint,
                                  updateCheckpoint: true,
                                ),
                        )
                    : null,
                onMarkBoarded: response?.boarded == true
                    ? null
                    : () => _save(
                          () =>
                              ref.read(pollActionsProvider).markStudentBoarded(
                                    driverId: widget.driverId,
                                    period: widget.period,
                                    studentId: widget.studentId,
                                    date: widget.targetDate,
                                  ),
                        ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(Future<void> Function() action) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      
      String message = 'Could not save poll response: $error';
      if (error is FirebaseException && (error.code == 'not-found' || error.code == 'NOT_FOUND')) {
        message = "The driver hasn't started today's poll yet.";
      } else if (error.toString().contains('not-found') || error.toString().contains('NOT_FOUND')) {
        message = "The driver hasn't started today's poll yet.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _StudentControls extends StatelessWidget {
  const _StudentControls({
    required this.answer,
    required this.boarded,
    required this.period,
    required this.checkpoints,
    required this.checkpoint,
    required this.isSaving,
    required this.isLocked,
    required this.canMarkBoarded,
    required this.onAnswerChanged,
    required this.onCheckpointChanged,
    required this.onMarkBoarded,
  });

  final bool? answer;
  final bool boarded;
  final PollPeriod period;
  final List<String> checkpoints;
  final String? checkpoint;
  final bool isSaving;
  final bool isLocked;
  final bool canMarkBoarded;
  final ValueChanged<bool> onAnswerChanged;
  final ValueChanged<String?>? onCheckpointChanged;
  final VoidCallback? onMarkBoarded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _CustomChoiceButton(
                label: 'Yes',
                icon: Icons.check_circle_outline,
                isSelected: answer == true,
                isLocked: isSaving || isLocked,
                activeBgColor: const Color(0xFF0D9488),
                activeFgColor: Colors.white,
                onTap: () => onAnswerChanged(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CustomChoiceButton(
                label: 'No',
                icon: Icons.cancel_outlined,
                isSelected: answer == false,
                isLocked: isSaving || isLocked,
                activeBgColor: Colors.red.shade600,
                activeFgColor: Colors.white,
                onTap: () => onAnswerChanged(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed:
                isSaving || boarded || !canMarkBoarded || isLocked ? null : onMarkBoarded,
            icon: boarded
                ? const Icon(Icons.task_alt)
                : const Icon(Icons.directions_bus_filled_outlined),
            label: Text(boarded ? 'Boarded' : 'Mark boarded'),
          ),
        ),
        if (period == PollPeriod.evening) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _dropdownValue(checkpoints, checkpoint),
            decoration: const InputDecoration(
              labelText: 'Evening checkpoint',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No checkpoint selected'),
              ),
              for (final checkpoint in checkpoints)
                DropdownMenuItem<String?>(
                  value: checkpoint,
                  child: Text(
                    checkpoint,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: isSaving || isLocked ? null : onCheckpointChanged,
          ),
        ],
        if (isSaving) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            minHeight: 2,
            color: colors.primary,
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ],
      ],
    );
  }
}

class _CustomChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isLocked;
  final Color activeBgColor;
  final Color activeFgColor;
  final VoidCallback? onTap;

  const _CustomChoiceButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.isLocked = false,
    required this.activeBgColor,
    required this.activeFgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected 
        ? (isLocked ? activeBgColor.withAlpha(153) : activeBgColor) 
        : const Color(0xFFF3F4F6);
    final fgColor = isSelected 
        ? (isLocked ? activeFgColor.withAlpha(153) : activeFgColor) 
        : (isLocked ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563));

    return InkWell(
      onTap: isLocked ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? (isLocked ? activeBgColor.withAlpha(153) : activeBgColor) 
                : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected && !isLocked
              ? [
                  BoxShadow(
                    color: activeBgColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSwitcher extends StatelessWidget {
  const _PeriodSwitcher({
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.response,
    required this.isApproaching,
  });

  final PollResponse? response;
  final bool isApproaching;

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(response, isApproaching);
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.background(colors),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 15, color: status.foreground(colors)),
            const SizedBox(width: 5),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: status.foreground(colors),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollScaffold extends StatelessWidget {
  const _PollScaffold({
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

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

class _PublicStudent {
  const _PublicStudent({
    this.displayName,
  });

  final String? displayName;
}

class _RowTint {
  const _RowTint({
    required this.background,
    required this.border,
    required this.avatarBackground,
    required this.avatarForeground,
  });

  final Color background;
  final Color border;
  final Color avatarBackground;
  final Color avatarForeground;
}

class _PollStatus {
  const _PollStatus({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final IconData icon;
  final Color Function(ColorScheme colors) background;
  final Color Function(ColorScheme colors) foreground;
}

_RowTint _rowTint(
  ColorScheme colors,
  PollResponse? response,
  bool isApproaching,
) {
  if (response?.boarded == true) {
    return _RowTint(
      background: Colors.green.withValues(alpha: 0.11),
      border: Colors.green.withValues(alpha: 0.45),
      avatarBackground: Colors.green.shade700,
      avatarForeground: Colors.white,
    );
  }

  if (isApproaching) {
    return _RowTint(
      background: Colors.amber.withValues(alpha: 0.17),
      border: Colors.amber.withValues(alpha: 0.55),
      avatarBackground: Colors.amber.shade700,
      avatarForeground: Colors.black,
    );
  }

  if (response?.answer == false) {
    return _RowTint(
      background: colors.errorContainer.withValues(alpha: 0.44),
      border: colors.error.withValues(alpha: 0.45),
      avatarBackground: colors.error,
      avatarForeground: colors.onError,
    );
  }

  return _RowTint(
    background: colors.surface,
    border: colors.outlineVariant,
    avatarBackground: colors.secondaryContainer,
    avatarForeground: colors.onSecondaryContainer,
  );
}

_PollStatus _statusFor(PollResponse? response, bool isApproaching) {
  if (response?.boarded == true) {
    return _PollStatus(
      label: 'Boarded',
      icon: Icons.task_alt,
      background: (_) => Colors.green.withValues(alpha: 0.16),
      foreground: (_) => Colors.green.shade800,
    );
  }

  if (isApproaching) {
    return _PollStatus(
      label: 'Approaching',
      icon: Icons.near_me_outlined,
      background: (_) => Colors.amber.withValues(alpha: 0.24),
      foreground: (_) => Colors.amber.shade900,
    );
  }

  if (response?.answer == false) {
    return _PollStatus(
      label: 'No',
      icon: Icons.cancel_outlined,
      background: (colors) => colors.errorContainer,
      foreground: (colors) => colors.onErrorContainer,
    );
  }

  if (response?.answer == true) {
    return _PollStatus(
      label: 'Yes',
      icon: Icons.check_circle_outline,
      background: (colors) => colors.secondaryContainer,
      foreground: (colors) => colors.onSecondaryContainer,
    );
  }

  return _PollStatus(
    label: 'Pending',
    icon: Icons.radio_button_unchecked,
    background: (colors) => colors.surfaceContainerHighest,
    foreground: (colors) => colors.onSurfaceVariant,
  );
}

String _initialFor(String? displayName, String studentId) {
  final source = displayName == null || displayName.trim().isEmpty
      ? studentId
      : displayName.trim();
  return source.characters.first.toUpperCase();
}

String? _dropdownValue(List<String> checkpoints, String? checkpoint) {
  if (checkpoint == null) return null;
  return checkpoints.contains(checkpoint) ? checkpoint : null;
}
