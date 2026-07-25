# Onboarding

### Flow Diagram
```mermaid
flowchart
    Onboarding[Continue with Google] --> Comeback & NewUser & ExistingUser

    NewUser --> Username["UsernameSelection"]
    Username --> Role[Role Selection Page]
    Role --> RoleSelected{"Role Selected??"}
    RoleSelected --> |driver| RideToggle
    RoleSelected --> |student| DriverAssignment
    DriverAssignment --> RideSelection
    RideToggle -->|For each enabled ride|DriverRideSetupCard
    RideSelection -->|For each selected ride among enabled| StudentRideSetupCard

    Comeback -.->|Resume Progress down the chain| Username
```


# Live Trip Screen

### Trip State
```mermaid
stateDiagram-v2
    direction TB
    [*] --> Enabled
    [*] --> Disabled

    state Enabled {
        Available --> Ready
        Ready --> Active
        Active --> Completed
        Completed --> [*]
    }
    Available  --> Disabled
    Disabled --> Available 
```

#### Disabled State
The above diagram applies to both students/drivers.
- Driver -> Unable to disable a trip if already `Active`.
- Student -> If a student disables a trip, they don't recieve further
notifications for

### Participant State
```mermaid
stateDiagram-v2
    direction TB
    [*] --> waiting : INITIAL
    [*] --> skipping : INITIAL

    waiting --> approaching
    waiting --> skipping
    skipping --> waiting

    skipping --> skipped

    state if_state <<choice>>
    approaching --> if_state
    if_state --> picked_up
    if_state --> skipped : student opted out
    if_state --> never_respond : driver skipped

    picked_up --> dropoff_target
    dropoff_target --> dropped_off
    skipped --> [*]
    never_respond --> [*]
    dropped_off --> [*]
```

### View eligibility — StudentTripStatus

| State          | Pickup view shows as  | Dropoff view shows as      |
|----------------|-----------------------|----------------------------|
| waiting        | Waiting               | Preview (renders pickup)   |
| skipping       | Skipping              | Preview (renders pickup)   |
| approaching    | Approaching           | Preview (renders pickup)   |
| picked_up      | Done (terminal)       | Active — picked_up         |
| dropoff_target | Done (terminal)       | Active — dropoff_target    |
| dropped_off    | Done (terminal)       | Active — dropoff_target    |
| skipped        | Skipped (terminal)    | Skipped (terminal)         |
| never_respond  | No response (terminal)| No response (terminal)     |

