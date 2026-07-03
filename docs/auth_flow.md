# Pickkaru Authentication & Onboarding Flow

This document summarizes the authentication architecture, how Riverpod providers dictate routing, and the exact step-by-step journey a new user takes during onboarding.

---

## 1. The Core Architecture & Routing Gate

The application's navigation doesn't rely on imperative pushes (e.g., `Navigator.push`). Instead, it is driven reactively by a central "Routing Gate" (`AuthenticatedHomePage`) which listens to a chain of Riverpod providers:

1. **`authStateProvider`**: Listens to Firebase Auth (`FirebaseAuth.instance.authStateChanges()`). It returns a Firebase UID if the user is signed into Google.
2. **`currentUserProvider`**: Combines the Firebase UID with the user's Firestore document at `/users/{uid}`.
3. **`studentProvider` / `driverProvider`**: Domain-specific providers that watch `/students/{uid}` or `/drivers/{uid}`.

### The Invisible Orchestrator: `AuthenticatedHomePage`
Whenever the data in the providers changes, `AuthenticatedHomePage` instantly evaluates the state and returns the correct screen:
*   If Firestore `user == null` ➔ Shows **`UsernameSelectionPage`**
*   If `user.role == null` ➔ Shows **`RoleSelectionPage`**
*   If `user.role == driver` ➔ Shows **`DriverShell`**
*   If `user.role == student` and `student.assignedDriverId == null` ➔ Shows **`StudentDriverAssignmentPage`**
*   If `user.role == student` and has driver ➔ Shows **`StudentShell`**

---

## 2. The Step-by-Step User Journey

When a new user opens the app, they progress through the following linear flow:

### Step 1: Google Sign-In (`HomePage`)
*   **User Action**: Taps "Continue with Google".
*   **Backend**: `AuthService().signInWithGoogle()` authenticates the user with Firebase. **No Firestore documents are created yet.**
*   **Transition**: `authStateProvider` updates. `AuthenticatedHomePage` sees the Google session but no Firestore profile, so it routes to Step 2.

### Step 2: Username Selection (`UsernameSelectionPage`)
*   **User Action**: Enters a custom username and display name, then taps "Continue".
*   **Backend**: `UserService().createInitialProfile()` runs an atomic batch to securely claim the username in `/usernames/` and creates the base `/users/{uid}` document **with a null role**.
*   **Transition**: `currentUserProvider` updates. `AuthenticatedHomePage` sees the profile but notices the missing role, routing to Step 3.

### Step 3: Role Selection (`RoleSelectionPage`)
*   **User Action**: Selects "Student" or "Driver" and taps "Complete Setup".
*   **Backend**: Calls either `StudentService().createStudentAccount(uid)` or `DriverService().createDriverAccount(uid)`. This updates the `/users/{uid}` document to set `role: 'student'` (or `'driver'`) and creates all domain-specific documents (e.g., `/students/` or `/drivers/`, `/polls/`, `/rosters/`) in a single atomic batch.
*   **Transition**: `currentUserProvider` detects the updated role. Drivers are immediately routed to the `DriverShell`. Students are routed to Step 4.

### Step 4: Driver Assignment (Students Only)
*   **User Action**: Student lands on `StudentDriverAssignmentPage`, enters their driver's ID, and submits.
*   **Backend**: `StudentService().assignDriverToStudent()` updates the `/students/{uid}` document and adds the student to the driver's `/rosters/` document.
*   **Transition**: The `studentProvider` updates. `AuthenticatedHomePage` sees the student now has an assigned driver and routes them to the `StudentShell`.

---

## 3. How to Use Providers in Screens

*   **To get the currently logged-in user's basic info** (UID, username, display name):
    ```dart
    final user = ref.watch(currentUserProvider).valueOrNull;
    ```
*   **To get domain-specific data** (e.g., inside the Student domain):
    ```dart
    final user = ref.watch(currentUserProvider).valueOrNull;
    final student = ref.watch(studentProvider(user!.uid)).valueOrNull;
    ```
*   **To log out**:
    ```dart
    ref.read(authServiceProvider).signOut();
    ```
    *(The `authStateProvider` will emit null, tearing down the session and automatically throwing the user back to the `HomePage`.)*
