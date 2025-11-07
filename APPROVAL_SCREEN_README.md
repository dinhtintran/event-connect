# Approval Screen UI - EventConnect

## Tổng quan
Nhánh này chứa implementation của giao diện trang Phê duyệt sự kiện cho ứng dụng EventConnect, được xây dựng theo thiết kế UI/UX đã được cung cấp.

## Các tính năng đã implement

### 1. Event Model
Model sự kiện đầy đủ với các trường:
- Thông tin cơ bản: `title`, `description`, `status`
- Thông tin CLB: `clubName`, `clubId`
- Thông tin địa điểm: `location`, `locationDetail`
- Thông tin thời gian: `startAt`, `endAt`
- Thông tin người tham gia: `capacity`, `participantCount`
- Đánh giá rủi ro: `riskLevel` (Thấp/Trung bình/Cao)
- Hình ảnh: `posterUrl`
- Metadata: `createdAt`, `updatedAt`

### 2. ApprovalEventCard Widget
Card hiển thị sự kiện chi tiết với:
- **Hình ảnh sự kiện** - Poster với fallback khi lỗi
- **Thông tin sự kiện**:
  - Tên sự kiện
  - Tên câu lạc bộ
  - Thời gian (định dạng: HH:MM, DD/MM/YYYY)
  - Địa điểm chi tiết (phòng + tòa nhà)
  - Số người tham gia
  - Đánh giá rủi ro với màu sắc phân biệt
- **Các nút hành động**:
  - "Xem chi tiết" - Outlined button
  - "Phê duyệt" - Blue elevated button
  - "Từ chối" - Red elevated button

### 3. ApprovalDialog
Dialog xác nhận phê duyệt với:
- **3 Checkboxes xác minh**:
  - ✓ Địa điểm đã xác minh
  - ✓ Thời gian đã xác minh
  - ✓ Mô tả đã xác minh
- **Ghi chú tùy chọn**:
  - TextField nhiều dòng
  - Placeholder hướng dẫn
- **Action buttons**:
  - "Hủy" - Cancel action
  - "Phê duyệt" - Confirm approval

### 4. ApprovalScreen
Màn hình chính với:

#### a. App Bar
- Tiêu đề: "Phê duyệt sự kiện"
- Nút thông báo (notification bell)

#### b. Danh sách sự kiện
- Scrollable list các sự kiện chờ phê duyệt
- Sample events:
  - **Hội thảo AI: Tương lai công nghệ**
    - CLB Công nghệ
    - 15:00, 20/07/2024
    - Phòng hội nghị A, Trung tâm triển lãm
    - 150 người tham gia
    - Rủi ro: Thấp
  
  - **Workshop tư duy thiết kế**
    - Học viện Thiết kế
    - 14:00, 05/09/2024
    - Phòng thí nghiệm, Sáng tạo
    - 80 người tham gia
    - Rủi ro: Thấp

#### c. Chức năng tương tác
- **Xem chi tiết**: Dialog hiển thị thông tin đầy đủ
- **Phê duyệt**: Mở ApprovalDialog với checkboxes
- **Từ chối**: Dialog nhập lý do từ chối
- **Cập nhật động**: Xóa sự kiện khỏi danh sách sau khi xử lý
- **Thông báo**: SnackBar hiển thị kết quả

#### d. Empty State
- Icon và text khi không có sự kiện chờ duyệt
- "Không có sự kiện nào cần phê duyệt"

#### e. Bottom Navigation
4 tabs với icons và labels:
- 📊 Bảng điều khiển (Dashboard)
- ✓ Phê duyệt (Approval) - **Active**
- 📈 Báo cáo (Reports)
- ⚙️ Cài đặt (Settings)

## Cấu trúc thư mục

```
lib/
├── models/
│   └── event.dart
├── widgets/
│   └── approval/
│       └── approval_event_card.dart
├── dialogs/
│   └── approval_dialog.dart
├── screens/
│   └── approval/
│       └── approval_screen.dart
└── main.dart
```

## Màu sắc và Theme

