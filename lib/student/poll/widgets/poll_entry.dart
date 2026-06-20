import 'package:flutter/material.dart';
import '../../../shared/poll/models/DailyPollBoard.dart';

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
    final colors = Theme.of(context).colorScheme;
    final tint = _rowTint(colors, response, isApproaching);
    final displayName = studentName.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.background,
        border: Border.all(color: tint.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: tint.avatarBackground,
              foregroundColor: tint.avatarForeground,
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
            _StatusPill(
              response: response,
              isApproaching: isApproaching,
            ),
          ],
        ),
      ),
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
