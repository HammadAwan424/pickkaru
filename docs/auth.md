# Authentication & Routing

Users sign in with Google, select a role (driver or student), and land on a central routing gate `authenticated_homepage` that dispatches them based on role and setup state.

## Constraints

- Role is set once at signup. There is no role-change flow.
- `assignedDriverId` under `students/{userId}` starts as `null` and is only written during the driver assignment step.
- **Privacy:** Student personal data (like home coordinates) is kept private. Shared information (like ride defaults) is stored in the `rosters` collection.

## Data

```javascript
users/{userId}
  role: "driver" | "student"
  displayName: string, 
  username: string

drivers/{userId}
  assignedStudents: <string>[], 
  refreshTime: string, // "HH:mm"
  timeZoneName: string // e.g. "Asia/Karachi"

rosters/{driverId}
  students: {
    {studentUid}: {
      displayName: string,
      defaultMorning: boolean,
      defaultEvening: boolean,
      defaultCheckpoint: string | null
    }
  }

students/{userId}
  assignedDriverId: string | null,
  location: { lat: number, lng: number } // Private home location
```

## Flow

### User Interface & Interaction Flow

1. **Sign In / Sign Up:** A single Google Sign-In flow. The first time a user signs in, they select their role (`driver` or `student`). On subsequent visits, Google Sign-In skips the role selection and routes directly based on their existing role.
2. **Deferred Profile Setup:** For students, the initial signup only links their `assignedDriverId`. Setting up their private home `location` and their `defaultMorning`/`defaultEvening`/`defaultCheckpoint` preferences is deferred and handled later through a dedicated settings/profile page.

### Student Driver Assignment

One-time setup. Student enters a driver ID to link themselves.

1. Student enters driver ID.
2. Validate `drivers/{userId}` exists.
3. If valid -> Batched write:
```javascript
students/{userId}
  assignedDriverId: driverId

drivers/{driverId}
  arrayUnion(studentId) on assignedStudents

rosters/{driverId}
  // Add to shared roster with initial defaults
  students.{studentId}: {
    displayName: "Student Name",
    defaultMorning: true,
    defaultEvening: true,
    defaultCheckpoint: null
  }
```

## Tasks

#### `authenticated_homepage`
Routing gate. Resolves `users/{userId}` role and redirects:
- Driver -> `driver_shell`
- Student (with `assignedDriverId`) -> `student_shell`
- Student (no `assignedDriverId`) -> `student_driver_assignment`

#### `student_driver_assignment`
Handles the linking of student to driver and initializes the roster entry.
