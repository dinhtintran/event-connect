# 🧪 QA TESTING CHECKLIST - Saved Events Feature

## 📋 Test Environment Setup

- [ ] Backend API endpoints deployed and accessible
- [ ] Test user account created (Student role)
- [ ] At least 10 test events created in database
- [ ] App installed on testing device/emulator
- [ ] Network connection stable

---

## 🎯 Feature Overview

**Feature:** Saved Events (Bookmark Events)  
**User Story:** As a student, I want to save events I'm interested in, so I can easily find them later.  
**Entry Points:**
- EventDetailScreen → Heart icon button
- My Events → "Đã lưu" tab

---

## ✅ Test Cases

### TC-01: Save Event from Detail Screen
**Priority:** High  
**Steps:**
1. Login as student
2. Navigate to Explore → Select any event
3. Click heart icon (❤️) at top-right of poster
4. Observe icon change and SnackBar message

**Expected Results:**
- ✅ Heart icon changes from white outline to red filled
- ✅ SnackBar shows "Đã lưu sự kiện" (2 seconds)
- ✅ Network request: POST /api/events/{id}/save/ returns 200/201

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-02: View Saved Events in Tab
**Priority:** High  
**Steps:**
1. Complete TC-01 (save at least 3 events)
2. Navigate to My Events screen
3. Tap on "Đã lưu" tab (4th tab)
4. Observe saved events list

**Expected Results:**
- ✅ "Đã lưu" tab exists (4th tab after "Sắp tới", "Đang diễn ra", "Đã qua")
- ✅ All saved events appear in list
- ✅ Events display correct info (title, date, location, poster)
- ✅ List is scrollable if > 5 events

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-03: Unsave Event from Detail Screen
**Priority:** High  
**Steps:**
1. Navigate to a saved event detail (heart should be red)
2. Click red heart icon
3. Observe icon change and SnackBar message
4. Go back to My Events → Đã lưu tab

**Expected Results:**
- ✅ Heart icon changes from red filled to white outline
- ✅ SnackBar shows "Đã bỏ lưu sự kiện" (2 seconds)
- ✅ Event removed from "Đã lưu" list
- ✅ Network request: POST /api/events/{id}/unsave/ returns 200

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-04: Cross-Screen Consistency
**Priority:** High  
**Steps:**
1. From Explore screen, click any unsaved event
2. Save event (heart icon → red)
3. Go back, then navigate to same event from Featured list
4. Check heart icon status
5. Navigate to My Events → Đã lưu
6. Verify event appears

**Expected Results:**
- ✅ Heart icon remains red in all entry points
- ✅ Event appears in "Đã lưu" tab
- ✅ No duplicate entries
- ✅ Saved status consistent across app

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-05: Saved Status Persistence After Logout
**Priority:** High  
**Steps:**
1. Login, save 3 events
2. Go to My Events → Đã lưu, verify 3 events
3. Logout completely
4. Login again with same account
5. Navigate to My Events → Đã lưu

**Expected Results:**
- ✅ All 3 saved events still appear
- ✅ Heart icons red when viewing those events
- ✅ No data loss after logout/login
- ✅ Network request: GET /api/events/saved/ returns correct data

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-06: Empty Saved Events State
**Priority:** Medium  
**Steps:**
1. Login with new account (no saved events)
2. Navigate to My Events → Đã lưu tab
3. Observe empty state

**Expected Results:**
- ✅ Shows empty state message or empty list
- ✅ No crash or error
- ✅ User can still navigate to other tabs

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-07: Rapid Toggle (Stress Test)
**Priority:** Medium  
**Steps:**
1. Open event detail screen
2. Rapidly click heart icon 10 times (save/unsave)
3. Wait for all requests to complete
4. Check final state in My Events → Đã lưu

**Expected Results:**
- ✅ No app crash
- ✅ Final state matches last action
- ✅ No duplicate API requests
- ✅ SnackBar messages don't stack excessively

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-08: Pull-to-Refresh Saved Events
**Priority:** Medium  
**Steps:**
1. Navigate to My Events → Đã lưu (with saved events)
2. Pull down list to trigger refresh
3. Observe loading indicator and list update

