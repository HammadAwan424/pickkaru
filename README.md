# Pickkaru Commute App Design

> **TL;DR:** A two-role Flutter app for drivers and students, using Firebase Auth and Firestore for state, Mapbox for location/address handling, Android geofencing on the driver side, and FCM for student alerts.

## Steps

### 1. Define User Onboarding and Authentication

- Use Firebase Authentication with a username + secret code login flow
- On signup, ask for role selection: driver or student
- Ask student for the corresponding driver ID; show drivers the homepage directly
- Create a Firestore user profile with `role`, `displayName`, and `assignedDriverId` for students

### 2. Design Firestore Data Model

All Firestore schema definitions are centralized in the JSON model below:

```json
{
  "users/{userId}": {
    "role": "string",
    "displayName": "string",
    "username": "string",
    "assignedDriverId": "string | null"
  },
  "drivers/{driverId}": {
    "currentLocation": {
      "lat": "number",
      "lng": "number",
      "ts": "timestamp"
    },
    "refreshTime": "timestamp",
    "assignedStudentIds": ["string"]
  },
  "students/{studentId}": {
    "assignedDriverId": "string | null",
    "location": {
      "lat": "number",
      "lng": "number"
    },
    "displayAddress": "string",
    "geofence": {
      "center": {
        "lat": "number",
        "lng": "number"
      },
      "radiusMeters": "number",
      "enabled": "boolean",
      "cooldownSeconds": "number"
    },
    "fcmTokens": ["string"],
    "notifyPreferences": {
      "notifyOnDriverArrival": "boolean"
    },
    "lastArrivalNotifiedAt": "timestamp",
    "defaultMorning": "boolean",
    "defaultEvening": "boolean"
  },
  "drivers/{driverId}/polls/{pollId}": {
    "period": "morning | evening",
    "type": "user-defined | pre-defined",
    "title": "string",
    "startsAt": "timestamp",
    "endsAt": "timestamp",
    "checkpoints": ["string"],
    "refreshTime": "timestamp",
    "responses": {
      "{studentId}": {
        "answer": "boolean",
        "checkpoint": "string | null",
        "updatedAt": "timestamp"
      }
    }
  },
  "events/arrivalEvents/{eventId}": {
    "driverId": "string",
    "studentId": "string",
    "at": "timestamp",
    "location": {
      "lat": "number",
      "lng": "number"
    },
    "source": "driver | server"
  }
}
```

**Notes:**
- `refreshTime` is a general-purpose timestamp replacing `createdAt` and `resetAt`
- For polls, `refreshTime` indicates the next daily refresh boundary
- `drivers/{driverId}/registeredStudentIds` can be added as an optional cache for driver-centric lookups

### 3. Build Poll and Role UX

#### Poll Logic Summary

- **Two polls per day:**
  - Evening poll: 19:00 → 09:00 (overnight)
  - Morning poll: 09:00 → 19:00
- **UI:** Single poll screen with horizontal swipe (PageView) — left/right to show Morning / Evening poll
- **Morning poll:** "user-defined" checkpoints — stores only responses; student location is read from `students/{id}.location`
- **Evening poll:** "pre-defined" checkpoints — stores responses plus a driver/global list of string checkpoints that students can select
- **Refresh:** On each refresh boundary (09:00 and 19:00) a Cloud Function or scheduled job creates the next poll and applies each student's defaults (`defaultMorning` / `defaultEvening`) into the new poll responses

#### Screens

- **Driver screen:** View poll details and manage poll reset schedule
- **Student screen:** View poll and answer yes/no, update location, set proximity area

### 4. Integrate Mapbox and Location

- Student location entry uses Mapbox geocoding and reverse geocoding
- Student can press a button to record current GPS coordinates and optionally resolve a pickup address
- Driver map view can display student pickup points and current route

### 5. Design Notification and Proximity Flow

- Student saves a geofence definition: center and radius
- Student writes the geofence config to Firestore
- Driver app subscribes to assigned students and registers Android geofences for each student's location
- When the driver enters a geofence, a local notification is triggered immediately on the driver device
- Use Android geofencing as the primary trigger and FCM as a fallback for remote delivery

## Design Decisions

- Use local Android geofencing as the main proximity trigger because it is fast, device-local, and fits the use case
- Use Firebase Auth for secure minimum-credential sign-in while keeping UX simple
- Use Firestore as the shared state source, with students feeding geofence data and the driver consuming it
- Schedule poll refresh with a time-based mechanism (7pm daily) rather than requiring manual reset

## Implementation Plan: Subtasks

This section breaks the design into smaller, actionable development tasks. Each task maps to files and a short acceptance criterion.

#### Poll Models
- **File:** `lib/models/poll.dart`
- **Task:** Create `Poll`, `PollResponse`, `PollPeriod`, and `PollType` types
- **Acceptance:** Models serialize/deserialize to Firestore schema

