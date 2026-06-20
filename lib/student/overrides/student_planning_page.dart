import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pickkaru/shared/poll/models/PollPeriod.dart';
import 'package:pickkaru/shared/poll/models/PrivateOverride.dart';
import 'package:pickkaru/student/poll/poll_provider.dart';
import 'package:pickkaru/student/overrides/override_provider.dart';
import 'package:pickkaru/student/overrides/override_notifier.dart';

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
    final activeDateAsync = ref.watch(studentActiveDateProvider(PollPeriod.morning));
    final activeDate = activeDateAsync.valueOrNull;

    if (activeDate == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
          ),
        ),
      );
    }

    final weekStart = DateTime(activeDate.year, activeDate.month, activeDate.day).add(const Duration(days: 1));
    final overrideWeekAsync = ref.watch(overridesForWeekProvider);

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
            // Period Toggle Selector
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
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final date = weekStart.add(Duration(days: index));

                      return _OverrideDayCard(
                        date: date,
                        weekdayName: _formatWeekday(date),
                        dateString: _formatDateString(date),
                        period: _selectedPeriod,
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

class _OverrideDayCard extends ConsumerWidget {
  final DateTime date;
  final String weekdayName;
  final String dateString;
  final PollPeriod period;

  const _OverrideDayCard({
    required this.date,
    required this.weekdayName,
    required this.dateString,
    required this.period,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PrivateOverride? privateOverride = ref.watch(dailyOverrideProvider(date));
    final bool? currentAnswer = period == PollPeriod.morning
        ? privateOverride?.morningAnswer
        : privateOverride?.eveningAnswer;

    final activeBorderColor = currentAnswer != null ? const Color(0xFF0D9488) : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activeBorderColor,
          width: currentAnswer != null ? 1.5 : 1,
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
                value: currentAnswer,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D9488)),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                onChanged: (newVal) {
                  final notifier = ref.read(overrideNotifierProvider.notifier);
                  if (period == PollPeriod.morning) {
                    notifier.updateMorningAnswer(date, newVal);
                  } else {
                    notifier.updateEveningAnswer(date, newVal);
                  }
                },
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
