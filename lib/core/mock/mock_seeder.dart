import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pickkaru/core/user/user_service.dart';
import 'package:pickkaru/core/user/user.dart';
import 'package:pickkaru/driver/driver_core/services/driver_service.dart';
import 'package:pickkaru/driver/driver_core/Driver.dart';
import 'package:pickkaru/student/student_core/services/student_service.dart';
import 'package:pickkaru/core/auth/auth_service.dart';
import 'package:pickkaru/student/student_core/Student.dart';
import 'package:pickkaru/core/mock/mock_users.dart';
import 'package:pickkaru/shared/trip/models/models.dart';
import 'package:pickkaru/shared/date/format_date.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pickkaru/firebase_options.dart';

Future<void> seedMockData(ProviderContainer container, String host) async {
  final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
  final _db = FirebaseFirestore.instance;
  
  try {
    await http.delete(Uri.parse('http://$host:8080/emulator/v1/projects/$projectId/databases/(default)/documents'));
    await http.delete(Uri.parse('http://$host:9099/emulator/v1/projects/$projectId/accounts'));
  } catch (e) {
    print('Failed to clear emulators: $e');
  }

  final studentService = container.read(studentServiceProvider);
  final userService = container.read(userServiceProvider);
  final driverService = container.read(driverServiceProvider);
  final authService = container.read(authServiceProvider);

  // 2. Seed Checkpoints
  final checkpoints = [
    CheckpointSet(
      id: 'morning_pickups',
      legType: LegType.driver,
      checkpoints: {
        'default_checkpoint': const Checkpoint(name: 'Main Gate', lat: 31.0, lng: 74.0, order: 1),
        'c2': const Checkpoint(name: 'Side Gate', lat: 31.01, lng: 74.01, order: 2),
      },
      order: ['default_checkpoint', 'c2'],
    ),
    CheckpointSet(
      id: 'noon_dropoffs',
      legType: LegType.driver,
      checkpoints: {
        'default_checkpoint': const Checkpoint(name: 'Market', lat: 31.02, lng: 74.02, order: 1),
      },
      order: ['default_checkpoint'],
    ),
    CheckpointSet(
      id: 'evening_dropoffs',
      legType: LegType.driver,
      checkpoints: {
        'default_checkpoint': const Checkpoint(name: 'Park', lat: 31.03, lng: 74.03, order: 1),
      },
      order: ['default_checkpoint'],
    ),
  ];

  for (var cp in checkpoints) {
    await _db.collection('checkpoints').doc(cp.id).set(cp.toMap());
  }
  
  String? actualFirstDriverUid;

  // 3. Seed Drivers
  for (final mockDriver in mockDriverTokens) {
    final tokenData = jsonDecode(mockDriver['token']!);
    final email = tokenData['email'] as String;
    final username = email.split('@').first;
    final displayName = mockDriver['label']!;

    final user = await authService.signInWithMock(mockDriver['token']!);
    final uid = user.uid;
    actualFirstDriverUid ??= uid;

      await userService.createInitialProfile(PendingUserModel(
        uid: uid,
        username: username,
        displayName: displayName,
      ));
    await driverService.createDriverAccount(DriverModel(
      uid: uid,
      assignedStudents: const [],
      refreshTime: '19:00',
      timeZoneName: 'Asia/Karachi',
    ));

    // Seed mock trips for the driver
    final tripsRef = _db.collection('drivers').doc(uid).collection('trips');
    
    final trips = [
      TripModel(
        id: 'trip_morning',
        name: 'Morning Ride',
        sequence: 1,
        disabled: false,
        pickup: const DriverTripLeg(checkpointSetId: 'morning_pickups'),
        dropoff: const FixedTripLeg(destination: LocationPoint(name: 'School', lat: 31.0, lng: 74.0)),
        participants: [],
      ),
      TripModel(
        id: 'trip_noon',
        name: 'Noon Ride',
        sequence: 2,
        disabled: false,
        pickup: const FixedTripLeg(destination: LocationPoint(name: 'School', lat: 31.0, lng: 74.0)),
        dropoff: const DriverTripLeg(checkpointSetId: 'noon_dropoffs'),
        participants: [],
      ),
      TripModel(
        id: 'trip_evening',
        name: 'Evening Ride',
        sequence: 3,
        disabled: false,
        pickup: const FixedTripLeg(destination: LocationPoint(name: 'School', lat: 31.0, lng: 74.0)),
        dropoff: const DriverTripLeg(checkpointSetId: 'evening_dropoffs'),
        participants: [],
      ),
    ];

    for (var trip in trips) {
      await tripsRef.doc(trip.id).set(trip.toMap());
    }
  }

  // 3. Seed Students and Relationships
  if (actualFirstDriverUid != null) {
    final driverId = actualFirstDriverUid;
    final todayStr = formatDate(DateTime.now());

    for (final mockStudent in mockStudentTokens) {
      final tokenData = jsonDecode(mockStudent['token']!);
      final email = tokenData['email'] as String;
      final username = email.split('@').first;
      final displayName = mockStudent['label']!;

      final user = await authService.signInWithMock(mockStudent['token']!);
      final studentId = user.uid;

      await userService.createInitialProfile(PendingUserModel(
        uid: studentId,
        username: username,
        displayName: displayName,
      ));
      
      await studentService.createStudentAccount(UnassignedStudentProfile(
        uid: studentId,
      ));

      await studentService.assignDriverToStudent(
        studentUid: studentId,
        driverId: driverId,
        displayName: displayName,
      );

      // Simulate the backend adding the student to all active trips
      final tripsRef = _db.collection('drivers').doc(driverId).collection('trips');
      final tripsSnap = await tripsRef.get();
      
      for (var tripDoc in tripsSnap.docs) {
        final tripId = tripDoc.id;
        final tripMap = tripDoc.data();
        final trip = TripModel.fromMap(tripMap, tripId);
        
        // Add student to participants array
        await tripsRef.doc(tripId).update({
          'participants': FieldValue.arrayUnion([studentId])
        });

        // Add config for pickup
        final pickupCoreData = _createDefaultCoreData(trip.pickup.legType);
        await tripsRef.doc(tripId).collection('config').doc('pickup_defaults').set({
          'legType': trip.pickup.legType.name,
          'leg': 'pickup',
          'configType': 'defaults',
          'students': {
            studentId: {
              'active': pickupCoreData.toMap(),
              'pending': {
                ...pickupCoreData.toMap(),
                'effectiveFrom': todayStr,
              }
            }
          }
        }, SetOptions(merge: true));

        // Add config for dropoff
        final dropoffCoreData = _createDefaultCoreData(trip.dropoff.legType);
        await tripsRef.doc(tripId).collection('config').doc('dropoff_defaults').set({
          'legType': trip.dropoff.legType.name,
          'leg': 'dropoff',
          'configType': 'defaults',
          'students': {
            studentId: {
              'active': dropoffCoreData.toMap(),
              'pending': {
                ...dropoffCoreData.toMap(),
                'effectiveFrom': todayStr,
              }
            }
          }
        }, SetOptions(merge: true));
      }
    }
  }

  await authService.signOut();
}

CoreStudentLegData _createDefaultCoreData(LegType legType) {
  switch (legType) {
    case LegType.fixed:
    case LegType.student:
      return const SimpleStudentLegData(vote: true);
    case LegType.driver:
      return const DriverStudentLegData(vote: true, checkpoint: 'default_checkpoint');
  }
}
