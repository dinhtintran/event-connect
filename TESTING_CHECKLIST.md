# ✅ Testing Checklist - API Integration

## 🔧 Before Testing

- [ ] Backend server đang chạy (`python manage.py runserver`)
- [ ] Updated `apiBaseUrl` trong `app_config.dart`
- [ ] Run `flutter pub get`
- [ ] No compile errors

---

## 1️⃣ Authentication Flow

- [ ] Register new account
  - [ ] Success response
  - [ ] Tokens saved
- [ ] Login with credentials
  - [ ] Success response
  - [ ] Tokens saved
  - [ ] Redirected to home
- [ ] Token refresh works automatically
- [ ] Logout works

---

## 2️⃣ Home Screen (Event List)

- [ ] Events load from API
- [ ] Loading indicator shows
- [ ] Events display correctly
- [ ] Featured events section works
- [ ] Category chips work
- [ ] Category filter works
- [ ] Pull to refresh works
- [ ] Error message shows if backend down

---

## 3️⃣ Explore Screen

- [ ] Events load from API
- [ ] Search bar works
  - [ ] Type query
  - [ ] Results update
- [ ] Category filter works
- [ ] Grid/List view toggle
- [ ] Advanced filters work
  - [ ] Date range
  - [ ] Multiple categories
- [ ] Load more button works

---

## 4️⃣ My Events Screen

- [ ] Shows "Upcoming" tab
  - [ ] Loads registered events
  - [ ] Shows correct count
- [ ] Shows "Past" tab
  - [ ] Loads past events
- [ ] Shows "Saved" tab
  - [ ] Currently empty (to implement)
- [ ] Pull to refresh works
- [ ] Events display correctly

---

## 5️⃣ Event Detail Screen

- [ ] Event details load
- [ ] Register button works
  - [ ] Shows success message
  - [ ] Button changes to "Registered"
- [ ] Unregister works
  - [ ] Shows confirmation
  - [ ] Button changes back
- [ ] Feedback form works (if event attended)
  - [ ] Rating selection
  - [ ] Comment input
  - [ ] Submit works
  - [ ] Shows in feedback list

---

## 6️⃣ Error Handling

- [ ] Network error shows message
- [ ] 401 Unauthorized → redirects to login
- [ ] 403 Forbidden → shows permission error
- [ ] 404 Not Found → shows not found message
- [ ] 500 Server Error → shows server error
- [ ] Validation errors show correctly

---

## 7️⃣ Edge Cases

- [ ] Empty event list shows message
- [ ] No search results shows message
- [ ] Loading state shows correctly
- [ ] Pull to refresh while loading
- [ ] Register when event full
- [ ] Register when already registered
- [ ] Submit feedback without attending

---

## 🎯 Performance Tests

- [ ] App loads quickly (< 3s)
- [ ] Images load progressively
- [ ] No janky scrolling
- [ ] Search is responsive
- [ ] Category filter is instant
- [ ] No memory leaks

---

## 🔐 Security Tests

- [ ] Token stored securely
- [ ] Token included in requests
- [ ] Token refresh automatic
- [ ] Logout clears tokens
- [ ] Protected routes require auth

---

## 📱 Cross-Platform Tests

### Android
- [ ] App runs on emulator
- [ ] API calls work
- [ ] Images load
- [ ] No crashes

### iOS
- [ ] App runs on simulator
- [ ] API calls work
- [ ] Images load
- [ ] No crashes

### Web
- [ ] App runs on Chrome
- [ ] API calls work (check CORS)
- [ ] Images load
- [ ] Responsive design

---

## 🐛 Bug Report Template

**If you find issues, document them:**

```
Bug: [Short description]
Screen: [Which screen]
Steps:
1. [Step 1]
2. [Step 2]
3. [Step 3]
Expected: [What should happen]
Actual: [What actually happened]
Error: [Error message if any]
```

---

## ✅ Final Checks

- [ ] All critical features work
- [ ] No console errors
- [ ] Good user experience
- [ ] Error messages are helpful
- [ ] Loading states are smooth
- [ ] Ready for demo/presentation

---

## 📊 Test Results Summary

**Date**: ___________  
**Tester**: ___________  
**Total Tests**: 50+  
**Passed**: ___________  
**Failed**: ___________  
**Blocked**: ___________  

**Overall Status**: 🔴 Failed | 🟡 Partial | 🟢 Passed

---

## 🎉 When All Tests Pass

Congratulations! Your app is ready for:
- ✅ Demo to stakeholders
- ✅ User testing
- ✅ Code review
- ✅ Production deployment preparation

---

**Happy Testing! 🧪✨**