#### PageView UI
- **File:** `lib/features/polls/poll_screen.dart`
- **Task:** Horizontal `PageView` (index 0 = Morning, index 1 = Evening), active-period indicator, and swipe gestures
- **Acceptance:** Swiping shows both polls and highlights active by local time

#### Morning Poll Widget
- **File:** `lib/features/polls/morning_poll_widget.dart`
- **Task:** User-defined checkpoints widget; reads `students/{id}.location` for pickup location
- **Acceptance:** Shows student's current saved location and yes/no control

#### Evening Poll Widget
- **File:** `lib/features/polls/evening_poll_widget.dart`
- **Task:** Pre-defined checkpoints widget; shows `checkpoints` options and records selected checkpoint + yes/no
- **Acceptance:** Selected checkpoint stored in response

#### Firestore Service Updates
- **File:** `lib/services/firestore_service.dart`
- **Task:** Add helpers to read/write poll docs, responses, and student defaults; use batched writes for defaults application
- **Acceptance:** Atomic default-seeding works

#### Scheduler Cloud Function
- **File:** `functions/src/scheduler.ts`
- **Task:** Scheduled at 09:00 and 19:00 UTC (or configured timezone); creates new poll docs, applies `defaultMorning/defaultEvening` into `responses`, populates `checkpoints` for evening polls
- **Acceptance:** Idempotent runs that create polls and seed responses

#### Arrival Notification Function
- **File:** `functions/src/sendNotification.ts`
- **Task:** Triggered by arrival events; validates origin, enforces cooldown, sends FCM to `students/{id}.fcmTokens`
- **Acceptance:** Valid events send to target tokens and update `lastArrivalNotifiedAt`

#### Firestore Security Rules
- **Task:** Restrict writes so students can only update their response and own student doc; drivers only manage polls for their driverId
- **Acceptance:** Rules pass basic linter and protect fields

#### Tests and Verification
- **Task:** Unit tests for Cloud Functions logic, integration test for poll creation and default seeding, manual device tests for swipe UI and geofence notifications
- **Acceptance:** Test run passes locally or in CI


## Notification Design: Driver → Student Proximity

> **TL;DR:** Driver devices detect entering a student's proximity (student-defined radius) using on-device geofence detection or periodic location checks, then trigger a trusted server-side action to deliver an FCM notification to the student's device. Primary flow is driver-side geofence detection; server-side proximity detection is a fallback.

### 1. Firestore Schema Additions

- All Firestore schema definitions are centralized in the data model JSON above
- `drivers/{driverId}/registeredStudentIds` is optional and should only be used as a cache for driver-centric lookups

### 2. Primary Flow

#### Setup
- Student sets `geofence` and allows notifications; student app stores its Firebase Cloud Messaging (FCM) token under `students/{id}.fcmTokens`
- Driver is assigned students; driver app pulls assigned students' geofence config
- Driver app registers an OS geofence per student location (or uses a drift-check if too many geofences). Note Android limit ≈100 geofences per app

#### Detection
- On geofence `ENTER` (driver device), the driver app performs a quick local validation (timestamp, distance) and writes a minimal arrival event to Firestore (e.g. `events/arrivalEvents/{id}`) or calls an authenticated Cloud Function `sendArrivalNotification(driverId, studentId, location)`

#### Delivery
- A Cloud Function authenticates and validates the event, checks `lastArrivalNotifiedAt` cooldown, updates `lastArrivalNotifiedAt`, and sends an FCM data/notification message to all tokens in `students/{id}.fcmTokens`
- Student devices receive FCM even when the app is backgrounded or terminated, and can show an in-app UI when foreground

### 3. Security & Validation

- **Firestore rules:** Drivers can read only geofence configs for assigned students; students can write only their own `fcmTokens` and `geofence`
- **Cloud Function validation:** HTTP calls require Firebase Auth driver tokens; Firestore triggers should enforce trusted payloads or signed device writes
- **Rate limiting:** Enforce per-student cooldown (`cooldownSeconds`) and global rate limits to avoid spam

### 4. Edge Cases & UX

- **App background/termination:** On Android, use geofence APIs plus a foreground service if continuous location is required; on iOS, prefer server fallback
- **Battery:** Prefer geofence APIs over continuous GPS polling

### 5. Message Payload & Notification Handling

**FCM data message example:**
- `title`: "Driver arriving"
- `body`: "Your driver is within 120m — be ready"
- `data`: `{ driverId, driverName, lat, lng, ts }`

**Student devices:** Notification taps should open the app and show driver ETA/map

### 6. Testing & Verification

- **Unit tests:** Cloud Function validation logic and cooldown handling
- **Integration tests:** Simulate driver geofence enter → Firestore write → Cloud Function → FCM to emulator tokens
- **Manual tests:** Assign students to a test driver, verify geofence notification and cooldown behavior

### 7. Alternative Approaches

- **Peer-to-peer push:** Not feasible without server auth; avoid
- **Topic-based notifications:** Can work for shared vans, but per-student geofence control is lost