# Pickkaru — Firestore Schema Documentation

This document defines the complete Cloud Firestore database schema for the application, specified using concise, standardized field types.

---

## 1. User & Auth Feature (`user_auth`)

### Collection: `users/{userId}`
Stores user identity metadata and system role assignment.

- **Document ID**: `userId` (Firebase Authentication UID)
- **Security Rules**: Auth required. Read/write accessible by self.

```json
{
  "displayName": "string",
  "username": "string",
  "role": "string (enum: 'student' | 'driver')"
}
```

---

### Collection: `usernames/{usernameId}`
Global lookup collection for enforcing unique handles across all users.

- **Document ID**: `usernameId` (Unique username string)

```json
{
  "uid": "string"
}
```

---

## 2. Driver Core Feature (`driver_core`)

### Collection: `drivers/{driverId}`
Stores driver profile settings.

- **Document ID**: `driverId` (Driver's Firebase Auth UID)

```json
{
  "assignedStudents": ["array<string>"],
  "timeZoneName": "string"
}
```

---

## 3. Student Core Feature (`student_core`)

### Collection: `students/{studentId}`
Stores student profile assignment status.

- **Document ID**: `studentId` (Student's Firebase Auth UID)

```json
{
  "initType": "string (enum: 'unassigned' | 'assigned')",
  "assignedDriverId": "string | null"
}
```

---

## 5. Trip & Route Management Feature (`trip_management`)

### Subcollection: `drivers/{driverId}/trips/{tripId}`
Defines routes and schedules managed by a driver. Each trip has two legs (`pickup` and `dropoff`).

- Every trip has two legs, each leg will be one of the:
`["driver", "student", "fixed"]`
The structure for each leg can be read from examples.

#### Leg types (`VALID_LEG_OBJECT`)

##### 1. Fixed Leg Type (`"fixed"`)
```json
{
  "legType": "fixed",
  "destination": {
    "name": "string",
    "lat": "number",
    "lng": "number"
  }
}
```

##### 2. Driver Leg Type (`"driver"`)
```json
{
  "legType": "driver",
  "ordering": "string (enum: 'forward' | 'reverse')",
  "checkpointSetId": "string"
}
```

##### 3. Student Leg Type (`"student"`)
```json
{
  "legType": "student",
  "ordering": "string (enum: 'forward' | 'reverse')",
  "checkpointSetId": "string"
}
```

- **Document ID**: `tripId` (Unique trip identifier)

#### Schema Definition & Disable State Handling
- **Driver Disable Handling**: Setting `disabled: true` disables the trip globally for the driver.
- **Student Disable Handling**: A student enabling or disabling a ride is represented by their UID's existence in the `participants` array (`present` = enabled, `absent` = disabled).

```json
{
  "name": "string",
  "disabled": "boolean",
  "participants": ["array<string>"],
  "pickup": "VALID_LEG_OBJECT",
  "dropoff": "VALID_LEG_OBJECT"
}
```

---

### Collection: `checkpoints/{setId}`
Shared master collection of route stop checkpoints. Intentionally root-level to support future multi-driver sharing.

- **Document ID**: `setId` (Checkpoint set identifier)

```json
{
  "legType": "string (enum: 'driver' | 'student')",
  "checkpoints": {
    "{checkpointOrStudentId}": {
      "name": "string",
      "lat": "number",
      "lng": "number"
    }
  },
  "order": ["array<string>"]
}
```

---

### Subcollection: `checkpoints/{setId}/editors/{userId}`
Permissions subcollection defining user access rights to a checkpoint set via foreign relation on `checkpointSetId`.

- **Document ID**: `userId` (Firebase Auth UID)

```json
{
  "read": "boolean",
  "write": "boolean"
}
```

---

## 6. Trip Configuration & Defaults Feature (`trip_config`)

### Subcollection: `drivers/{driverId}/trips/{tripId}/config/defaults`
Stores default student configuration preferences for both legs in a single document.

- **Document ID**: `defaults`
- Config entries persist when a student leaves `participants` (re-enabling preserves previous defaults).

#### Default Leg Entry Types (`VALID_DEFAULT_ENTRY`)

##### 1. Fixed Default Leg Entry (`"fixed"`)
```json
{
  "legType": "fixed",
  "students": {
    "{studentId}": {}
  }
}
```

##### 2. Driver Default Leg Entry (`"driver"`)
```json
{
  "legType": "driver",
  "students": {
    "{studentId}": {
      "active": {
        "checkpoint": "string"
      },
      "pending": {
        "checkpoint": "string",
        "effectiveFrom": "string (YYYY-MM-DD)"
      }
    }
  }
}
```

##### 3. Student Default Leg Entry (`"student"`)
```json
{
  "legType": "student",
  "students": {
    "{studentId}": {
      "active": {
        "locationPoint": {
          "name": "string",
          "lat": "number",
          "lng": "number"
        }
      },
      "pending": {
        "locationPoint": {
          "name": "string",
          "lat": "number",
          "lng": "number"
        },
        "effectiveFrom": "string (YYYY-MM-DD)"
      }
    }
  }
}
```

#### Schema Definition
> [!IMPORTANT]
> **Allowed Default Status Values**:
> For the default status map (`active` and `pending`), the `status` field strictly accepts **ONLY** `'waiting'` (default attending) or `'skipping'` (default opting out). Runtime execution states (`approaching`, `picked_up`, `dropped_off`, `never_respond`, etc.) are **NOT** permitted in defaults config.

```json
{
  "configType": "string",
  "status": {
    "{studentId}": {
      "active": "string (enum: 'waiting' | 'skipping')",
      "pending": {
        "status": "string (enum: 'waiting' | 'skipping')",
        "effectiveFrom": "string (YYYY-MM-DD)"
      }
    }
  },
  "pickup": "VALID_DEFAULT_ENTRY",
  "dropoff": "VALID_DEFAULT_ENTRY"
}
```

- `active`: Represents the currently effective default baseline for today.
- `pending`: Holds upcoming preference changes taking effect on `effectiveFrom` (starting tomorrow).
- The resolved default `status` (`pending.status` if `date >= effectiveFrom`, else `active`) seeds the initial student state when creating daily responses on-demand.


---

## 7. Trip Responses & Execution Feature (`trip_execution`)

### Subcollection: `drivers/{driverId}/trips/{tripId}/responses/{dateString}`
Single document per trip per date storing the full student ride lifecycle. Created on-demand when the first student or driver writes. Students without a response entry fall back to their config defaults.

- **Document ID**: `dateString` (Format: `YYYY-MM-DD`)

#### Student Ride Lifecycle State Machine
- `waiting` — Initial state (voted yes)
- `skipping` — Initial / transit state (voted no, or changed mind)
- `approaching` — Driver approaching stop
- `picked_up` — Student picked up
- `dropoff_target` — Approaching dropoff destination
- `dropped_off` — Student dropped off (Terminal)
- `skipped` — Student opted out (Terminal)
- `never_respond` — Driver skipped / no response (Terminal)

#### Response Leg Entry Types (`VALID_RESPONSE_ENTRY`)

##### 1. Fixed Response Leg Entry (`"fixed"`)
```json
{
  "legType": "fixed",
  "students": {
    "{studentId}": {}
  }
}
```

##### 2. Driver Response Leg Entry (`"driver"`)
```json
{
  "legType": "driver",
  "students": {
    "{studentId}": {
      "checkpoint": "string"
    }
  }
}
```

##### 3. Student Response Leg Entry (`"student"`)
```json
{
  "legType": "student",
  "students": {
    "{studentId}": {
      "locationPoint": {
        "name": "string",
        "lat": "number",
        "lng": "number"
      }
    }
  }
}
```

#### Schema Definition
```json
{
  "status": {
    "{studentId}": "string (enum: 'waiting' | 'skipping' | 'approaching' | 'picked_up' | 'dropoff_target' | 'dropped_off' | 'skipped' | 'never_respond')"
  },
  "pickup": "VALID_RESPONSE_ENTRY",
  "dropoff": "VALID_RESPONSE_ENTRY"
}
```


- `legType` is duplicated from the trip doc intentionally to preserve historical context if leg types change in the future.


---

### Subcollection: `drivers/{driverId}/tripRuns/{dateString}`
Stores execution lifecycle timestamps for trips on a specific calendar day.

- **Document ID**: `dateString` (Format: `YYYY-MM-DD`)
- **Trip State** is derived from this doc: no entry = `Available`, `startedAt` exists + `completedAt` null = `Active`, `completedAt` exists = `Completed`. The `Disabled` state lives on the trip doc's `disabled` field.

```json
{
  "trips": {
    "{tripId}": {
      "startedAt": "string (ISO 8601)",
      "completedAt": "string (ISO 8601) | null",
      "startedBy": "string"
    }
  }
}
```