import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/driver/trip/providers/driver_trip_providers.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/shared/date/format_date.dart';

import 'components/driver_header.dart';
import 'components/trip_leg_view.dart';
import 'components/trip_action_bar.dart';

class DriverDashboardPage extends ConsumerStatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  ConsumerState<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends ConsumerState<DriverDashboardPage> {
  TripLegDirection _selectedDirection = TripLegDirection.pickup;

  @override
  Widget build(BuildContext context) {
    // 1. Get the currently active trip state
    final activeTripState = ref.watch(requireDriverActiveTripProvider);
    final trip = activeTripState.trip;
    final date = activeTripState.date;

    // 2. We can optionally fetch the trip run to see if it's started/completed
    final tripRun = ref.watch(requireDriverTripRunProvider);
    final runState = tripRun?.trips[trip.id];
    final isStarted = runState?.startedAt != null;
    final isCompleted = runState?.completedAt != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                DriverHeader(
                  tripName: trip.name,
                  date: date,
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: SegmentedButton<TripLegDirection>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white,
                      selectedBackgroundColor: const Color(0xFF0D9488),
                      selectedForegroundColor: Colors.white,
                    ),
                    segments: const [
                      ButtonSegment(
                        value: TripLegDirection.pickup, 
                        label: Text('Pickup Leg'),
                        icon: Icon(Icons.flight_takeoff_rounded),
                      ),
                      ButtonSegment(
                        value: TripLegDirection.dropoff, 
                        label: Text('Dropoff Leg'),
                        icon: Icon(Icons.flight_land_rounded),
                      ),
                    ],
                    selected: {_selectedDirection},
                    onSelectionChanged: (set) {
                      setState(() => _selectedDirection = set.first);
                    },
                  ),
                ),

                Expanded(
                  child: TripLegView(
                    trip: trip,
                    direction: _selectedDirection,
                    date: date,
                    isTripStarted: isStarted,
                    isTripCompleted: isCompleted,
                  ),
                ),
              ],
            ),
            
            // Floating Action Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TripActionBar(
                tripId: trip.id,
                date: date,
                isStarted: isStarted,
                isCompleted: isCompleted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
