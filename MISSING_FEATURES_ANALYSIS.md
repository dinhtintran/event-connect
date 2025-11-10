# Missing Features Analysis - Event Management System

## 📊 Current Implementation Status

### ✅ **Đã Hoàn Thành (Implemented)**

#### 1. Authentication
- ✅ Login/Logout
- ✅ User profile với roles (student, club_admin, system_admin)
- ✅ JWT token management
- ✅ Role-based navigation

#### 2. Event Listing & Discovery
- ✅ **ExploreScreen** - Browse all events
- ✅ **MyEventsScreen** - View registered events
- ✅ **EventDetailScreen** - View event details (READ-ONLY)
- ✅ Search functionality
- ✅ Category filtering
- ✅ Featured events

#### 3. Club Admin Features
- ✅ **ClubHomePage** - Dashboard with stats
- ✅ **ClubEventsPage** - List club events with filters
- ✅ **CreateEventScreen** - Create new event (FULL FORM)
- ✅ API Integration:
  - `getClubEvents()` ✅
  - `createEvent()` ✅
  - `getClubInfo()` ✅
  - `getNotifications()` ✅

#### 4. System Admin Features
- ✅ **AdminDashboard** - System stats
- ✅ **ApprovalScreen** - View pending events
- ✅ API Integration:
  - `getStats()` ✅
  - `getPendingApprovals()` ✅

---

## ❌ **Chưa Hoàn Thành (Missing Features)**

### 1. Event Management - Student Features

#### A. Event Registration
**Status:** ❌ Not Implemented  
**Priority:** 🔴 HIGH  
**Files:** None created yet

**Missing:**
- Register for event button/action
- Registration confirmation dialog
- View registration status
- Cancel registration

**APIs Available (need UI):**
```dart
// EventApi.dart
POST /api/events/{id}/register/         ✅ Backend ready
DELETE /api/events/{id}/cancel/         ✅ Backend ready
GET /api/registrations/my-events/       ✅ Backend ready
```

**TODO:**
1. Add "Đăng ký" button in EventDetailScreen
2. Check if user already registered
3. Handle registration success/failure
4. Refresh event status after registration

---

#### B. Event Check-in
**Status:** 🟡 Partial (Button exists, no logic)  
**Priority:** 🟠 MEDIUM  
**Files:** 
- `event_detail_screen.dart` - Has "Check-in" button (line 383) but no logic

**Missing:**
- QR code scanning
- Manual check-in
- Check-in confirmation
- View check-in status

**APIs Available:**
```dart
POST /api/events/{id}/checkin/          ✅ Backend ready
```

**TODO:**
1. Implement QR scanner or manual check-in
2. Validate check-in eligibility
3. Show success feedback
4. Update UI after check-in

---

#### C. Event Feedback
**Status:** ❌ Not Implemented  
**Priority:** 🟢 LOW  
**Files:** None

**Missing:**
- Submit feedback form
- View submitted feedback
- Rating system
- Feedback list

**APIs Available:**
```dart
POST /api/events/{id}/feedback/         ✅ Backend ready
GET /api/events/{id}/feedbacks/         ✅ Backend ready
```

**TODO:**
1. Create FeedbackScreen
2. Rating widget (1-5 stars)
3. Comment text field
4. Submit logic

---

### 2. Event Management - Club Admin Features

#### A. Edit Event
**Status:** ❌ Not Implemented  
**Priority:** 🔴 HIGH  
**Files:** None

**Missing:**
- Edit event screen/form
- Pre-populate form with existing data
- Update event API call
- Handle approval status changes

**APIs Available:**
```dart
PUT /api/events/{id}/                   ✅ Backend ready
```

**TODO:**
1. Create EditEventScreen (reuse CreateEventScreen logic)
2. Load existing event data
3. Update API call in ClubAdminRepository
4. Navigation from ClubEventsPage (Edit button)

---

#### B. Delete Event
**Status:** ❌ Not Implemented  
**Priority:** 🟠 MEDIUM  
**Files:** None

**Missing:**
- Delete confirmation dialog
- API call to delete event
- Refresh list after deletion

**APIs Available:**
```dart
DELETE /api/events/{id}/                ✅ Backend ready
```

