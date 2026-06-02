# Pickkaru Commute App

A two-role Flutter app for drivers and students. Drivers manage daily ride polls and
trigger proximity notifications. Students set their pickup location, answer polls, and
receive arrival alerts.

**Stack:** Flutter · Firebase Auth · Firestore · Mapbox · FCM · Android Geofencing

---

## Reading Guide

Each feature lives in its own file. This README is the map — read it to orient yourself,
then open the relevant file when working on a feature.

This file -> Feature list, one-line purpose, relationships 
`docs/*.md` -> Constraints, Data, Flow, Edge Cases, Tasks - Identified by H2

## Features

### Authentication & Routing
Users sign up with a username and secret code, pick a role, and land on a routing
gate that dispatches them based on role and assignment state.
→ [docs/auth.md](./docs/auth.md)

### Polls
Two polls per day (morning / evening). Drivers create and view them. Students answer
and update their pickup location per-poll.
→ [docs/polls.md](./docs/polls.md)

### Location & Mapbox
Students set a pickup location via GPS or address search. Drivers see assigned student
locations on a map.
→ [docs/location.md](./docs/location.md)

### Geofence & Notifications
Driver device registers OS-level geofences for each assigned student. On entry, an
arrival event is written to Firestore and a Cloud Function delivers an FCM notification
to the student.
→ [docs/notifications.md](./docs/notifications.md)

---

## Open Questions

These are unresolved decisions that affect multiple features. Resolve before implementing
the relevant feature.

- **Driver reassignment:** the current design allows a student to assign a driver once.
  Re-assignment is explicitly out of scope but needs a decision before Firestore rules
  are finalized, since rules will need to either block or allow overwrites on
  `assignedDriverId`.

- **iOS geofence fallback:** Android geofencing is the primary trigger. iOS has stricter
  background location limits. Needs resolution before notifications work cross-platform.

## Firestore Schema
```
[auth.md]
users/{userId}
  role: "driver" | "student"
  displayName: string, 
  username: string,

drivers/{userId}
  assignedStudents: <string>[], [auth.md]
  refreshTime: string [auth.md] [TODO: update through profile]

students/{userId}
  assignedDriverId: string [auth.md]
  defaultMorning: boolean, [polls.md]
  defaultEvening: boolean, [polls.md]
  defaultCheckpoint: string, [polls.md]
  "location": [polls.md]
    "lat": number,
    "lng": number
  "displayAddress": "string", [polls.md]

[polls.md]
drivers/{driverId}/polls/morning
  period: "morning", 
  checkpoints: null, 
  responses: 
    {studentId}: 
      answer: boolean, 
      boarded: false, 
      updatedAt: timestamp 

[polls.md]
drivers/{driverId}/polls/evening 
  period: "evening", 
  checkpoints: <string>[], 
  responses:
    {studentId}:
      answer: boolean, 
      checkpoint: string, 
      boarded: false, 
      updatedAt: timestamp 
```