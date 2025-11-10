# Event Connect - Database Schema & Relationships

## Entity Relationship Diagram (Text Format)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            ACCOUNTS APP                                     │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────┐
│           USER                   │
│──────────────────────────────────│
│ id (PK)                          │
│ username                         │
│ email                            │
│ password                         │
│ first_name                       │
│ last_name                        │
│ role (student/club_admin/system) │
│ student_id                       │
│ faculty                          │
│ phone                            │
│ avatar (ImageField)              │
│ bio                              │
│ created_at                       │
│ updated_at                       │
└──────────────────────────────────┘
            │
            │ (extends AbstractUser)
            ▼

┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLUBS APP                                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────┐         ┌──────────────────────────────┐
│           CLUB                   │         │      CLUBMEMBERSHIP          │
│──────────────────────────────────│         │──────────────────────────────│
│ id (PK)                          │◄────────┤ id (PK)                      │
│ name                             │         │ user_id (FK → User)          │
│ slug (unique)                    │         │ club_id (FK → Club)          │
│ description                      │         │ role (member/admin/president)│
│ faculty                          │         │ joined_at                    │
│ contact_email                    │         └──────────────────────────────┘
│ contact_phone                    │                      │
│ logo (ImageField)                │                      │
│ status (active/inactive)         │                      │
│ president_id (FK → User)         │                      │
│ created_at                       │                      ▼
│ updated_at                       │         Many-to-Many relationship
└──────────────────────────────────┘         between User and Club
            │
            │
            ▼

┌─────────────────────────────────────────────────────────────────────────────┐
│                        EVENT MANAGEMENT APP                                 │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────┐
│           EVENT                  │
│──────────────────────────────────│
│ id (PK)                          │
│ title                            │
│ slug (unique)                    │
│ description                      │
│ category                         │
│ club_id (FK → Club)              │
│ created_by_id (FK → User)        │
│ location                         │
│ location_detail                  │
│ start_at                         │
│ end_at                           │
│ registration_start               │
│ registration_end                 │
│ capacity                         │
│ registration_count               │
│ poster (ImageField)              │
│ banner (ImageField)              │
│ status (draft/pending/approved..)│
│ is_featured                      │
│ requires_approval                │
│ view_count                       │
│ average_rating                   │
│ rating_count                     │
│ created_at                       │
│ updated_at                       │
│ approved_at                      │
└──────────────────────────────────┘
            │
            ├──────────────────────────────────────────┐
            │                                          │
            ▼                                          ▼

┌──────────────────────────────────┐    ┌──────────────────────────────────┐
│      EVENTREGISTRATION           │    │        EVENTAPPROVAL             │
│──────────────────────────────────│    │──────────────────────────────────│
│ id (PK)                          │    │ id (PK)                          │
│ event_id (FK → Event)            │    │ event_id (OneToOne → Event)      │
│ user_id (FK → User)              │    │ reviewer_id (FK → User)          │
│ status (registered/attended...)  │    │ status (pending/approved...)     │
│ note                             │    │ comment                          │
│ qr_code (unique)                 │    │ submitted_at                     │
│ checked_in                       │    │ reviewed_at                      │
│ checked_in_at                    │    └──────────────────────────────────┘
│ registered_at                    │
│ updated_at                       │
└──────────────────────────────────┘
            │
            │
            ▼