**TODO:**
1. Add delete button in ClubEventsPage
2. Confirmation dialog
3. API call in ClubAdminRepository
4. Handle errors (e.g., can't delete approved events)

---

#### C. View Event Participants
**Status:** 🟡 Partial (API ready, no UI)  
**Priority:** 🟠 MEDIUM  
**Files:** 
- `club_admin_repository.dart` - Has `getEventParticipants()` method

**Missing:**
- Participants list screen
- Filter by status (registered, checked_in, cancelled)
- Export participants list
- Send notifications to participants

**APIs Available:**
```dart
GET /api/events/{id}/participants/      ✅ Backend ready
```

**TODO:**
1. Create EventParticipantsScreen
2. List view with filters
3. Participant details
4. Action buttons (approve, reject for approval-required events)

---

#### D. Update Event Status
**Status:** ❌ Not Implemented  
**Priority:** 🟡 MEDIUM  
**Files:** None

**Missing:**
- Change status button (draft → pending, approved → ongoing, ongoing → completed)
- Status change confirmation
- API call

**APIs Available:**
```dart
PATCH /api/events/{id}/status/          ✅ Backend ready (needs verification)
```

**TODO:**
1. Add status dropdown/buttons in ClubEventsPage
2. Validate status transitions
3. Confirmation dialog
4. Update event in list

---

### 3. Event Management - System Admin Features

#### A. Approve/Reject Events
**Status:** 🟡 Partial (Screen exists, limited logic)  
**Priority:** 🔴 HIGH  
**Files:**
- `approval_screen.dart` - Has UI but basic logic

**Missing:**
- Detailed event review
- Rejection reason input
- Bulk approve/reject
- Approval history

**APIs Available:**
```dart
POST /api/approvals/{event_id}/approve/ ✅ Backend ready
POST /api/approvals/{event_id}/reject/  ✅ Backend ready
GET /api/approvals/pending/             ✅ Backend ready
```

**TODO:**
1. Enhance ApprovalScreen with event details
2. Add rejection reason field
3. Implement approve/reject logic
4. Refresh list after action

---

#### B. View All Events (Admin)
**Status:** ❌ Not Implemented  
**Priority:** 🟠 MEDIUM  
**Files:** None

**Missing:**
- Admin event management screen
- View all events across all clubs
- Advanced filters
- Bulk actions

**APIs Available:**
```dart
GET /api/events/                        ✅ Backend ready
```

**TODO:**
1. Create AdminEventManagementScreen
2. Advanced filters (club, status, date range)
3. Pagination
4. Quick actions (approve, view, edit)

---

#### C. Manage Clubs
**Status:** ❌ Not Implemented  
**Priority:** 🟢 LOW  
**Files:** None

**Missing:**
- Club list screen
- Create/edit/delete clubs
- Assign club admins
- Club approval workflow

**APIs Available:**
```dart
GET /api/clubs/                         ✅ Backend ready
POST /api/clubs/                        ✅ Backend ready
PUT /api/clubs/{id}/                    ✅ Backend ready
DELETE /api/clubs/{id}/                 ✅ Backend ready
```

**TODO:**
1. Create ClubManagementScreen
2. CRUD operations
3. Club admin assignment
4. Club status management

---

#### D. User Management
**Status:** ❌ Not Implemented  
**Priority:** 🟢 LOW  
**Files:** None

**Missing:**
- User list screen
- View user details
- Change user roles
- Ban/unban users

**APIs Available:**
```dart
GET /api/admin/users/                   ❓ Need to check backend
PUT /api/admin/users/{id}/role/         ❓ Need to check backend
```

**TODO:**
1. Verify backend APIs
2. Create UserManagementScreen
3. Role management UI
4. User actions

---

### 4. Enhanced Event Detail Screen

#### Current State: READ-ONLY Mock UI
**Status:** 🟡 Partial  
**Priority:** 🔴 HIGH  
**File:** `event_detail_screen.dart`

**Missing Actions:**
- ❌ Register button (for students)
- ❌ Cancel registration (for students)
- ❌ Edit button (for club admin)
- ❌ Delete button (for club admin)
- ❌ Approve/Reject buttons (for system admin)
- ❌ View participants (for club admin)
- ❌ Check-in logic (for students)
- ❌ Share event
- ❌ Add to calendar
- ❌ View location on map

**TODO:**
1. Add role-based action buttons
2. Implement register/cancel logic
3. Integrate with EventApi
4. Add loading states
5. Error handling

---

### 5. Notifications

**Status:** 🟡 Partial (API ready, basic UI)  
**Priority:** 🟠 MEDIUM  
**Files:**
- `notification_api.dart` ✅
- UI screens ❌

**Missing:**
- Notification center screen
- Mark as read/unread
- Delete notifications
- Push notifications (Firebase)
- In-app notification badges

**APIs Available:**
```dart
GET /api/notifications/                 ✅ Backend ready
POST /api/notifications/{id}/read/      ✅ Backend ready
GET /api/notifications/unread-count/    ✅ Backend ready
```

**TODO:**
1. Create NotificationCenterScreen
2. Notification list with filters
3. Mark read/unread logic
4. Setup Firebase Cloud Messaging

---

## 🎯 Recommended Implementation Order

### Phase 1: Core Event Management (Week 1)
**Priority: 🔴 HIGH**

1. **Edit Event** (Club Admin)
   - Reuse CreateEventScreen
   - Add EditEventScreen wrapper
   - Update API integration
   - Testing: 1 day

2. **Event Registration** (Student)
   - Add register button to EventDetailScreen
   - Registration confirmation dialog
   - API integration
   - Testing: 1 day

3. **Approve/Reject Events** (System Admin)
   - Enhance ApprovalScreen
   - Add rejection reason
   - Implement approve/reject logic
   - Testing: 1 day

**Total: 3 days**

---

### Phase 2: Event Interactions (Week 2)
**Priority: 🟠 MEDIUM**

4. **View Participants** (Club Admin)
   - Create EventParticipantsScreen
   - List with filters
   - Export functionality
   - Testing: 1 day

5. **Delete Event** (Club Admin)
   - Confirmation dialog
   - API integration
   - Error handling
   - Testing: 0.5 day

6. **Cancel Registration** (Student)
   - Add cancel button
   - Confirmation dialog
   - Refresh event detail
   - Testing: 0.5 day

7. **Check-in System** (Student)
   - QR code scanner
   - Manual check-in
   - Success feedback
   - Testing: 1 day

**Total: 3 days**

---

### Phase 3: Admin Features (Week 3)
**Priority: 🟢 LOW-MEDIUM**

8. **Admin Event Management**
   - Create AdminEventManagementScreen
   - Advanced filters
   - Bulk actions
   - Testing: 2 days

9. **Notification Center**
   - Create NotificationCenterScreen
   - Mark read/unread
   - Delete notifications
   - Testing: 1 day

10. **Club Management** (Optional)
    - Create ClubManagementScreen
    - CRUD operations
    - Testing: 2 days

**Total: 3-5 days**

---

### Phase 4: Polish & Enhancements (Week 4)
**Priority: 🟢 LOW**

11. **Event Feedback System**
    - Create FeedbackScreen
    - Rating widget
    - Submit logic
    - Testing: 1 day

12. **Enhanced Event Detail**
    - Share event
    - Add to calendar
    - Map integration
    - Testing: 1 day

13. **User Management** (Optional)
    - UserManagementScreen
    - Role management
    - Testing: 1 day

**Total: 2-3 days**

---

## 📝 Implementation Notes

### Code Reusability
- **CreateEventScreen** → Reuse for **EditEventScreen**
- **ClubEventsPage** filters → Reuse for **AdminEventManagementScreen**
- **Event cards** → Reuse across all event lists

### State Management
- Consider adding Provider for:
  - EventService (for student actions)
  - ClubAdminService (for club admin actions)
  - AdminService (for system admin actions)

### Error Handling
- All API calls need try-catch
- User-friendly error messages
- Retry logic for failed requests

### Testing Checklist
For each feature:
- ✅ Happy path
- ✅ Error handling
- ✅ Edge cases (empty lists, network errors)
- ✅ Role-based access control
- ✅ UI responsiveness

---

## 🚀 Quick Start - Implement First Feature

**Start with: Event Registration (Student)**

Why?
- Most used feature
- Simple UI
- Clear user value
- Tests full flow (UI → API → Backend)

**Files to create/modify:**
1. `event_detail_screen.dart` - Add register button
2. `event_service.dart` - Add registerForEvent() method
3. `event_repository.dart` - Add registration logic

**Time estimate:** 4-6 hours

---

## 📊 Summary

| Category | Total Features | Completed | Pending | Priority |
|----------|----------------|-----------|---------|----------|
| Student Features | 4 | 1 (25%) | 3 | 🔴 HIGH |
| Club Admin | 5 | 2 (40%) | 3 | 🔴 HIGH |
| System Admin | 4 | 1 (25%) | 3 | 🟠 MEDIUM |
| Enhancements | 3 | 0 (0%) | 3 | 🟢 LOW |
| **TOTAL** | **16** | **4 (25%)** | **12** | - |

**Overall Progress: 25% Complete** 🎯

**Estimated Time to Complete All:** 11-14 days (with testing)

---

## 🎓 Next Steps

1. **Review this document** with team/stakeholders
2. **Prioritize features** based on business needs
3. **Create tickets** for each feature
4. **Start with Phase 1** (Event Registration, Edit, Approve/Reject)
5. **Iterate** with user feedback

**Ready to implement? Let's start with Event Registration! 🚀**
