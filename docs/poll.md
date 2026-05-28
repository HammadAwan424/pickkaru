# Polls

Two fixed Firestore documents per driver, reused daily. One poll covers the morning
ride (home → university), one covers the evening ride (university → home). Students
answer yes/no and optionally select a stop. The driver uses responses to know who is
riding and where to pick them up or stop.

## Constraints

- Exactly two poll documents per driver: `drivers/{driverId}/polls/morning` and
  `drivers/{driverId}/polls/evening`. Fixed IDs, never recreated — same docs reused daily.
- Poll times (morning / evening) are semantic labels for ride direction. They do not
  enforce any time-based access rules on the client.
- Both polls are always visible via horizontal swipe (PageView). The client never
  hides a poll based on current time.
- The only condition that locks a student's response is `boarded: true`. No other
  lock conditions exist currently. When boarded, the yes/no button and checkpoint
  selector are hidden.
- `refreshTime` lives on `drivers/{driverId}`, not on the poll docs. It is a driver-level
  config that applies to both polls. See Data section.
- The scheduler owns poll lifecycle. It is the only writer of `responses` defaults
  and the only thing that resets `boarded`.

## Data

```
drivers/{driverId}
  refreshTime: string                      // "HH:mm" format, default "19:00"

drivers/{driverId}/polls/morning
  period:      "morning"
  checkpoints: null
  responses:
    {studentId}:
      answer:    boolean
      boarded:   boolean
      updatedAt: timestamp

drivers/{driverId}/polls/evening
  period:        "evening"
  checkpoints:   string[]                  // driver-owned, preserved across resets
  responses:
    {studentId}:
      answer:     boolean
      checkpoint: string
      boarded:    boolean
      updatedAt:  timestamp

students/{studentId}
  defaultMorning:    boolean               // seeded into morning answer at reset
  defaultEvening:    boolean               // seeded into evening answer at reset
  defaultCheckpoint: string                // seeded into evening checkpoint at reset
```

**On the union type:** morning and evening responses are structurally different.
In Dart, model this as a sealed class or union:

```dart
sealed class PollResponse {
  final bool answer;
  final bool boarded;
  final Timestamp updatedAt;
}

class MorningResponse extends PollResponse { }

class EveningResponse extends PollResponse {
  final String checkpoint;
}
```

**Checkpoint validity:** if a student has `defaultCheckpoint` set to a stop the driver
later removes from `checkpoints`, the stale value is preserved in the response and
displayed as-is. No validation is enforced. The driver is expected to communicate
changes to affected students directly.

## Flow

### Daily Reset (scheduler)

Runs when server time crosses `drivers/{driverId}.refreshTime`.

1. Read all student IDs from `drivers/{driverId}.assignedStudentIds`.
2. For each student, read `defaultMorning`, `defaultEvening`, `defaultCheckpoint`
   from `students/{studentId}`.
3. Batched write to both poll docs:
   - Morning responses: `{ answer: defaultMorning, boarded: false, updatedAt: now }`
   - Evening responses: `{ answer: defaultEvening, checkpoint: defaultCheckpoint, boarded: false, updatedAt: now }`
   - `checkpoints` array on evening poll is **not touched** — preserved as-is.
4. Write `refreshTime` forward to the next boundary (same `HH:mm`, next calendar day).

### New Student Added Mid-Cycle

Triggered when `students/{studentId}.assignedDriverId` is written.

1. Read student's `defaultMorning`, `defaultEvening`, `defaultCheckpoint`.
2. Write response entry into both poll docs immediately:
   - Morning: `{ answer: defaultMorning, boarded: false, updatedAt: now }`
   - Evening: `{ answer: defaultEvening, checkpoint: defaultCheckpoint, boarded: false, updatedAt: now }`
3. Does not affect other students' responses or the `checkpoints` array.

### Student Updates Response

Student can change `answer` or `checkpoint` at any time unless `boarded: true`.

1. Client checks `boarded` on load — hides yes/no button and checkpoint selector if true.
2. On change, student writes only their own response entry:
   - `responses/{studentId}.answer` and/or `responses/{studentId}.checkpoint`
   - `responses/{studentId}.updatedAt: now`
3. `boarded` is never written by the student during a normal response update.

### Student Marks Boarded

