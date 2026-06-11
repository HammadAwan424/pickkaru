# Polls

Polls are split into **Parent Configuration** (defining the route), **Private Overrides** (future planning), and a **Shared Daily Board** (today's live status).

## Constraints

- **The Day 0 Rule:** The Shared Daily Board is the **sole** source of truth for "Today". Private overrides are **only** used for Days 1-6 in the future.
- **Privacy:** Students can see other students' status only for "Today". Future intentions are private.
- **Defaults:** If no override exists for a future date, the app falls back to the `rosters/{driverId}` document.
- **Checkpoints:** Evening polls pull their master checkpoint list from the parent configuration document.

## Data

```javascript
// 1. Parent Config (defines the route)
polls/{pollId}
  driverId: string,
  period: "morning" | "evening", 
  status: "uninitiated" | "active" | "completed",
  checkpoints: <string>[] | null

// 2. Shared Daily Board (Today's live status - Day 0)
polls/{pollId}/responses/{yyyy-mm-dd}
  approachingStudentIds: <string>[],
  responses: 
    {studentId}: 
      answer: boolean, // Fully resolved (Override OR Default)
      checkpoint: string | null,
      boarded: boolean, 
      updatedAt: timestamp 

// 3. Private Overrides (Future intentions - Days 1-6)
students/{userId}/overrides/{yyyy-mm-dd}
  morning: { answer: boolean },
  evening: { answer: boolean, checkpoint: string | null }
```

## Flow

### User Interface & Interaction Flow

- **Unified Poll Screen:** Both the morning and evening polls are presented on a single screen and can be navigated by swiping horizontally. 
- **Active Ride Map:** When a parent poll document's `status` transitions to `"active"`:
  - **For Students:** A "Track Ride" button appears, allowing them to view the driver's location on a map.
  - **For Drivers:** A "Navigation" button appears, providing them with route guidance and map viewing.
- **Driver Controls:** Only the driver has the authority to tap the "Start Ride" button, which sets the parent poll's `status` to `"active"`.
- **Future Override Screen (7-Day View):** The student views an upcoming 7-day schedule. Each day is represented as a row containing a dropdown with three options: `Yes`, `No`, and `Default`. 
  - Selecting `Default` deletes any existing override for that day (or makes no write if one doesn't exist), reverting to the public roster settings.
  - Selecting `Yes` or `No` writes an explicit boolean override to the `students/{userId}/overrides/{date}` document.

### 1. Student Future Planning (Days 1-6)
When a student views their upcoming schedule:
1. For each future date, check `students/{userId}/overrides/{date}`.
2. If override exists, show it.
3. If no override exists, fall back to `rosters/{driverId}.students.{userId}` default values.
4. **Writes:** Any change to a future day is written strictly to the student's private `overrides/{date}` document.

### 2. Daily Initialization (The Merge)
At the start of a ride (or via Cloud Function), the Shared Daily Board for "Today" is created.
1. The system reads `rosters/{driverId}` for all student defaults.
2. The system reads `students/{studentId}/overrides/{today}` for all students.
3. **Merging:** For each student, if an override for today exists, use it. Otherwise, use their roster default.
4. **Write:** Create `polls/{pollId}/responses/{today}` with these fully resolved values.

### 3. Live Ride Updates ("Today")
Once the Shared Daily Board exists for the current day:
1. **Reads:** All users (Driver & Students) stream `polls/{pollId}/responses/{today}`.
2. **Writes (Student):** If a student changes their mind "today", they write directly to the `responses.{studentId}` map in the Shared Daily Board.
3. **Writes (Driver):** Driver updates `status` on the parent poll, and `boarded` / `approachingStudentIds` on the Shared Daily Board.

---

## Tasks

#### `lib/models/poll.dart`
Define `PollConfig` (parent), `PollInstance` (daily board), and `PollOverride` (private future).
Handle nullable vs non-nullable answers based on document type.

#### `lib/services/poll_service.dart`
- `initializeDailyPoll`: Logic to merge roster defaults and private overrides into the shared board.
- `streamDailyPoll`: Streams today's resolved responses.
- `updateFutureOverride`: Writes to private subcollection.
- `updateTodayResponse`: Writes to shared subcollection.

#### UI Logic
Implement the split-source strategy in the 7-day schedule view: Day 0 uses the shared board, Days 1-6 use private overrides + roster fallback.