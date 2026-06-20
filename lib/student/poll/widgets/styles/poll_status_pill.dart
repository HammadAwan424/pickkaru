import 'package:flutter/material.dart';
import '../../../../../shared/poll/models/DailyPollBoard.dart';

class PollStatusPill extends StatelessWidget {
  const PollStatusPill({
    super.key,
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

  _PollStatusData _statusFor(PollResponse? response, bool isApproaching) {
    if (response?.boarded == true) {
      return _PollStatusData(
        label: 'Boarded',
        icon: Icons.task_alt,
        background: (_) => Colors.green.withValues(alpha: 0.16),
        foreground: (_) => Colors.green.shade800,
      );
    }

    if (isApproaching) {
      return _PollStatusData(
        label: 'Approaching',
        icon: Icons.near_me_outlined,
        background: (_) => Colors.amber.withValues(alpha: 0.24),
        foreground: (_) => Colors.amber.shade900,
      );
    }

    if (response?.answer == false) {
      return _PollStatusData(
        label: 'No',
        icon: Icons.cancel_outlined,
        background: (colors) => colors.errorContainer,
        foreground: (colors) => colors.onErrorContainer,
      );
    }

    if (response?.answer == true) {
      return _PollStatusData(
        label: 'Yes',
        icon: Icons.check_circle_outline,
        background: (colors) => colors.secondaryContainer,
        foreground: (colors) => colors.onSecondaryContainer,
      );
    }

    return _PollStatusData(
      label: 'Pending',
      icon: Icons.radio_button_unchecked,
      background: (colors) => colors.surfaceContainerHighest,
      foreground: (colors) => colors.onSurfaceVariant,
    );
  }
}

class _PollStatusData {
  const _PollStatusData({
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
