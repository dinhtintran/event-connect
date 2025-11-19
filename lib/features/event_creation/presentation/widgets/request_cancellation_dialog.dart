import 'package:flutter/material.dart';

/// Dialog để nhập thông tin yêu cầu hủy sự kiện
class RequestCancellationDialog extends StatefulWidget {
  final String eventTitle;

  const RequestCancellationDialog({
    super.key,
    required this.eventTitle,
  });

  @override
  State<RequestCancellationDialog> createState() => _RequestCancellationDialogState();
}

class _RequestCancellationDialogState extends State<RequestCancellationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _refundPolicyController = TextEditingController();
  final _alternativeActionController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    _refundPolicyController.dispose();
    _alternativeActionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Return data to caller
      Navigator.pop(context, {
        'reason': _reasonController.text.trim(),
        'refund_policy': _refundPolicyController.text.trim().isEmpty 
            ? null 
            : _refundPolicyController.text.trim(),
        'alternative_action': _alternativeActionController.text.trim().isEmpty 
            ? null 
            : _alternativeActionController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Yêu cầu hủy sự kiện',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Event title
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.eventTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Warning message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Yêu cầu hủy sẽ được gửi đến System Admin để xét duyệt. Vui lòng cung cấp lý do rõ ràng.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Reason field (required)
                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Lý do hủy *',
                    hintText: 'Vui lòng nêu rõ lý do cần hủy sự kiện...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'Tối thiểu 20 ký tự',
                    helperStyle: const TextStyle(fontSize: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập lý do hủy';
                    }
                    if (value.trim().length < 20) {
                      return 'Lý do phải có ít nhất 20 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Refund policy (optional)
                TextFormField(
                  controller: _refundPolicyController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Chính sách hoàn tiền (tùy chọn)',
                    hintText: 'Ví dụ: Hoàn 100% tiền vé cho người tham gia',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Alternative action (optional)
                TextFormField(
                  controller: _alternativeActionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Hành động thay thế (tùy chọn)',
                    hintText: 'Ví dụ: Hoãn sang tháng sau hoặc đổi địa điểm',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Hủy bỏ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Gửi yêu cầu',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
