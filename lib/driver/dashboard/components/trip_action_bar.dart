import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/driver/trip/notifiers/driver_trip_run_notifier.dart';
import 'package:pickkaru/shared/date/format_date.dart';

class TripActionBar extends ConsumerStatefulWidget {
  final String tripId;
  final DateTime date;
  final bool isStarted;
  final bool isCompleted;

  const TripActionBar({
    super.key,
    required this.tripId,
    required this.date,
    required this.isStarted,
    required this.isCompleted,
  });

  @override
  ConsumerState<TripActionBar> createState() => _TripActionBarState();
}

class _TripActionBarState extends ConsumerState<TripActionBar> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Trip Completed',
              style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final dateStr = formatDate(widget.date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isStarted ? const Color(0xFFF59E0B) : const Color(0xFF0D9488),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _isLoading
            ? null
            : () async {
                setState(() => _isLoading = true);
                try {
                  final notifier = ref.read(driverTripRunNotifierProvider(dateStr).notifier);
                  if (widget.isStarted) {
                    await notifier.completeTrip(tripId: widget.tripId, now: DateTime.now());
                  } else {
                    await notifier.startTrip(tripId: widget.tripId, now: DateTime.now());
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
            : Text(
                widget.isStarted ? 'Complete Trip' : 'Start Trip',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
