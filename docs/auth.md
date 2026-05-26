# Authentication & Routing

Users sign up with a username and secret code or "sign in with google" option, select a role (driver or student), and
land on a central routing gate `authenticated_homepage` that dispatches them based on role and setup state.

## Constraints

- We wanted to only work with usernames. Mock email is generated based on username+@gmail.com. Username + secret code only to avoid Edge Case 1. 
- Role is set once at signup. There is no role-change flow.
- `assignedDriverId` starts as `null` for all students and is only written during
  the driver assignment step, never during signup.

## Data

```
users/{userId}
  role:             "driver" | "student"
  displayName:      string
  username:         string

students/{userId}
  assignedDriverId: string | null
```

Only these fields are relevant to auth and routing. Other fields on `students/{userId}`
are written later (location, geofence, FCM tokens) and are not read here.

## Flow

### Signup

1. User enters `displayName`, `username`, `secretCode`, selects role.
2. Existing username is handled by `createUserWithEmailAndPassword`
3. Call `FirebaseAuth.createUserWithEmailAndPassword` (or custom token — see constraints).
4. On auth success, write `users/{userId}` with `role`, `displayName`, `username`.
5. If role is `student`, also write `students/{userId}` with `assignedDriverId: null`.
6. Redirect to `authenticated_homepage` regardless of role.

### Login

1. User enters `username` + `secretCode`.
2. Resolve username to Firebase Auth credential and sign in.
3. Redirect to `authenticated_homepage`.


### Google Signup/Login

1. This handles both on a single button click.
2. Since its a single function for both singup and signin,
we therefore check if either the student or user doc already exists before `setting`. 

---

## Edge Cases

### Signup with different addresses but same username
Suppose a@gmail.com does continue with google. His identification is
"a" because we wanted to keep friction little. Now, username=="a" perform regular signup, we use `signUpWithEmailAndPassword` behind the scenes with a@mock_domain. 
The mock_domain must match with gmail.com to prevent this registration
so that we don't have multiple users with same identity (usernames).

### Firestore doc missing after signup
Auth can succeed but the Firestore write can fail. If `authenticated_homepage` reads
`users/{userId}` and the doc is absent:
- Show a loading/retry state, attempt one re-fetch after a short delay.
- If still missing after retry, sign the user out and surface a recoverable error
  ("Setup incomplete, please sign in again"). Do not silently redirect to login —
  that would look like a session expiry to the user.

### Driver ID not found during assignment
Show an inline field error. Do not disable the submit button preemptively — validate
on submit only (avoids a Firestore read on every keystroke).

### Batch write fails halfway during assignment
`arrayUnion` on the driver doc is safe to retry — it is idempotent. Re-submitting the
form will overwrite `assignedDriverId` with the same value and call `arrayUnion` again,
which is a no-op if the student ID is already present. Surface a retry prompt, not a
hard error.

---

## Tasks

#### `authenticated_homepage`

Routing gate. No UI of its own — renders a loading indicator while resolving, then
navigates. Never renders content directly.

```
authenticated_homepage
  │
  ├─ No active Firebase Auth session
  │     → /login
  │
  ├─ role == "driver"
  │     → /driver/home
  │
  └─ role == "student"
        │
        ├─ assignedDriverId != null  →  render poll_widget
        └─ assignedDriverId == null  →  /student_driver_assignment
```

Reads on load:
- `users/{userId}` for `role`
- `students/{userId}` for `assignedDriverId` (only if role is student)

Both reads should be cached in a provider after first resolution. Do not re-fetch on
every navigation — `authenticated_homepage` may be hit on hot restart, tab switches,
and deep links.

#### `student_driver_assignment`

One-time setup. Student enters a driver ID to link themselves.

1. Student enters driver ID.
2. Validate `drivers/{driverId}` exists — show inline error and stop if not found.
3. Batched write:
   - `students/{studentId}` → set `assignedDriverId: driverId`
   - `drivers/{driverId}` → `arrayUnion(studentId)` on `assignedStudentIds`
4. On success, `authenticated_homepage` re-evaluates and routes to `poll_widget`.
