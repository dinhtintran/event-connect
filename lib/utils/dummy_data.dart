import '../models/event.dart';

class DummyData {
  static final List<Event> events = [
    // Upcoming Events (Sắp tới)
    Event(
      id: '1',
      title: 'Digital Marketing Summit 2024',
      imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
      date: DateTime(2025, 8, 15, 10, 0),
      location: 'Virtual Conference',
      category: 'Công nghệ',
      isFeatured: true,
    ),
    Event(
      id: '2',
      title: 'Web Development Masterclass',
      imageUrl: 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800',
      date: DateTime(2025, 8, 20, 14, 30),
      location: 'Tech Hub Auditorium',
      category: 'Công nghệ',
      isFeatured: true,
    ),
    Event(
      id: '3',
      title: 'Lễ Hội Âm Nhạc Mùa Hè',
      imageUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=800',
      date: DateTime(2025, 12, 20, 18, 0),
      location: 'Sân vận động trường',
      category: 'Âm nhạc',
    ),
    Event(
      id: '4',
      title: 'Hội Thảo AI và Machine Learning',
      imageUrl: 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800',
      date: DateTime(2025, 11, 25, 9, 0),
      location: 'Phòng 205',
      category: 'Công nghệ',
    ),
    Event(
      id: '5',
      title: 'Workshop Thiết Kế UI/UX',
      imageUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800',
      date: DateTime(2025, 11, 15, 14, 0),
      location: 'Phòng Sáng tạo',
      category: 'Nghệ thuật',
    ),
    // Past Events (Đã qua)
    Event(
      id: '6',
      title: 'Đêm nhạc Cổ điển: Giai điệu Mùa Thu',
      imageUrl: 'https://images.unsplash.com/photo-1501281668745-f7f57925c3b4?w=800',
      date: DateTime(2025, 10, 20, 19, 0),
      location: 'Nhà hát Lớn',
      category: 'Âm nhạc',
      isFeatured: false,
    ),
    Event(
      id: '7',
      title: 'Ngày Hội Tuyển Dụng 2025',
      imageUrl: 'https://images.unsplash.com/photo-1591115765373-5207764f72e7?w=800',
      date: DateTime(2025, 10, 10, 9, 0),
      location: 'Hội trường lớn',
      category: 'Nghề nghiệp',
    ),
    Event(
      id: '8',
      title: 'Triển Lãm Nghệ Thuật Đương Đại',
      imageUrl: 'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=800',
      date: DateTime(2025, 9, 15, 10, 0),
      location: 'Bảo tàng Mỹ thuật',
      category: 'Nghệ thuật',
    ),
    Event(
      id: '9',
      title: 'Giải đấu E-Sports',
      imageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=800',
      date: DateTime(2025, 9, 5, 14, 0),
      location: 'Gaming Arena',
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