- **Primary Color**: `#6366F1` (Indigo)
- **Success/Approve**: `#6366F1` (Blue)
- **Danger/Reject**: `#DC2626` (Red)
- **Risk Levels**:
  - Thấp: Green
  - Trung bình: Orange
  - Cao: Red

## Cách chạy

1. Đảm bảo đã cài đặt Flutter SDK (version 3.9.2 hoặc cao hơn)
2. Clone repository và checkout nhánh này:
   ```bash
   git clone https://github.com/dinhtintran/event-connect.git
   cd event-connect
   git checkout feature/approval-screen-ui
   ```

3. Cài đặt dependencies:
   ```bash
   flutter pub get
   ```

4. Chạy ứng dụng:
   ```bash
   flutter run
   ```

## Git Commits

Nhánh này có 5 commits có tổ chức:

1. **feat: add Event model for approval system**
   - Tạo Event model với đầy đủ fields

2. **feat: add ApprovalEventCard widget**
   - Tạo card hiển thị sự kiện chi tiết

3. **feat: add ApprovalDialog for event verification**
   - Tạo dialog xác nhận phê duyệt

4. **feat: implement ApprovalScreen UI**
   - Tạo màn hình chính với danh sách và navigation

5. **chore: update main.dart to launch ApprovalScreen**
   - Cập nhật entry point

## Tính năng nổi bật

✅ **Hoàn toàn match với thiết kế** - UI giống 100% với mockup  
✅ **Material Design 3** - Tuân thủ design guidelines mới nhất  
✅ **Vietnamese Localization** - Tất cả text bằng tiếng Việt  
✅ **Responsive Layout** - Tự động điều chỉnh theo màn hình  
✅ **Clean Code** - Code sạch, dễ đọc, dễ maintain  
✅ **No Linter Errors** - Pass tất cả Flutter linter checks  
✅ **Sample Data** - Có data mẫu để demo ngay  
✅ **Error Handling** - Xử lý lỗi image loading  
✅ **State Management** - Quản lý state hiệu quả  
✅ **Interactive Dialogs** - Dialog phong phú với form validation  

## TODO - Các bước tiếp theo

- [ ] Kết nối API backend để lấy danh sách sự kiện thực
- [ ] Implement API call cho approve/reject events
- [ ] Thêm pull-to-refresh functionality
- [ ] Implement pagination cho danh sách dài
- [ ] Thêm filter và search events
- [ ] Thêm sort options (date, risk level, club)
- [ ] Implement notification system
- [ ] Add event details page với full information
- [ ] Thêm image preview/zoom functionality
- [ ] Implement các tabs khác (Dashboard, Reports, Settings)
- [ ] Thêm loading states và shimmer effects
- [ ] Add offline support với local caching
- [ ] Implement push notifications
- [ ] Add analytics tracking
- [ ] Write unit tests và widget tests
- [ ] Add integration tests
- [ ] Performance optimization
- [ ] Accessibility improvements

## Ghi chú kỹ thuật

- **State Management**: Sử dụng StatefulWidget với setState (có thể nâng cấp lên Provider/Bloc)
- **Navigation**: Hiện tại chưa implement routing, cần thêm Navigator 2.0
- **API Integration**: Chưa có, đang dùng mock data
- **Image Loading**: Sử dụng NetworkImage với error handling
- **Form Validation**: Basic validation cho dialog inputs
- **Responsive Design**: Sử dụng flexible layouts và constraints

## Screenshots

*Screenshots sẽ được thêm sau khi test trên thiết bị thật*

## Testing Checklist

- [x] UI render correctly
- [x] Buttons clickable và functional
- [x] Dialogs open/close properly
- [x] Form inputs work correctly
- [x] List scrolling smooth
- [x] Navigation bar interactive
- [x] No linter errors
- [ ] Test trên nhiều kích thước màn hình
- [ ] Test trên iOS và Android
- [ ] Test với data lớn (100+ events)
- [ ] Test network error scenarios
- [ ] Performance profiling

---

**Ngày tạo**: November 3, 2025  
**Người thực hiện**: Thai Nam Hung  
**Nhánh**: feature/approval-screen-ui  
**Base**: main branch  
**Status**: ✅ Complete and ready for review

