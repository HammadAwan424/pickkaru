# Pickkaru — Dart Models Refactoring Plan & Implementation Guide

This document outlines all implementation details, factory parsing logic, JSON serialization (`fromMap` / `toMap`), and step-by-step refactoring tasks required to update the codebase in `lib/` to match the target specifications defined in [docs/models.md](file:///home/hammad/code/flutter/pickkaru/docs/models.md) and [docs/firestore_schema.md](file:///home/hammad/code/flutter/pickkaru/docs/firestore_schema.md).

---

## 📋 Architectural Refactoring Matrix

| Feature | Current Implementation in `lib/` | Target Model in `docs/models.md` | Refactoring & Migration Tasks |
| :--- | :--- | :--- | :--- |
| **1. User & Auth** | `UserProfile`, `PendingUserProfile`, `UserModel` in `lib/core/user/user.dart` | `BaseUserModel`, `PendingUserModel`, `UserModel` | Rename base class `UserProfile` to `BaseUserModel`. Update `fromMap` factory and constructors across onboarding/login flows. |
| **2. Driver & Student Core** | Independent `DriverModel` and `StudentProfile` classes | Sealed `ProfileModel` root hierarchy (`DriverModel`, `StudentModel`, `AssignedStudentModel`, `UnassignedStudentModel`) | Create top-level `sealed class ProfileModel { final String uid; }`. Refactor `DriverModel` and `StudentModel` to extend `ProfileModel`. Ensure `AssignedStudentModel.assignedDriverId` is non-null. |
| **3. Trip Management** | `TripModel` with leg objects | `TripModel` with non-optional `ordering` on leg subclasses | Ensure `ordering: String` (`'forward'` \| `'reverse'`) is non-nullable required on `DriverTripLeg` and `StudentTripLeg`. Add `disabled: bool` on `TripModel` for driver global disable. Verify `participants: List<String>` presence/absence logic for student ride toggle. |
| **4. Trip Config** | `TripLegConfig` (`pickup_defaults`, `dropoff_defaults`) | `TripDefaultsConfigModel` (`config/defaults`) with `DefaultEntryData` | Merge per-leg config docs into single `drivers/{driverId}/trips/{tripId}/config/defaults` doc containing `pickup` & `dropoff` maps. Introduce `DefaultEntryData` sealed hierarchy (`FixedDefaultEntryData`, `DriverDefaultEntryData`, `StudentDefaultEntryData`). Move default `status` map to top level of document (`waiting` \| `skipping`). Preserve `active` and `pending` (`effectiveFrom`) date technique. |
| **5. Trip Responses & Execution** | `TripLegResponse` (`pickup_date`, `dropoff_date` with `boarded`/`droppedOff`) | `TripDailyResponseModel` at `responses/{dateString}` | Merge per-leg response docs into single `drivers/{driverId}/trips/{tripId}/responses/{dateString}` doc containing `status: Map<String, StudentRideStatus>` state machine (`waiting` $\rightarrow$ `dropped_off`/`skipped`/`never_respond`). Alias `ResponseEntryData` to `DefaultEntryData`. |
| **6. Checkpoints** | `CheckpointSet` | `CheckpointSet` & `CheckpointEditorPermission` | Verify root `checkpoints/{setId}` collection access and document `CheckpointEditorPermission` for `checkpoints/{setId}/editors/{userId}` permissions subcollection. |

---

## 🛠️ Implementation & Parsing Details

### 1. Auth Model Deserialization (`lib/core/user/user.dart`)

```dart
factory BaseUserModel.fromMap(String uid, Map<String, dynamic> map, {String? claimRole}) {
  // Role is retrieved primarily from Firebase Auth custom token claims (IdTokenResult.claims['role'])
  final roleStr = claimRole ?? map['role'] as String?;
  if (roleStr != null && roleStr.isNotEmpty) {
    return UserModel(
      uid: uid,
      role: roles.values.byName(roleStr),
      displayName: map['displayName'] as String,
      username: map['username'] as String,
    );
  }
  return PendingUserModel(
    uid: uid,
    displayName: map['displayName'] as String,
    username: map['username'] as String,
  );
}
```
*Note: `role` is read from Firebase Auth token claims during authentication. It remains stored in Firestore under `users/{userId}` using the key `'role'`.*



### 2. Domain Profile Serialization (Omit `uid` from document body)

```dart
// DriverModel.toMap()
@override
Map<String, dynamic> toMap() => {
  'assignedStudents': assignedStudents,
  'timeZoneName': timeZoneName,
};

// UnassignedStudentModel.toMap()
@override
Map<String, dynamic> toMap() => {
  'initType': StudentInitType.unassigned.name,
  'assignedDriverId': null,
};

// AssignedStudentModel.toMap()
@override
Map<String, dynamic> toMap() => {
  'initType': StudentInitType.assigned.name,
  'assignedDriverId': assignedDriverId,
};
```


### 2. Default Config & Polymorphic Parsing Helpers (`lib/shared/trip/models/trip_leg_config.dart`)

```dart
DefaultEntryData parseDefaultEntryData(Map<String, dynamic> raw) => switch (raw['legType']) {
  'fixed'   => const FixedDefaultEntryData(),
  'driver'  => DriverDefaultEntryData(
                 checkpoint: raw['checkpoint'] as String,
               ),
  'student' => StudentDefaultEntryData(
                 locationPoint: LocationPoint.fromMap(raw['locationPoint'] as Map<String, dynamic>),
               ),
  _ => throw ArgumentError('Unknown legType: ${raw['legType']}'),
};

PendingData? parsePending(Map<String, dynamic>? raw) => raw == null
    ? null
    : (
        coreData: parseDefaultEntryData(raw),
        effectiveFrom: raw['effectiveFrom'] as String,
      );
```

### 3. Response Model Type Aliases (`lib/shared/trip/models/trip_leg_response.dart`)

```dart
typedef ResponseEntryData = DefaultEntryData;
typedef FixedResponseEntryData = FixedDefaultEntryData;
typedef DriverResponseEntryData = DriverDefaultEntryData;
typedef StudentResponseEntryData = StudentDefaultEntryData;
```

---

## 🚀 Step-by-Step Refactoring Instructions

### Step 1: User & Auth Models (`lib/core/user/user.dart`)
1. Rename `UserProfile` to `BaseUserModel` (`sealed class BaseUserModel`).
2. Rename `PendingUserProfile` to `PendingUserModel`.
3. Update `UserModel` to extend `BaseUserModel`.
4. Update all references in auth services (`auth_service.dart`, `user_provider.dart`) and UI screens (`username_selection.dart`, `role_selection.dart`).

### Step 2: Domain Profiles (`lib/driver/driver_core/` & `lib/student/student_core/`)
1. Create `sealed class ProfileModel { final String uid; }`.
2. Update `DriverModel` to extend `ProfileModel`.
3. Create `sealed class StudentModel extends ProfileModel`.
4. Refactor `UnassignedStudentModel` and `AssignedStudentModel` to extend `StudentModel`, ensuring `assignedDriverId` is non-null by construction on `AssignedStudentModel`.

### Step 3: Trip Strategy Legs (`lib/shared/trip/models/trip_leg.dart`)
1. Make `ordering: String` required (non-nullable) on `DriverTripLeg` and `StudentTripLeg`.

### Step 4: Trip Configuration (`lib/shared/trip/models/trip_leg_config.dart`)
1. Create `sealed class DefaultEntryData` with `FixedDefaultEntryData`, `DriverDefaultEntryData(checkpoint)`, and `StudentDefaultEntryData(locationPoint)`.
2. Create `DefaultStatusEntry` to hold active and pending default status (`waiting` | `skipping`).
3. Implement `parseDefaultEntryData(Map<String, dynamic> raw)` and `parsePending(Map<String, dynamic>? raw)` helpers.
4. Create `TripDefaultsConfigModel` representing the single merged document at `config/defaults` with top-level `status` map.

### Step 5: Live Trip Responses (`lib/shared/trip/models/trip_leg_response.dart`)
1. Define `StudentRideStatus` enum with all 8 state machine transitions (`waiting`, `skipping`, `approaching`, `picked_up`, `dropoff_target`, `dropped_off`, `skipped`, `never_respond`).
2. Create `ResponseEntryData` typedef aliases mapping directly to `DefaultEntryData` subclasses (`FixedResponseEntryData`, `DriverResponseEntryData`, `StudentResponseEntryData`).
3. Create `TripDailyResponseModel` representing the single merged document at `responses/{dateString}` with top-level `status`, `pickup`, and `dropoff` maps.
