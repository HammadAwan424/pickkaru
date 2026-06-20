import 'package:flutter/material.dart';
import '../../../../../shared/poll/models/DailyPollBoard.dart';

class PollRowSurface extends StatelessWidget {
  const PollRowSurface({
    super.key,
    required this.response,
    required this.isApproaching,
    required this.builder,
  });

  final PollResponse? response;
  final bool isApproaching;
  final Widget Function(BuildContext context, Color avatarBg, Color avatarFg)
      builder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = _rowTint(colors, response, isApproaching);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint.background,
        border: Border.all(color: tint.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: builder(context, tint.avatarBackground, tint.avatarForeground),
      ),
    );
  }

  _RowTintData _rowTint(
    ColorScheme colors,
    PollResponse? response,
    bool isApproaching,
  ) {
    if (response?.boarded == true) {
      return _RowTintData(
        background: Colors.green.withValues(alpha: 0.11),
        border: Colors.green.withValues(alpha: 0.45),
        avatarBackground: Colors.green.shade700,
        avatarForeground: Colors.white,
      );
    }

    if (isApproaching) {
      return _RowTintData(
        background: Colors.amber.withValues(alpha: 0.17),
        border: Colors.amber.withValues(alpha: 0.55),
        avatarBackground: Colors.amber.shade700,
        avatarForeground: Colors.black,
      );
    }

    if (response?.answer == false) {
      return _RowTintData(
        background: colors.errorContainer.withValues(alpha: 0.44),
        border: colors.error.withValues(alpha: 0.45),
        avatarBackground: colors.error,
        avatarForeground: colors.onError,
      );
    }

    return _RowTintData(
      background: colors.surface,
      border: colors.outlineVariant,
      avatarBackground: colors.secondaryContainer,
      avatarForeground: colors.onSecondaryContainer,
    );
  }
}

class _RowTintData {
  const _RowTintData({
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