**Expected Results:**
- ✅ Loading indicator appears
- ✅ List refreshes successfully
- ✅ Network request: GET /api/events/saved/ called
- ✅ Updated data displayed

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-09: Save Event That Is Full (Edge Case)
**Priority:** Low  
**Steps:**
1. Find an event with capacity = participantCount (full)
2. Try to save the event
3. Check if save operation succeeds

**Expected Results:**
- ✅ Save operation succeeds (saving ≠ registration)
- ✅ Event appears in saved list
- ✅ No error message about capacity

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-10: Save Event That Already Passed (Edge Case)
**Priority:** Low  
**Steps:**
1. Find an event with date in the past
2. Try to save the event
3. Check if save operation succeeds

**Expected Results:**
- ✅ Save operation succeeds
- ✅ Event appears in saved list
- ✅ No restriction on saving past events

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-11: Network Error Handling
**Priority:** High  
**Steps:**
1. Turn off device internet/wifi
2. Try to save an event
3. Observe error handling
4. Turn on internet
5. Retry save

**Expected Results:**
- ✅ Error SnackBar shows: "Có lỗi xảy ra, vui lòng thử lại"
- ✅ Heart icon does NOT change color
- ✅ App does not crash
- ✅ After reconnecting, save works normally

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-12: Backend Returns 500 Error
**Priority:** High  
**Steps:**
1. (Backend team: Force 500 error on save endpoint)
2. Try to save an event
3. Observe error handling

**Expected Results:**
- ✅ Error SnackBar shows: "Có lỗi xảy ra, vui lòng thử lại"
- ✅ Heart icon stays white (not saved)
- ✅ App does not crash
- ✅ User can retry

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-13: Save 50+ Events (Performance)
**Priority:** Low  
**Steps:**
1. Save 50 different events
2. Navigate to My Events → Đã lưu
3. Scroll through the list
4. Test pull-to-refresh

**Expected Results:**
- ✅ All 50 events load successfully
- ✅ Scrolling is smooth (no lag)
- ✅ Refresh works correctly
- ✅ No memory issues or crash

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-14: Visual States Verification
**Priority:** Medium  
**Steps:**
1. Open any event detail
2. Verify unsaved state visual
3. Save event
4. Verify saved state visual

**Expected Results - Unsaved:**
- ✅ Heart icon: white outline (favorite_border)
- ✅ Icon clearly visible on poster

**Expected Results - Saved:**
- ✅ Heart icon: red filled (favorite)
- ✅ Clear visual distinction from unsaved
- ✅ Icon color: RGB(255, 0, 0) or similar red

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

### TC-15: Multiple Users Same Event
**Priority:** Medium  
**Steps:**
1. User A saves Event X
2. User B saves Event X
3. User A unsaves Event X
4. User B checks their saved list

**Expected Results:**
- ✅ Both users can save same event independently
- ✅ User A's unsave doesn't affect User B
- ✅ Event still in User B's saved list
- ✅ Backend correctly isolates user data

**Pass:** [ ]  **Fail:** [ ]  **N/A:** [ ]

---

## 🐛 Bug Report Template

**Bug ID:** BUG-SAVED-XXX  
**Severity:** [Critical / High / Medium / Low]  
**Test Case:** TC-XX  

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Result:**


**Actual Result:**


**Screenshots/Logs:**


**Device Info:**
- Device: 
- OS Version: 
- App Version: 

---

## 📊 Test Summary

**Total Test Cases:** 15  
**Passed:** ___  
**Failed:** ___  
**N/A:** ___  
**Pass Rate:** ____%

**Critical Issues Found:** ___  
**High Issues Found:** ___  
**Medium Issues Found:** ___  
**Low Issues Found:** ___

---

## ✅ Sign-off

**Tested By:** _______________  
**Date:** _______________  
**Build Version:** _______________  
**Status:** [ ] Approved for Production  [ ] Needs Fixes

**Notes:**



---

**Reference Documents:**
- `SAVED_EVENTS_IMPLEMENTATION_SUMMARY.md` - Technical details
- `SAVED_EVENTS_QUICK_START.md` - Quick reference
- `BACKEND_TODO_SAVED_EVENTS.md` - Backend API specs
