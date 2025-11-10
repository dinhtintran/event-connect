import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/event_management/data/api/event_api.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _eventApi = EventApi();
  final _storage = const FlutterSecureStorage();

  bool isFavorite = false;
  bool isRegistered = false;
  bool isLoadingRegistration = true;
  bool isRegistering = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    setState(() {
      isLoadingRegistration = true;
    });

    try {
      final accessToken = await _storage.read(key: 'auth_access');

      if (accessToken == null) {
        setState(() {
          isRegistered = false;
          isLoadingRegistration = false;
        });
        return;
      }

      // Get user's registered events and check if this event is in the list
      final result = await _eventApi.getMyEvents(accessToken: accessToken);

      if (result['status'] == 200) {
        final data = result['body'];

        if (data['results'] != null) {
          final registrations = data['results'] as List;

          // Check if current event is in registered events
          final registered = registrations.any((registration) {
            final eventData = registration['event'];
            return eventData != null && eventData['id'].toString() == widget.event.id;
          });

          setState(() {
            isRegistered = registered;
            isLoadingRegistration = false;
          });
        }
      } else {
        setState(() {
          isLoadingRegistration = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingRegistration = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      isRegistering = true;
    });

    try {
      final accessToken = await _storage.read(key: 'auth_access');

      if (accessToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn cần đăng nhập để đăng ký sự kiện')),
          );
        }
        setState(() {
          isRegistering = false;
        });
        return;
      }

      // Call register API
      final result = await _eventApi.registerForEvent(
        accessToken: accessToken,
        eventId: widget.event.id,
      );

      if (result['status'] == 200 || result['status'] == 201) {
        setState(() {
          isRegistered = true;
          isRegistering = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký sự kiện thành công!'),
              backgroundColor: Color(0xFF5669FF),
            ),
          );
        }
      } else {
        setState(() {
          isRegistering = false;
        });

        final errorMessage = result['body']?['error'] ?? 'Không thể đăng ký sự kiện';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      setState(() {
        isRegistering = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _handleCheckIn() async {
    // TODO: Call check-in API
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in thành công!'),
          backgroundColor: Color(0xFF5669FF),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.1 * 255).round()),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).round()),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                    onPressed: () {},
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade200,
                      child: const Icon(Icons.person, size: 20, color: Colors.grey),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.event.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 48),
                          );
                        },
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha((0.7 * 255).round()),
                            ],
                          ),
                        ),
                      ),
                      // Title and description on image
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Một buổi tối lãng mạn với những giai điệu jazz cổ điển dưới ánh sao.',
                                style: TextStyle(
                                color: Colors.white.withAlpha((0.9 * 255).round()),
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Favorite and Share buttons
                      Positioned(
                        top: 140,
                        right: 16,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isFavorite = !isFavorite;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha((0.3 * 255).round()),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? Colors.red : Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                // Share functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Chia sẻ sự kiện'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                  color: Colors.white.withAlpha((0.3 * 255).round()),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.share,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      _buildInfoRow(
                        Icons.calendar_today,
                        _formatDate(widget.event.date),
                        const Color(0xFF5669FF),
                      ),
                      const SizedBox(height: 16),
                      // Time
                      _buildInfoRow(
                        Icons.access_time,
                        '${DateFormat('HH:mm').format(widget.event.date)} - ${DateFormat('HH:mm').format(widget.event.date.add(const Duration(hours: 3)))}',
                        const Color(0xFF5669FF),
                      ),
                      const SizedBox(height: 16),
                      // Location
                      _buildInfoRow(
                        Icons.location_on,
                        widget.event.location,
                        const Color(0xFF5669FF),
                      ),
                      const SizedBox(height: 32),
                      // Description Section
                      const Text(
                        'Mô tả',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF120D26),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Đắm mình vào một buổi tối mê hoặc với những giai điệu Jazz êm dịu tại Đêm nhạc Jazz mùa hè hằng năm của chúng tôi. Lắng nghe những nghệ sĩ Jazz nổi tiếng trong nước biểu diễn, tạo ra một bầu không khí hoàn hảo cho một buổi tối thư giãn và thưởng thức âm nhạc. Đừng bỏ lỡ cơ hội trải nghiệm sự kết hợp kỳ diệu giữa âm nhạc, không khí và cộng đồng. Mang theo bạn bè và gia đình để có một buổi tối khó quên!',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Organizer Section
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade200,
                            child: const Icon(Icons.music_note, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Câu lạc bộ Âm nhạc',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF120D26),
                                  ),
                                ),
                                Text(
                                  'Nhà tổ chức sự kiện',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF747688),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Xem hồ sơ',
                              style: TextStyle(
                                color: Color(0xFF5669FF),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Attendees info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              color: Color(0xFF5669FF),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '150 người tham dự',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF120D26),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Đã đăng ký',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Space for button
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bottom Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.05 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: isLoadingRegistration
                  ? const Center(child: CircularProgressIndicator())
                  : isRegistered
                      ? Row(
                          children: [
                            // Đã đăng ký button (disabled/info only)
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Đã đăng ký',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Check-in button
                            Expanded(
                              flex: 3,
                              child: ElevatedButton(
                                onPressed: _handleCheckIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5669FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Check-in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: isRegistering ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5669FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: isRegistering
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Đăng ký',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF120D26),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Chủ nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
    final weekday = weekdays[date.weekday % 7];
    final day = date.day;
    final month = date.month;
    final year = date.year;
    return '$weekday, $day tháng $month, $year';
  }
}

