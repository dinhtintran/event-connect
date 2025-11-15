import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:event_connect/features/event_creation/data/repositories/club_admin_repository.dart';
import 'package:event_connect/features/event_creation/data/api/club_admin_api.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';

class EditEventScreen extends StatefulWidget {
  final Event event;
  
  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = ClubAdminRepository(api: ClubAdminApi());
  
  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _locationDetailController;
  late final TextEditingController _capacityController;
  
  // Form state
  late String _selectedCategory;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  late bool _isFeatured;
  bool _isSubmitting = false;
  
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
    
    // Initialize controllers with existing data
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _locationDetailController = TextEditingController(text: widget.event.locationDetail);
    _capacityController = TextEditingController(text: widget.event.capacity.toString());
    
    // Initialize state - validate category exists in list
    final categoryExists = _categories.any((cat) => cat['value'] == widget.event.category);
    _selectedCategory = categoryExists ? widget.event.category : 'academic';
    _isFeatured = widget.event.isFeatured;
    
    // Parse start date/time
    _startDate = widget.event.startAt;
    _startTime = TimeOfDay.fromDateTime(widget.event.startAt);
    
    // Parse end date/time if exists
    if (widget.event.endAt != null) {
      _endDate = widget.event.endAt;
      _endTime = TimeOfDay.fromDateTime(widget.event.endAt!);
    }
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
  
  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context, {required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
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
        'is_featured': _isFeatured,
      };
      
      // Optional fields
      if (_locationDetailController.text.isNotEmpty) {
        eventData['location_detail'] = _locationDetailController.text.trim();
      }
      
      // Update event via API
      final updatedEvent = await _repository.updateEvent(widget.event.id, eventData);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cập nhật sự kiện "${updatedEvent.title}" thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back
      Navigator.pop(context, true); // Return true to indicate success
      
    } catch (e) {
      debugPrint('Error updating event: $e');
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
      appBar: AppBar(
        title: const Text('Chỉnh sửa sự kiện'),
        elevation: 0,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tên sự kiện *',
                hintText: 'Nhập tên sự kiện',
                prefixIcon: Icon(Icons.event),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên sự kiện';
                }
                return null;
              },
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả *',
                hintText: 'Mô tả chi tiết về sự kiện',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mô tả';
                }
                return null;
              },
              maxLength: 2000,
            ),
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Thể loại *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
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
            
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Địa điểm *',
                hintText: 'Ví dụ: Hội trường A',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập địa điểm';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Location Detail
            TextFormField(
              controller: _locationDetailController,
              decoration: const InputDecoration(
                labelText: 'Chi tiết địa điểm',
                hintText: 'Mô tả chi tiết cách đến địa điểm',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Start Date & Time
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _selectDate(context, isStart: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày bắt đầu *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDateTime(_startDate, null)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, isStart: true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Giờ *',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_startTime?.format(context) ?? '--:--'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // End Date & Time
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () => _selectDate(context, isStart: false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày kết thúc *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_formatDateTime(_endDate, null)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectTime(context, isStart: false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Giờ *',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_endTime?.format(context) ?? '--:--'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Capacity
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: 'Sức chứa *',
                hintText: 'Số lượng người tham gia tối đa',
                prefixIcon: Icon(Icons.people),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập sức chứa';
                }
                final capacity = int.tryParse(value);
                if (capacity == null || capacity <= 0) {
                  return 'Sức chứa phải là số dương';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Is Featured switch
            SwitchListTile(
              title: const Text('Sự kiện nổi bật'),
              subtitle: const Text('Hiển thị sự kiện này ở trang chủ'),
              value: _isFeatured,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value;
                });
              },
              activeColor: Colors.indigo,
            ),
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Cập nhật sự kiện',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
