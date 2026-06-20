import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/poll/models/DailyPollBoard.dart';
import '../../../shared/poll/models/PollPeriod.dart';
import '../response_form_notifier.dart';
import 'styles/poll_bottom_panel.dart';
import 'styles/custom_choice_button.dart';

class StudentControls extends ConsumerWidget {
  const StudentControls({
    super.key,
    required this.period,
    required this.response,
    required this.checkpoints,
  });

  final PollPeriod period;
  final PollResponse? response;
  final List<String> checkpoints;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final formState = ref.watch(responseFormNotifierProvider(period));
    final isSaving = formState.isLoading;

    final draft = formState.valueOrNull;
    final answer = draft?.answer;
    final checkpoint = draft?.checkpoint;

    final boarded = response?.boarded == true;
    final canMarkBoarded = response != null;

    void handleAnswerChanged(bool newAnswer) {
      ref.read(responseFormNotifierProvider(period).notifier).updateResponse(
            newAnswer: newAnswer,
            newCheckpoint: checkpoint,
          );
    }

    void handleCheckpointChanged(String? newCheckpoint) {
      ref.read(responseFormNotifierProvider(period).notifier).updateResponse(
            newAnswer: answer ?? false,
            newCheckpoint: newCheckpoint,
          );
    }

    void handleMarkBoarded() {
      ref.read(responseFormNotifierProvider(period).notifier).markBoarded();
    }

    return PollBottomPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomChoiceButton(
                  label: 'Yes',
                  icon: Icons.check_circle_outline,
                  isSelected: answer == true,
                  isLocked: isSaving,
                  activeBgColor: const Color(0xFF0D9488),
                  activeFgColor: Colors.white,
                  onTap: () => handleAnswerChanged(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomChoiceButton(
                  label: 'No',
                  icon: Icons.cancel_outlined,
                  isSelected: answer == false,
                  isLocked: isSaving,
                  activeBgColor: Colors.red.shade600,
                  activeFgColor: Colors.white,
                  onTap: () => handleAnswerChanged(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: isSaving || boarded || !canMarkBoarded
                  ? null
                  : handleMarkBoarded,
              icon: boarded
                  ? const Icon(Icons.task_alt)
                  : const Icon(Icons.directions_bus_filled_outlined),
              label: Text(boarded ? 'Boarded' : 'Mark boarded'),
            ),
          ),
          if (period == PollPeriod.evening) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _dropdownValue(checkpoints, checkpoint),
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
                for (final cp in checkpoints)
                  DropdownMenuItem<String?>(
                    value: cp,
                    child: Text(
                      cp,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: isSaving ? null : handleCheckpointChanged,
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
      ),
    );
  }

  String? _dropdownValue(List<String> checkpoints, String? checkpoint) {
    if (checkpoint == null) return null;
    return checkpoints.contains(checkpoint) ? checkpoint : null;
  }
}
