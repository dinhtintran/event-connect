import 'package:flutter/material.dart';
import 'package:event_connect/features/event_management/domain/models/event.dart';

class ApprovalDialog extends StatefulWidget {
  final Event event;
  final Function(bool locationVerified, bool timeVerified, bool descriptionVerified, String note) onApprove;

  const ApprovalDialog({
    super.key,
    required this.event,
    required this.onApprove,
  });

  @override
  State<ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<ApprovalDialog> {
  bool _locationVerified = false;
  bool _timeVerified = false;
  bool _descriptionVerified = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Phê duyệt sự kiện',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Checkboxes
            CheckboxListTile(
              value: _locationVerified,
              onChanged: (value) {
                setState(() {
                  _locationVerified = value ?? false;
                });
              },
              title: const Text(
                'Địa điểm đã xác minh',
                style: TextStyle(fontSize: 15),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF6366F1),
            ),
            CheckboxListTile(
              value: _timeVerified,
              onChanged: (value) {
                setState(() {
                  _timeVerified = value ?? false;
                });
              },
              title: const Text(
                'Thời gian đã xác minh',
                style: TextStyle(fontSize: 15),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF6366F1),
            ),
            CheckboxListTile(
              value: _descriptionVerified,
              onChanged: (value) {
                setState(() {
                  _descriptionVerified = value ?? false;
                });
              },
              title: const Text(
                'Mô tả đã xác minh',
                style: TextStyle(fontSize: 15),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF6366F1),
            ),
            const SizedBox(height: 16),
            
            // Note Input
            const Text(
              'Ghi chú ngắn sách (tùy chọn)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú liên quan đến ngắn sách sự kiện...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    widget.onApprove(
                      _locationVerified,
                      _timeVerified,
                      _descriptionVerified,
                      _noteController.text,
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Phê duyệt',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

