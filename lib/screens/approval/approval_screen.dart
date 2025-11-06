import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../widgets/approval/approval_event_card.dart';
import '../../dialogs/approval_dialog.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  int _selectedIndex = 1; // Approval tab is selected

  // Sample pending events data
  final List<Event> _pendingEvents = [
    Event(
      id: '1',
      title: 'Hội thảo AI: Tương lai công nghệ',
      clubName: 'CLB Công nghệ',
      clubId: '1',
      description: 'Hội thảo về tương lai của trí tuệ nhân tạo và công nghệ',
      location: 'Phòng hội nghị A',
      locationDetail: 'Trung tâm triển lãm',
      startAt: DateTime(2024, 7, 20, 15, 0),
      endAt: DateTime(2024, 7, 20, 18, 0),
      posterUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
      capacity: 200,
      participantCount: 150,
      status: 'pending',
      riskLevel: 'Thấp',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Event(
      id: '2',
      title: 'Workshop tư duy thiết kế',
      clubName: 'Học viện Thiết kế',
      clubId: '2',
      description: 'Workshop về design thinking và UX/UI',
      location: 'Phòng thí nghiệm',
      locationDetail: 'Sáng tạo',
      startAt: DateTime(2024, 9, 5, 14, 0),
      endAt: DateTime(2024, 9, 5, 17, 0),
      posterUrl: 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=800',
      capacity: 100,
      participantCount: 80,
      status: 'pending',
      riskLevel: 'Thấp',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  void _handleViewDetails(Event event) {
    // TODO: Navigate to event details page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết sự kiện'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tên: ${event.title}'),
              const SizedBox(height: 8),
              Text('CLB: ${event.clubName}'),
              const SizedBox(height: 8),
              Text('Mô tả: ${event.description}'),
              const SizedBox(height: 8),
              Text('Sức chứa: ${event.capacity} người'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleApprove(Event event) {
    showDialog(
      context: context,
      builder: (context) => ApprovalDialog(
        event: event,
        onApprove: (locationVerified, timeVerified, descriptionVerified, note) {
          // TODO: Call API to approve event
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã phê duyệt sự kiện "${event.title}"'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Remove from pending list
          setState(() {
            _pendingEvents.removeWhere((e) => e.id == event.id);
          });
        },
      ),
    );
  }

  void _handleReject(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Từ chối sự kiện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc chắn muốn từ chối sự kiện "${event.title}"?'),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Lý do từ chối',
                hintText: 'Nhập lý do từ chối...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Call API to reject event
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã từ chối sự kiện "${event.title}"'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              
              // Remove from pending list
              setState(() {
                _pendingEvents.removeWhere((e) => e.id == event.id);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  void _onNavigationTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Navigate to different screens based on index
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Phê duyệt sự kiện',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: _pendingEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có sự kiện nào cần phê duyệt',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingEvents.length,
              itemBuilder: (context, index) {
                final event = _pendingEvents[index];
                return ApprovalEventCard(
                  event: event,
                  onViewDetails: () => _handleViewDetails(event),
                  onApprove: () => _handleApprove(event),
                  onReject: () => _handleReject(event),
                );
              },
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavigationTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Bảng điều khiển',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              activeIcon: Icon(Icons.check_circle),
              label: 'Phê duyệt',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Báo cáo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}

