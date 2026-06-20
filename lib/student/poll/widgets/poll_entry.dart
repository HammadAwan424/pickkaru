import 'package:flutter/material.dart';
import '../../../shared/poll/models/DailyPollBoard.dart';
import 'styles/poll_row_surface.dart';
import 'styles/poll_status_pill.dart';

class PollEntryRow extends StatelessWidget {
  const PollEntryRow({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.response,
    required this.isApproaching,
  });

  final String studentId;
  final String studentName;
  final PollResponse? response;
  final bool isApproaching;

  @override
  Widget build(BuildContext context) {
    final displayName = studentName.trim();

    return PollRowSurface(
      response: response,
      isApproaching: isApproaching,
      builder: (context, avatarBg, avatarFg) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: avatarBg,
              foregroundColor: avatarFg,
              child: Text(_initialFor(displayName, studentId)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayName.isEmpty ? 'Student' : displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            PollStatusPill(
              response: response,
              isApproaching: isApproaching,
            ),
          ],
        );
      },
    );
  }

  String _initialFor(String? displayName, String studentId) {
    final source = displayName == null || displayName.trim().isEmpty
        ? studentId
        : displayName.trim();
    return source.characters.first.toUpperCase();
  }
}
