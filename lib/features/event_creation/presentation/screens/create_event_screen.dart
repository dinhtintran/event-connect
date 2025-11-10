import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:event_connect/features/authentication/authentication.dart';
import 'package:event_connect/features/event_creation/data/repositories/club_admin_repository.dart';
import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';

class CreateEventScreen extends StatefulWidget {
  final String? clubId;
  
  const CreateEventScreen({super.key, this.clubId});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ClubAdminRepository(api: ClubAdminApi());
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationDetailController = TextEditingController();
  final _capacityController = TextEditingController();
  
  // Form state
  String _selectedCategory = 'academic';
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  DateTime? _registrationStartDate;
  DateTime? _registrationEndDate;
  bool _isFeatured = false;
  bool _requiresApproval = true;
  bool _isSubmitting = false;
  
  String? _clubId;
  
  // Categories from backend spec
  final List<Map<String, String>> _categories = [
    {'value': 'academic', 'label': 'Học thuật'},
    {'value': 'sports', 'label': 'Thể thao'},
    {'value': 'cultural', 'label': 'Văn hóa'},
    {'value': 'technology', 'label': 'Công nghệ'},
    {'value': 'volunteer', 'label': 'Tình nguyện'},
    {'value': 'entertainment', 'label': 'Giải trí'},
    {'value': 'workshop', 'label': 'Workshop'},
    {'value': 'seminar', 'label': 'Hội thảo'},
    {'value': 'competition', 'label': 'Thi đấu'},
    {'value': 'other', 'label': 'Khác'},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadClubId();
  }
  
  Future<void> _loadClubId() async {
    if (widget.clubId != null) {
      setState(() {
        _clubId = widget.clubId;
      });
      return;
    }
    
    // Get club ID from user profile (same logic as club_events_page)
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user == null) return;
    
    String? clubId;
    if (user.profile.clubName != null && user.profile.clubName!.isNotEmpty) {
      try {
        final clubApi = ClubAdminApi();
        final clubsResult = await clubApi.clubApi.getAllClubs();
        if (clubsResult['status'] == 200) {
          final clubs = clubsResult['body'];
          if (clubs is Map && clubs.containsKey('results')) {
            final results = clubs['results'] as List;
            try {
              final matchingClub = results.firstWhere(
                (c) => c['name'] == user.profile.clubName,
              );
              clubId = matchingClub['id']?.toString();
            } catch (e) {
              debugPrint('Club not found by name');
            }
          } else if (clubs is List) {
            try {
              final matchingClub = clubs.firstWhere(
                (c) => c['name'] == user.profile.clubName,
              );
              clubId = matchingClub['id']?.toString();
            } catch (e) {
              debugPrint('Club not found by name');
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching clubs: $e');
      }
    }
    
    setState(() {
      _clubId = clubId ?? '1'; // Fallback
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationDetailController.dispose();
    _capacityController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDate(BuildContext context, {required bool isStart, bool isRegistration = false}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isRegistration) {
          if (isStart) {
            _registrationStartDate = picked;
          } else {
            _registrationEndDate = picked;
          }
        } else {
          if (isStart) {
            _startDate = picked;
          } else {
            _endDate = picked;
          }
        }
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context, {required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigo,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }
  
  DateTime? _combineDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
  
  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null) return 'Chọn ngày';
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    if (time == null) return dateStr;
    return '$dateStr ${time.format(context)}';
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
      );
      return;
    }
    
    if (_clubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin CLB')),
      );
      return;
    }
    
    if (_startDate == null || _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu')),
      );
      return;
    }
    
    if (_endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian kết thúc')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final startAt = _combineDateTime(_startDate, _startTime)!;
      final endAt = _combineDateTime(_endDate, _endTime)!;
      
      if (endAt.isBefore(startAt)) {
        throw Exception('Thời gian kết thúc phải sau thời gian bắt đầu');
      }
      
      // Prepare event data according to API spec
      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'capacity': int.parse(_capacityController.text.trim()),
      };
      
      // Optional fields
      if (_locationDetailController.text.isNotEmpty) {
        eventData['location_detail'] = _locationDetailController.text.trim();
      }
      
      if (_registrationStartDate != null) {
        eventData['registration_start'] = _registrationStartDate!.toIso8601String();
      }
      
