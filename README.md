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

- **Firebase Auth strategy:** username+password requires a synthetic email convention
  (`username@pickkaru.internal`) or a Custom Auth token via Cloud Function. Decision
  affects signup complexity and password reset flow.

- **Poll refresh boundary condition:** at exactly 19:00, a student mid-answer loses
  their draft. Is that acceptable or does the refresh wait for an active session to end?

- **Driver reassignment:** the current design allows a student to assign a driver once.
  Re-assignment is explicitly out of scope but needs a decision before Firestore rules
  are finalized, since rules will need to either block or allow overwrites on
  `assignedDriverId`.

- **iOS geofence fallback:** Android geofencing is the primary trigger. iOS has stricter
  background location limits. The fallback (server-side polling) is mentioned but not
  designed. Needs resolution before notifications work cross-platform.