┌──────────────────────────────────┐    ┌──────────────────────────────────┐
│          FEEDBACK                │    │         EVENTIMAGE               │
│──────────────────────────────────│    │──────────────────────────────────│
│ id (PK)                          │    │ id (PK)                          │
│ event_id (FK → Event)            │    │ event_id (FK → Event)            │
│ user_id (FK → User)              │    │ image (ImageField)               │
│ registration_id (OneToOne)       │    │ caption                          │
│ rating (1-5)                     │    │ order                            │
│ comment                          │    │ uploaded_at                      │
│ is_approved                      │    └──────────────────────────────────┘
│ is_anonymous                     │
│ created_at                       │
│ updated_at                       │
└──────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         NOTIFICATIONS APP                                   │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────┐    ┌──────────────────────────────────┐
│        NOTIFICATION              │    │         ACTIVITYLOG              │
│──────────────────────────────────│    │──────────────────────────────────│
│ id (PK)                          │    │ id (PK)                          │
│ user_id (FK → User)              │    │ user_id (FK → User)              │
│ type                             │    │ action                           │
│ title                            │    │ description                      │
│ message                          │    │ metadata (JSONField)             │
│ event_id (FK → Event, nullable)  │    │ ip_address                       │
│ club_id (FK → Club, nullable)    │    │ user_agent                       │
│ is_read                          │    │ created_at                       │
│ read_at                          │    └──────────────────────────────────┘
│ created_at                       │
└──────────────────────────────────┘
```

---

## Relationships Summary

### 1. USER (Central Entity)
**Has Many:**
- Clubs (as president)
- Clubs (as admin) - M2M
- Clubs (as member) - M2M through ClubMembership
- Created Events
- Event Registrations
- Feedbacks
- Reviewed Events (as reviewer)
- Notifications
- Activity Logs

### 2. CLUB
**Belongs To:**
- User (president)

**Has Many:**
- Users (admins) - M2M
- Users (members) - M2M through ClubMembership
- Events
- Notifications

### 3. EVENT
**Belongs To:**
- Club
- User (created_by)

**Has Many:**
- Event Registrations
- Feedbacks
- Event Images
- Notifications

**Has One:**
- Event Approval

### 4. EVENTREGISTRATION
**Belongs To:**
- Event
- User

**Has One:**
- Feedback

### 5. FEEDBACK
**Belongs To:**
- Event
- User
- Event Registration (optional)

### 6. EVENTAPPROVAL
**Belongs To:**
- Event (OneToOne)
- User (reviewer)

### 7. EVENTIMAGE
**Belongs To:**
- Event

### 8. NOTIFICATION
**Belongs To:**
- User
- Event (optional)
- Club (optional)

### 9. ACTIVITYLOG
**Belongs To:**
- User

---

## Database Tables

| App              | Table Name           | Primary Purpose                  |
|------------------|----------------------|----------------------------------|
| accounts         | users                | User authentication & profiles   |
| clubs            | clubs                | Student organizations            |
| clubs            | club_memberships     | User-Club relationships          |
| event_management | events               | Event information                |
| event_management | event_registrations  | Event sign-ups                   |
| event_management | feedbacks            | Event reviews/ratings            |
| event_management | event_approvals      | Event approval workflow          |
| event_management | event_images         | Event gallery                    |
| notifications    | notifications        | User notifications               |
| notifications    | activity_logs        | System activity tracking         |

---

## Indexes

**For Performance Optimization:**

1. `events` table:
   - Index on (status, start_at)
   - Index on (category, status)
   - Index on (is_featured, status)

2. `notifications` table:
   - Index on (user, is_read)

---

## Unique Constraints

1. `users`: username, email, student_id
2. `clubs`: name, slug
3. `events`: slug
4. `club_memberships`: (user, club)
5. `event_registrations`: (event, user), qr_code
6. `feedbacks`: (event, user)
7. `event_approvals`: event (OneToOne)

---

## Key Workflows

### Event Creation Flow
```
1. User (Club Admin) creates Event → status: 'draft'
2. User submits for approval → status: 'pending'
3. EventApproval record created → status: 'pending'
4. System Admin reviews → EventApproval status: 'approved'/'rejected'
5. Event status updated → status: 'approved'/'rejected'
6. Notification sent to creator
```

### Event Registration Flow
```
1. Student views approved Event
2. Checks if registration is open (is_registration_open)
3. Checks if event is full (is_full)
4. Creates EventRegistration → status: 'registered'
5. Event.registration_count incremented
6. QR code generated for check-in
7. Notification sent to student
```

### Check-in Flow
```
1. Scan QR code at event
2. Find EventRegistration by qr_code
3. Update: checked_in = True, checked_in_at = now()
4. Update: status = 'attended'
```

### Feedback Flow
```
1. Event completed (status: 'completed')
2. Registered users can submit Feedback
3. Rating (1-5) and comment submitted
4. Event.average_rating and rating_count updated
5. Optional: moderation (is_approved)
```

---

## Data Flow Example

```
USER (Student)
    ↓ registers for
EVENT (Django Workshop)
    ↓ creates
EVENTREGISTRATION (John → Django Workshop)
    ↓ generates
QR_CODE (abc123xyz)
    ↓ at event
CHECK-IN (scanned)
    ↓ after event
FEEDBACK (Rating: 5, "Great workshop!")
    ↓ updates
EVENT.average_rating (4.8)
    ↓ sends
NOTIFICATION ("Thanks for your feedback!")
```

---

## Storage Estimates (Example)

Assuming 1000 active users, 50 clubs, 200 events/year:

| Table               | Est. Rows | Notes                              |
|---------------------|-----------|-------------------------------------|
| users               | 1,000     | Growing                            |
| clubs               | 50        | Relatively stable                  |
| club_memberships    | 5,000     | Avg 100 members/club               |
| events              | 200/year  | 1,000 over 5 years                 |
| event_registrations | 20,000/yr | Avg 100 registrations/event        |
| feedbacks           | 10,000/yr | ~50% of attendees give feedback    |
| event_approvals     | 200/year  | 1:1 with events needing approval   |
| event_images        | 1,000     | Avg 5 images/event                 |
| notifications       | 50,000/yr | Growing, consider archiving old    |
| activity_logs       | 100,000/yr| Growing, consider archiving old    |

---

Generated: November 10, 2025
