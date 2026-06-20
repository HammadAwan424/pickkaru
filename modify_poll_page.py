import re

with open('lib/student/poll/student_poll_page.dart', 'r') as f:
    content = f.read()

# 1. Add imports
content = content.replace(
    "import '../overrides/student_planning_page.dart';",
    "import '../overrides/student_planning_page.dart';\nimport 'widgets/poll_entry.dart';\nimport 'widgets/student_controls.dart';"
)

# 2. Add StudentControls
target = """                                          ],
                                        ),
                                      ),
                                    ],
                                  );"""
replacement = """                                          ],
                                        ),
                                      ),
                                      if (poll.status != PollStatus.completed)
                                        StudentControls(
                                          period: _period,
                                          response: _period == PollPeriod.morning
                                              ? morningDailyBoard?.responses[user.uid]
                                              : eveningDailyBoard?.responses[user.uid],
                                          checkpoints: _period == PollPeriod.morning
                                              ? polls.morning.checkpoints ?? const []
                                              : polls.evening.checkpoints ?? const [],
                                        ),
                                    ],
                                  );"""
content = content.replace(target, replacement)

# 3. Replace _StudentPollRow with PollEntryRow
target2 = """        return _StudentPollRow(
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
        );"""
replacement2 = """        return PollEntryRow(
          studentId: studentId,
          studentName: publicStudent.displayName ?? 'Student',
          response: response,
          isApproaching: dailyBoard!.approachingStudentIds.contains(studentId),
        );"""
content = content.replace(target2, replacement2)

# 4. Remove classes from _StudentPollRow to before _PeriodSwitcher
# _StudentPollRow starts with "class _StudentPollRow extends ConsumerStatefulWidget {"
# _PeriodSwitcher starts with "class _PeriodSwitcher extends StatelessWidget {"
start_idx = content.find("class _StudentPollRow extends ConsumerStatefulWidget {")
end_idx = content.find("class _PeriodSwitcher extends StatelessWidget {")
if start_idx != -1 and end_idx != -1:
    content = content[:start_idx] + content[end_idx:]

# 5. Remove _StatusPill to the end, but keep _PollScaffold, _EmptyState, _ErrorState, _PublicStudent
# Actually, the file has _StatusPill, _PollScaffold, _EmptyState, _ErrorState, _PublicStudent, _RowTint, _PollStatus, etc.
# We want to remove _StatusPill, _RowTint, _PollStatus, _rowTint, _statusFor, _initialFor, _dropdownValue
# Let's just remove _StatusPill class
pill_start = content.find("class _StatusPill extends StatelessWidget {")
pill_end = content.find("class _PollScaffold extends StatelessWidget {")
if pill_start != -1 and pill_end != -1:
    content = content[:pill_start] + content[pill_end:]

# 6. Remove _RowTint and everything after it to the end
row_tint_start = content.find("class _RowTint {")
if row_tint_start != -1:
    content = content[:row_tint_start]

with open('lib/student/poll/student_poll_page.dart', 'w') as f:
    f.write(content)

print("Modifications done.")
