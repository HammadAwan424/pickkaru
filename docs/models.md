# Pickkaru — Dart Models Documentation

This document defines the complete Dart data model declarations across the application architecture, categorized under its corresponding **Feature** heading, matching [docs/firestore_schema.md](file:///home/hammad/code/flutter/pickkaru/docs/firestore_schema.md) feature-by-feature.

---

## 1. User & Auth Feature (`user_auth`)

### `roles` (Enum)
Represents the system roles for authenticated users.

```dart
enum roles {
  student,
  driver,
}
```

### `BaseUserModel` (Sealed Base Class)
Abstract polymorphic base class representing a user's core identity profile during authentication and handle registration.

```dart
sealed class BaseUserModel {
  final String uid;
  final String displayName;
  final String username;

  const BaseUserModel({
    required this.uid,
    required this.displayName,
    required this.username,
  });
}
```

### `PendingUserModel`
Subclass of `BaseUserModel` representing a user who has registered their handle but has not yet chosen a role.

```dart
class PendingUserModel extends BaseUserModel {
  const PendingUserModel({
    required super.uid,
    required super.displayName,
    required super.username,
  });
}
```

### `UserModel`
Subclass of `BaseUserModel` representing an onboarded user with an assigned system role.

```dart
class UserModel extends BaseUserModel {
  final roles role;

  const UserModel({
    required super.uid,
    required this.role,
    required super.displayName,
    required super.username,
  });
}

### `UserNotFoundException`
Thrown by `watchLocalUser` when a Firebase Auth user signs in successfully but their Firestore `users/{userId}` document does not exist.

```dart
class UserNotFoundException implements Exception {
  final String uid;
  final String code; // 'user-not-found'
  final String message;

  const UserNotFoundException(
    this.uid, {
    this.code = 'user-not-found',
    this.message = 'User document does not exist in Firestore.',
  });
}
```

### `UsernameTakenException`
Thrown by `createInitialProfile` when attempting to register a handle that is already claimed in the `usernames/{usernameId}` collection.

```dart
class UsernameTakenException implements Exception {
  final String username;
  final String code; // 'username-taken'
  final String message;

  const UsernameTakenException(
    this.username, {
    this.code = 'username-taken',
    this.message = 'The username is already taken.',
  });
}
```


```

---

## 2. Driver & Student Domain Profile Hierarchy (`driver_core` & `student_core`)

### `ProfileModel` (Sealed Base Class)
Root abstract class for domain-specific user profile models.

```dart
sealed class ProfileModel {
  final String uid; // Populated from Firestore Document ID

  const ProfileModel({required this.uid});
}
```

*Note: `uid` is supplied from the Firestore Document ID upon deserialization (`drivers/{driverId}` or `students/{studentId}`). It is excluded from `toMap()` document payloads to avoid redundant data.*

### `DriverModel`
Subclass of `ProfileModel` representing a driver's profile settings and assigned student UIDs.

```dart
class DriverModel extends ProfileModel {
  final List<String> assignedStudents;
  final String timeZoneName;

  const DriverModel({
    required super.uid,
    required this.assignedStudents,
    required this.timeZoneName,
  });
}
```

### `StudentModel` (Sealed Subclass Hierarchy)
Sealed hierarchy representing a student's driver-assignment state.

```dart
sealed class StudentModel extends ProfileModel {
  const StudentModel({required super.uid});
}

class UnassignedStudentModel extends StudentModel {
  const UnassignedStudentModel({required super.uid});
}

class AssignedStudentModel extends StudentModel {
  final String assignedDriverId; // Non-null by construction

  const AssignedStudentModel({
    required super.uid,
    required this.assignedDriverId,
  });
}
```


---

## 5. Trip & Route Management Feature (`trip_management`)

### `LegType` & `TripLegDirection` (Enums)
```dart
enum LegType { student, driver, fixed }
enum TripLegDirection { pickup, dropoff }
```

### `LocationPoint`
Represents a geographic location destination point.

```dart
class LocationPoint {
  final String name;
  final double lat;
  final double lng;

  const LocationPoint({
    required this.name,
    required this.lat,
    required this.lng,
  });
}
```

### `TripLeg` (Sealed Base Class) & Subclasses
Polymorphic representation of a leg strategy within a trip.

```dart
sealed class TripLeg {
  final LegType legType;
  const TripLeg({required this.legType});
}

class FixedTripLeg extends TripLeg {
  final LocationPoint destination;
  const FixedTripLeg({required this.destination}) : super(legType: LegType.fixed);
}

class DriverTripLeg extends TripLeg {
  final String checkpointSetId;
  final String ordering; // Required ordering ('forward' | 'reverse')

  const DriverTripLeg({
    required this.checkpointSetId,
    required this.ordering,
  }) : super(legType: LegType.driver);
}

class StudentTripLeg extends TripLeg {
  final String checkpointSetId;
  final String ordering; // Required ordering ('forward' | 'reverse')

  const StudentTripLeg({
    required this.checkpointSetId,
    required this.ordering,
  }) : super(legType: LegType.student);
}
```

### `TripModel`
Represents a scheduled route / trip definition managed by a driver.

```dart
class TripModel {
  final String id;
  final String name;
  final bool disabled; // Driver disable state (true = disabled globally)
  final TripLeg pickup;
  final TripLeg dropoff;
  final List<String> participants; // Enrolled Student UIDs (presence = enabled)

  const TripModel({
    required this.id,
    required this.name,
    required this.disabled,
    required this.pickup,
    required this.dropoff,
    required this.participants,
  });
}
```

### `Checkpoint` & `CheckpointSet`
Represents a stop along a route and a named master collection of stops stored in the root `checkpoints/{setId}` collection.

```dart
class Checkpoint {
  final String name;
  final double lat;
  final double lng;

  const Checkpoint({
    required this.name,
    required this.lat,
    required this.lng,
  });
}

class CheckpointSet {
  final String id;
  final LegType legType;
  final Map<String, Checkpoint> checkpoints;
  final List<String> order;

  const CheckpointSet({
    required this.id,
    required this.legType,
    required this.checkpoints,
    required this.order,
  });
}
```

### `CheckpointEditorPermission`
Represents access permissions for a user on a checkpoint set stored at `checkpoints/{setId}/editors/{userId}`.

```dart
class CheckpointEditorPermission {
  final String userId;
  final bool read;
  final bool write;

  const CheckpointEditorPermission({
    required this.userId,
    required this.read,
    required this.write,
  });
}
```

---

## 6. Trip Configuration & Defaults Feature (`trip_config`)

> [!IMPORTANT]
> **Default Status Constraints**:
> The top-level default `status` map (`active` and `pending`) uses `StudentRideStatus` strictly restricted to `StudentRideStatus.waiting` (attending by default) or `StudentRideStatus.skipping` (opted out by default).

### `DefaultStatusEntry`
Represents a student's active baseline default status and pending future status change.

```dart
class DefaultStatusEntry {
  final StudentRideStatus active; // Strictly waiting or skipping
  final ({StudentRideStatus status, String effectiveFrom})? pending;

  const DefaultStatusEntry({
    required this.active,
    this.pending,
  });
}
```

### `DefaultEntryData` (Sealed Base Class) & Subclasses
Polymorphic representation of a student's default leg configuration choices based on `legType`.

```dart
sealed class DefaultEntryData {
  const DefaultEntryData();
}

class FixedDefaultEntryData extends DefaultEntryData {
  const FixedDefaultEntryData();
}

class DriverDefaultEntryData extends DefaultEntryData {
  final String checkpoint;

  const DriverDefaultEntryData({required this.checkpoint});
}

class StudentDefaultEntryData extends DefaultEntryData {
  final LocationPoint locationPoint;

  const StudentDefaultEntryData({required this.locationPoint});
}
```

### `PendingData` (Record Type)
Represents upcoming default configuration choices taking effect on a specific future date.

```dart
typedef PendingData = ({DefaultEntryData coreData, String effectiveFrom});
```

### `ConfigStudentEntry`
Represents a student's active baseline default leg choices and pending future changes.

```dart
class ConfigStudentEntry {
  final DefaultEntryData active;
  final PendingData? pending;

  const ConfigStudentEntry({
    required this.active,
    this.pending,
  });
}
```

### `TripLegConfigData`
Represents default configurations for a single leg (`pickup` or `dropoff`).

```dart
class TripLegConfigData {
  final LegType legType;
  final Map<String, ConfigStudentEntry> students;

  const TripLegConfigData({
    required this.legType,
    required this.students,
  });
}
```

### `TripDefaultsConfigModel`
Main merged config document stored at `drivers/{driverId}/trips/{tripId}/config/defaults` (Doc ID: `defaults`).

```dart
class TripDefaultsConfigModel {
  final String configType;
  final Map<String, DefaultStatusEntry> status; // Top-level status map
  final TripLegConfigData pickup;
  final TripLegConfigData dropoff;

  const TripDefaultsConfigModel({
    required this.configType,
    required this.status,
    required this.pickup,
    required this.dropoff,
  });
}
```

*Note: Contains top-level `status` map (strictly `waiting` or `skipping`) alongside leg-specific `pickup` and `dropoff` default data. Config entries persist when a student leaves `participants` so re-enables preserve student defaults.*

---

## 7. Trip Responses & Execution Feature (`trip_execution`)

### `StudentRideStatus` (Enum)
Defines the state machine status transitions for a student's ride during trip execution.

```dart
enum StudentRideStatus {
  waiting,        // Initial state (voted yes)
  skipping,       // Initial / transit state (voted no or opted out)
  approaching,    // Driver approaching stop
  picked_up,      // Student picked up
  dropoff_target, // Approaching dropoff destination
  dropped_off,    // Student dropped off (Terminal)
  skipped,        // Student opted out (Terminal)
  never_respond,  // Driver skipped / no response (Terminal)
}
```

### `ResponseEntryData` (Type Aliases)
Aliased from `DefaultEntryData` since live leg response entries share the exact same polymorphic structure as default leg entries:

```dart
typedef ResponseEntryData = DefaultEntryData;
typedef FixedResponseEntryData = FixedDefaultEntryData;
typedef DriverResponseEntryData = DriverDefaultEntryData;
typedef StudentResponseEntryData = StudentDefaultEntryData;
```

### `ResponseLegData`
Represents live leg metadata and student checkpoint/location choices.

```dart
class ResponseLegData {
  final LegType legType;
  final Map<String, ResponseEntryData> students;

  const ResponseLegData({
    required this.legType,
    required this.students,
  });
}
```

### `TripDailyResponseModel`
Single merged daily response document stored at `drivers/{driverId}/trips/{tripId}/responses/{dateString}` (Doc ID: `YYYY-MM-DD`).

```dart
class TripDailyResponseModel {
  final Map<String, StudentRideStatus> status;
  final ResponseLegData pickup;
  final ResponseLegData dropoff;

  const TripDailyResponseModel({
    required this.status,
    required this.pickup,
    required this.dropoff,
  });
}
```

### `TripExecutionState` & `TripRunDay`
Stores execution lifecycle timestamps for trips on a specific calendar day.

```dart
class TripExecutionState {
  final DateTime startedAt;
  final DateTime? completedAt;
  final String startedBy;

  const TripExecutionState({
    required this.startedAt,
    this.completedAt,
    required this.startedBy,
  });
}

class TripRunDay {
  final String dateString;
  final Map<String, TripExecutionState> trips;

  const TripRunDay({
    required this.dateString,
    required this.trips,
  });
}
```
