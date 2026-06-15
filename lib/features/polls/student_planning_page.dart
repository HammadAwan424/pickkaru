import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/poll.dart';
import '../../providers/poll_provider.dart';

class StudentPlanningPage extends ConsumerStatefulWidget {
  final String studentId;
  final String driverId;

  const StudentPlanningPage({
    super.key,
    required this.studentId,
    required this.driverId,
  });

  @override
  ConsumerState<StudentPlanningPage> createState() => _StudentPlanningPageState();
}

class _StudentPlanningPageState extends ConsumerState<StudentPlanningPage> {
  PollPeriod _selectedPeriod = PollPeriod.morning;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Normalize tomorrow to midnight so that the start date is stable
    _weekStart = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  String _formatWeekday(DateTime date) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  String _formatDateString(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final overrideWeekAsync = ref.watch(
      overridesForWeekProvider(
        OverrideWeekArgs(
          studentId: widget.studentId,
          start: _weekStart,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Ride Planning',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Period Toggle Selector (Matches Driver Command Center tab switcher)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Container(
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
                        isSelected: _selectedPeriod == PollPeriod.morning,
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
                        isSelected: _selectedPeriod == PollPeriod.evening,
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
            ),

            // Schedule Info Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '7-Day Commute Schedule',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Overrides Weekly List
            Expanded(
              child: overrideWeekAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Error loading overrides: $err',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (overrides) {
                  // Map list of entries to a calendar date string map for quick lookup
                  final overrideMap = {
                    for (final entry in overrides) _formatDateKey(entry.key): entry.value,
                  };

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date = _weekStart.add(Duration(days: index));
                      final dateKey = _formatDateKey(date);
                      final privateOverride = overrideMap[dateKey];

                      return _OverrideDayCard(
                        date: date,
                        weekdayName: _formatWeekday(date),
                        dateString: _formatDateString(date),
                        overrideValue: privateOverride,
                        period: _selectedPeriod,
                        studentId: widget.studentId,
                        onChanged: (newVal) async {
                          final isMorning = _selectedPeriod == PollPeriod.morning;
                          await ref.read(pollActionsProvider).updateFutureOverride(
                                studentId: widget.studentId,
                                date: date,
                                morningAnswer: isMorning ? newVal : null,
                                updateMorning: isMorning,
                                eveningAnswer: !isMorning ? newVal : null,
                                updateEvening: !isMorning,
                              );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _PeriodTabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OverrideDayCard extends StatelessWidget {
  final DateTime date;
  final String weekdayName;
  final String dateString;
  final PrivateOverride? overrideValue;
  final PollPeriod period;
  final String studentId;
  final ValueChanged<bool?> onChanged;

  const _OverrideDayCard({
    required this.date,
    required this.weekdayName,
    required this.dateString,
    required this.overrideValue,
    required this.period,
    required this.studentId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool? answer = period == PollPeriod.morning
        ? overrideValue?.morningAnswer
        : overrideValue?.eveningAnswer;

    final activeBorderColor = answer != null ? const Color(0xFF0D9488) : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activeBorderColor,
          width: answer != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weekdayName,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateString,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Custom styled dropdown selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<bool?>(
                value: answer,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D9488)),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                onChanged: onChanged,
                items: [
                  DropdownMenuItem<bool?>(
                    value: null,
                    child: Text(
                      'Default',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                  const DropdownMenuItem<bool?>(
                    value: true,
                    child: Text(
                      'Yes',
                      style: TextStyle(color: Color(0xFF0D9488)),
                    ),
                  ),
                  DropdownMenuItem<bool?>(
                    value: false,
                    child: Text(
                      'No',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
