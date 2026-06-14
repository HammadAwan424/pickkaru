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
  ConsumerState<StudentPlanningPage> createState() =>
      _StudentPlanningPageState();
}

class _StudentPlanningPageState extends ConsumerState<StudentPlanningPage> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = DateTime.now();
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
      appBar: AppBar(
        title: const Text('Plan ahead'),
      ),
      body: overrideWeekAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (overrides) {
          final overrideMap = {
            for (final entry in overrides) _dateKey(entry.key): entry.value,
          };

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 7,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final date = _weekStart.add(Duration(days: index));
              final dateKey = _dateKey(date);
              final ov = overrideMap[dateKey];
              final isToday = dateKey == _dateKey(DateTime.now());

              return _DayPlanningRow(
                date: date,
                isToday: isToday,
                overrideValue: ov,
                onMorningChanged: (value) =>
                    _saveOverride(date, morningAnswer: value),
                onEveningChanged: (value) =>
                    _saveOverride(date, eveningAnswer: value),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _saveOverride(
    DateTime date, {
    bool? morningAnswer,
    bool? eveningAnswer,
  }) async {
    await ref.read(pollActionsProvider).updateFutureOverride(
          studentId: widget.studentId,
          date: date,
          morningAnswer: morningAnswer,
          eveningAnswer: eveningAnswer,
        );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

enum _OverrideOption { yes, no, default_ }

class _DayPlanningRow extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final PrivateOverride? overrideValue;
  final ValueChanged<bool?> onMorningChanged;
  final ValueChanged<bool?> onEveningChanged;

  const _DayPlanningRow({
    required this.date,
    required this.isToday,
    required this.overrideValue,
    required this.onMorningChanged,
    required this.onEveningChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dayName = _dayName(date.weekday);
    final dayNum = date.day.toString();
    final monthName = _monthName(date.month);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : dayName,
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$monthName $dayNum',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _PeriodDropdown(
              label: 'Morning',
              value: overrideValue?.morningAnswer,
              onChanged: onMorningChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PeriodDropdown(
              label: 'Evening',
              value: overrideValue?.eveningAnswer,
              onChanged: onEveningChanged,
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(int weekday) {
    const names = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month - 1];
  }
}

class _PeriodDropdown extends StatelessWidget {
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _PeriodDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    _OverrideOption selected;
    if (value == true) {
      selected = _OverrideOption.yes;
    } else if (value == false) {
      selected = _OverrideOption.no;
    } else {
      selected = _OverrideOption.default_;
    }

    return DropdownButtonFormField<_OverrideOption>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(
          value: _OverrideOption.default_,
          child: Text('Default'),
        ),
        DropdownMenuItem(
          value: _OverrideOption.yes,
          child: Text('Yes'),
        ),
        DropdownMenuItem(
          value: _OverrideOption.no,
          child: Text('No'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        switch (value) {
          case _OverrideOption.yes:
            onChanged(true);
          case _OverrideOption.no:
            onChanged(false);
          case _OverrideOption.default_:
            onChanged(null);
        }
      },
    );
  }
}