1. Student taps "Mark as boarded."
2. Client writes `responses/{studentId}.boarded: true` and `updatedAt: now`.
3. Client hides the yes/no button and checkpoint selector immediately.
4. This write is not reversible by the student. It resets to `false` only at the
   next scheduler run.

### Driver Views Poll

1. Driver opens poll screen — reads both poll docs via a Firestore stream.
2. Morning poll: shows each student's `answer` and their saved pickup location
   (read from `students/{studentId}.location`, not from the poll response).
3. Evening poll: shows each student's `answer`, selected `checkpoint`, and `boarded`
   status. Driver can see per-stop boarding counts to decide when to move.

---

## Edge Cases

### `refreshTime` crosses while the ride is in progress
The scheduler fires at `refreshTime` regardless of ride state. Rides are expected to
end before 19:00 so this should not occur in practice. No special handling is
implemented for a late-running ride. If this becomes a problem, a `rideActive` flag
on the driver doc could gate the scheduler — out of scope for now.

### Driver removes a checkpoint that a student has selected
Stale `checkpoint` value is preserved in the response and shown as-is on both driver
and student screens. No error is shown. Driver handles this out-of-band.

### Driver adds a new checkpoint after students have already responded
Existing responses are not affected. New checkpoint appears in the evening poll's
selector for students who haven't boarded yet. Students who have already responded
can still change their checkpoint selection as long as they haven't boarded.

### Batch write fails during reset
The scheduler should retry. All response writes within a reset are idempotent —
writing the same defaults twice produces the same state. The `checkpoints` array is
not touched, so a partial retry cannot corrupt it.

### Student added to a driver with no `defaultCheckpoint` set
`defaultCheckpoint` is typed as `string` — it must be set during student onboarding.
If somehow absent, the evening response entry will have a missing field. The client
must handle this defensively and prompt the student to set a default checkpoint before
the evening poll is usable.

---

## Tasks (Needs optimization esp. *_poll_widget contains both the student and driver side logic)

#### `lib/models/poll.dart`
Define `Poll`, `MorningResponse`, `EveningResponse` as a sealed class hierarchy.
Serialize from Firestore. `Poll` holds `period`, `checkpoints`, and a map of
`responses` keyed by student ID.
**Acceptance:** Round-trips through `fromFirestore` / `toMap` without data loss.
Both response types deserialize correctly from the same `responses` map.

#### `lib/features/polls/poll_screen.dart`
`PageView` with two pages: index 0 = morning, index 1 = evening.
Active-period indicator (not time-based — just visual). Swipe gestures only, no tabs.
**Acceptance:** Both polls render; swiping navigates between them with no time-gating.

#### `lib/features/polls/morning_poll_widget.dart`
Reads `drivers/{driverId}/polls/morning` via stream.
For each student entry: shows `answer`, shows pickup location from
`students/{studentId}.location` (not from response).
Hides yes/no button when `boarded: true`.
**Acceptance:** Boarded students show locked state; location comes from student doc,
not poll response.

#### `lib/features/polls/evening_poll_widget.dart`
Reads `drivers/{driverId}/polls/evening` via stream.
Shows `checkpoints` list for selection, `answer`, `boarded` per student.
Hides yes/no and checkpoint selector when `boarded: true`.
Driver view shows per-stop boarding count.
**Acceptance:** Boarded state hides controls; checkpoint selector only shows current
`checkpoints` array from poll doc; stale checkpoints display as-is without error.

#### `lib/services/poll_service.dart`
Add helpers for:
- Streaming both poll docs for a given driver ID
- Writing a student response entry (answer, checkpoint)
- Writing `boarded: true` for a student
- Writing a new student response entry on assignment
**Acceptance:** All writes are scoped to the calling user's own student ID via
Firestore rules. Boarded write is a targeted field update, not a full response overwrite.

#### `functions/src/scheduler.ts`
Scheduled function. On each driver's `refreshTime`:
- **Clears the poll and applies defaults**
- Reads `assignedStudentIds` and each student's defaults
- Batched write of all responses to both poll docs
- Updated fields inlcude: `boarded` to `false`, `answer` to `default[Morning | Evening]` & `updatedAt` to now.
- Preserves `checkpoints`, `refreshTime` and other non-related fields.
**Acceptance:** Idempotent — running twice produces the same state. `checkpoints`
array is unchanged after reset. New `refreshTime` is always in the future.