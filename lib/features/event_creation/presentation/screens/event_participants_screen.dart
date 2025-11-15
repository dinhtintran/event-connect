import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/event_creation/data/repositories/club_admin_repository.dart';
import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';
import 'package:event_connect/features/authentication/domain/services/auth_service.dart';

class EventParticipantsScreen extends StatefulWidget {
  final Event event;
  
  const EventParticipantsScreen({super.key, required this.event});

  @override
  State<EventParticipantsScreen> createState() => _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  final _repository = ClubAdminRepository(api: ClubAdminApi());
  
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';
  
  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'Tất cả'},
    {'value': 'registered', 'label': 'Đã đăng ký'},
    {'value': 'checked_in', 'label': 'Đã check-in'},
    {'value': 'attended', 'label': 'Đã tham gia'},
    {'value': 'cancelled', 'label': 'Đã hủy'},
  ];

  @override
  void initState() {
    super.initState();
    _debugUserPermissions();
    _loadParticipants();
  }
  
  void _debugUserPermissions() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.user;
    
    debugPrint('👤 ========== USER PERMISSION DEBUG ==========');
    debugPrint('👤 Current user: ${user?.username}');
    debugPrint('👤 User role: ${user?.role}');
    debugPrint('👤 User email: ${user?.email}');
    debugPrint('👤 Club name: ${user?.profile.clubName}');
    debugPrint('👤 Club role: ${user?.profile.clubRole}');
    debugPrint('👤 Is system admin: ${user?.isSystemAdmin}');
    debugPrint('👤 Is club leader: ${user?.profile.isClubLeader}');
    debugPrint('👤 Is club president: ${user?.profile.isClubPresident}');
    debugPrint('👤 Can view participants: ${user?.canViewParticipants}');
    debugPrint('👤 Can manage events: ${user?.canManageEvents}');
    debugPrint('👤 Has club admin permission: ${user?.hasClubAdminPermission}');
    debugPrint('👤 ============================================');
    debugPrint('🎯 Event ID: ${widget.event.id}');
    debugPrint('🎯 Event Club: ${widget.event.clubName}');
    debugPrint('🎯 Match: ${user?.profile.clubName == widget.event.clubName}');
    debugPrint('👤 ============================================');
  }
  
  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      debugPrint('🔍 Loading participants for event: ${widget.event.id}');
      debugPrint('🔍 Event title: ${widget.event.title}');
      debugPrint('🔍 Event club: ${widget.event.clubName}');
      debugPrint('🔍 Selected filter: $_selectedStatus');
      
      // WORKAROUND: Backend has bug with status query param
      // Always fetch all participants, then filter on frontend
      final allParticipants = await _repository.getEventParticipants(
        widget.event.id,
        status: null, // Always null to avoid 404
      );
      
      // Filter on frontend side
      final filteredParticipants = _selectedStatus == 'all'
          ? allParticipants
          : allParticipants.where((p) {
              final participantStatus = p['status'] as String?;
              return participantStatus == _selectedStatus;
            }).toList();
      
      debugPrint('✅ Loaded ${allParticipants.length} total participants');
      debugPrint('✅ Filtered to ${filteredParticipants.length} participants');
      
      setState(() {
        _participants = filteredParticipants;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading participants: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      
      // Handle permission error specifically
      String errorMsg = e.toString();
      if (errorMsg.contains('permission') || errorMsg.contains('403') || errorMsg.contains('401')) {
        errorMsg = 'Bạn không có quyền xem danh sách người tham gia.\n\n'
                   'Lý do có thể:\n'
                   '• Bạn không phải Admin hoặc Chủ tịch CLB này\n'
                   '• Backend chưa cấp quyền cho tài khoản của bạn\n'
                   '• ClubMembership chưa được tạo\n\n'
                   'Chi tiết lỗi: ${errorMsg.contains('Exception:') ? errorMsg.split('Exception:').last : errorMsg}';
      } else {
        errorMsg = 'Lỗi khi tải danh sách người tham gia:\n\n${e.toString()}';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }
  
  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadParticipants();
  }
  
  String _getStatusText(String? status) {
    switch (status) {
      case 'registered':
        return 'Đã đăng ký';
      case 'checked_in':
        return 'Đã check-in';
      case 'attended':
        return 'Đã tham gia';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'N/A';
    }
  }
  
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'registered':
        return Colors.blue;
      case 'checked_in':
        return Colors.orange;
      case 'attended':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Người tham gia'),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Export button (future feature)
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng xuất danh sách sẽ được cập nhật')),
              );
            },
            tooltip: 'Xuất danh sách',
          ),
        ],
      ),
      body: Column(
        children: [
          // Event info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Participant count with smart display
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      widget.event.participantDisplayText,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.event.isFull
                            ? Colors.red
                            : widget.event.hasEnded
                                ? Colors.grey
                                : widget.event.isLive
                                    ? Colors.orange
                                    : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.event.availabilityText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Detailed breakdown if available
                if (widget.event.totalParticipants > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 20),
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (widget.event.registrationCount > 0)
                          _buildCountChip(
                            Icons.how_to_reg,
                            'Đăng ký: ${widget.event.registrationCount}',
                            Colors.blue,
                          ),
                        if (widget.event.checkedInCount > 0)
                          _buildCountChip(
                            Icons.check_circle,
                            'Check-in: ${widget.event.checkedInCount}',
                            Colors.orange,
                          ),
                        if (widget.event.attendedCount > 0)
                          _buildCountChip(
                            Icons.event_available,
                            'Đã tham dự: ${widget.event.attendedCount}',
                            Colors.green,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Status filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text(
                  'Trạng thái:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statusFilters.map((filter) {
                        final isSelected = _selectedStatus == filter['value'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(filter['label']!),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _onStatusFilterChanged(filter['value']!);
                              }
                            },
                            selectedColor: Colors.indigo,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Participants list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadParticipants,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : _participants.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có người đăng ký',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadParticipants,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _participants.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final participant = _participants[index];
                                final user = participant['user'];
                                final status = participant['status'] as String?;
                                final registeredAt = participant['registered_at'];
                                
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.indigo.shade100,
                                    child: Text(
                                      (user?['full_name'] ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.indigo,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user?['full_name'] ?? 'Người dùng',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (user?['student_id'] != null)
                                        Text('MSSV: ${user['student_id']}'),
                                      if (user?['email'] != null)
                                        Text(
                                          user['email'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      if (registeredAt != null)
                                        Text(
                                          'Đăng ký: ${_formatDateTime(registeredAt)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getStatusColor(status),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _getStatusText(status),
                                      style: TextStyle(
                                        color: _getStatusColor(status),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(dynamic dateTime) {
    try {
      if (dateTime is String) {
        final dt = DateTime.parse(dateTime);
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (dateTime is DateTime) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      return dateTime.toString();
    } catch (e) {
      return 'N/A';
    }
  }
  
  /// Build a small chip to display count breakdown
  Widget _buildCountChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