      if (_registrationEndDate != null) {
        eventData['registration_end'] = _registrationEndDate!.toIso8601String();
      }
      
      eventData['is_featured'] = _isFeatured;
      eventData['requires_approval'] = _requiresApproval;
      
      // Create event via API
      final createdEvent = await _repository.createEvent(_clubId!, eventData);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tạo sự kiện "${createdEvent.title}" thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back
      Navigator.pop(context, true); // Return true to indicate success
      
    } catch (e) {
      debugPrint('Error creating event: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tạo sự kiện mới',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitForm,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Tạo',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tên sự kiện *',
                hintText: 'VD: Hackathon 2025',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên sự kiện';
                }
                if (value.trim().length < 5) {
                  return 'Tên sự kiện phải có ít nhất 5 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Danh mục *',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((cat) {
                return DropdownMenuItem(
                  value: cat['value'],
                  child: Text(cat['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả *',
                hintText: 'Mô tả chi tiết về sự kiện...',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                if (value.trim().length < 20) {
                  return 'Mô tả phải có ít nhất 20 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Địa điểm *',
                hintText: 'VD: Phòng hội thảo A',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa điểm';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Location Detail (Optional)
            TextFormField(
              controller: _locationDetailController,
              decoration: InputDecoration(
                labelText: 'Chi tiết địa điểm',
                hintText: 'VD: Tầng 3, tòa nhà A',
                prefixIcon: const Icon(Icons.place),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Capacity
            TextFormField(
              controller: _capacityController,
              decoration: InputDecoration(
                labelText: 'Sức chứa *',
                hintText: 'VD: 100',
                prefixIcon: const Icon(Icons.people),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập sức chứa';
                }
                final capacity = int.tryParse(value.trim());
                if (capacity == null || capacity <= 0) {
                  return 'Sức chứa phải là số dương';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            
            // Date & Time Section
            Text(
              'Thời gian sự kiện',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Start Date & Time
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, isStart: true),
                    icon: const Icon(Icons.calendar_today, size: 20),
                    label: Text(_formatDateTime(_startDate, null)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context, isStart: true),
                    icon: const Icon(Icons.access_time, size: 20),
                    label: Text(_startTime?.format(context) ?? 'Chọn giờ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bắt đầu: ${_formatDateTime(_startDate, _startTime)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            
            // End Date & Time
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context, isStart: false),
                    icon: const Icon(Icons.calendar_today, size: 20),
                    label: Text(_formatDateTime(_endDate, null)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context, isStart: false),
                    icon: const Icon(Icons.access_time, size: 20),
                    label: Text(_endTime?.format(context) ?? 'Chọn giờ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Kết thúc: ${_formatDateTime(_endDate, _endTime)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 24),
            
            // Registration Period (Optional)
            ExpansionTile(
              title: const Text('Thời gian đăng ký (Tùy chọn)'),
              leading: const Icon(Icons.app_registration),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _selectDate(context, isStart: true, isRegistration: true),
                        icon: const Icon(Icons.calendar_today, size: 20),
                        label: Text(
                          _registrationStartDate != null
                              ? 'Bắt đầu: ${DateFormat('dd/MM/yyyy').format(_registrationStartDate!)}'
                              : 'Chọn ngày bắt đầu đăng ký',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _selectDate(context, isStart: false, isRegistration: true),
                        icon: const Icon(Icons.calendar_today, size: 20),
                        label: Text(
                          _registrationEndDate != null
                              ? 'Kết thúc: ${DateFormat('dd/MM/yyyy').format(_registrationEndDate!)}'
                              : 'Chọn ngày kết thúc đăng ký',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Options
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sự kiện nổi bật'),
                    subtitle: const Text('Hiển thị trên trang chủ'),
                    value: _isFeatured,
                    onChanged: (value) {
                      setState(() {
                        _isFeatured = value;
                      });
                    },
                    secondary: const Icon(Icons.star),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Yêu cầu phê duyệt'),
                    subtitle: const Text('Cần duyệt trước khi công khai'),
                    value: _requiresApproval,
                    onChanged: (value) {
                      setState(() {
                        _requiresApproval = value;
                      });
                    },
                    secondary: const Icon(Icons.approval),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sự kiện sẽ được gửi để phê duyệt nếu bật "Yêu cầu phê duyệt"',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
