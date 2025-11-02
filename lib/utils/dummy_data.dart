import '../models/event.dart';

class DummyData {
  static final List<Event> events = [
    Event(
      id: '1',
      title: 'Đêm nhạc Cổ điển: Giai điệu Mùa Thu',
      imageUrl: 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800',
      date: DateTime(2024, 7, 20),
      location: 'Sân vận động trường',
      category: 'Âm nhạc',
      isFeatured: true,
    ),
    Event(
      id: '2',
      title: 'Giải đấu Game',
      imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800',
      date: DateTime(2024, 7, 5),
      location: 'Phòng 205',
      category: 'Công nghệ',
      isFeatured: true,
    ),
    Event(
      id: '3',
      title: 'Lễ Hội Âm Nhạc Hè',
      imageUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
      date: DateTime(2024, 7, 20),
      location: 'Sân vận động trường',
      category: 'Âm nhạc',
    ),
    Event(
      id: '4',
      title: 'Hội Thảo Khởi Nghiệp',
      imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
      date: DateTime(2024, 7, 5),
      location: 'Phòng 205',
      category: 'Công nghệ',
    ),
    Event(
      id: '5',
      title: 'Buổi Đọc Sách Cộng Đồng',
      imageUrl: 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=800',
      date: DateTime(2024, 7, 25, 19, 0),
      location: 'Thư viện',
      category: 'Văn hóa',
    ),
    Event(
      id: '6',
      title: 'Ngày Hội Tuyển Dụng',
      imageUrl: 'https://images.unsplash.com/photo-1591115765373-5207764f72e7?w=800',
      date: DateTime(2024, 8, 10, 9, 0),
      location: 'Hội trường lớn',
      category: 'Nghề nghiệp',
    ),
    Event(
      id: '7',
      title: 'Đêm Nhạc Giao Lưu Sinh Viên',
      imageUrl: 'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=800',
      date: DateTime(2024, 8, 30, 20, 0),
      location: 'Quán cà phê sân thượng',
      category: 'Âm nhạc',
    ),
    Event(
      id: '8',
      title: 'Hội Thảo Khởi Nghiệp',
      imageUrl: 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=800',
      date: DateTime(2024, 9, 2, 14, 0),
      location: 'Phòng Zoom 101',
      category: 'Công nghệ',
    ),
  ];

  static List<String> get categories => [
        'Tất cả',
        'Âm nhạc',
        'Công nghệ',
        'Nghệ thuật',
        'Thể thao',
      ];
}
