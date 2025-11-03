// Step 3: detail & registration settings
import 'package:flutter/material.dart';
import '../models/event_data.dart';
import 'create_event_step4_review.dart';

class CreateEventStep3Page extends StatefulWidget {
  final EventData eventData;
  const CreateEventStep3Page({super.key, required this.eventData});

  @override
  State<CreateEventStep3Page> createState() => _CreateEventStep3PageState();
}

class _CreateEventStep3PageState extends State<CreateEventStep3Page> {
  final TextEditingController detailController = TextEditingController();
  bool isOpenToAll = true;
  bool requiresApproval = false;
  bool inviteOnly = false;
  DateTime? deadline;

  @override
  void initState() {
    super.initState();
    detailController.text = widget.eventData.detailDescription ?? '';
    isOpenToAll = widget.eventData.isOpenToAll ?? true;
    requiresApproval = widget.eventData.requiresApproval ?? false;
    inviteOnly = widget.eventData.inviteOnly ?? false;
    deadline = widget.eventData.deadline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo sự kiện: Chi tiết'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bước 3 trên 4', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          const Text('Mô tả chi tiết sự kiện', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 6),
          TextField(
            controller: detailController,
            maxLines: 6,
            maxLength: 5000,
            decoration: const InputDecoration(
              hintText: 'Hãy mô tả chi tiết về sự kiện của bạn ở đây. Bao gồm lịch trình, diễn giả, hoạt động chính...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Cài đặt đăng ký', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          CheckboxListTile(
            title: const Text('Mở đăng ký cho tất cả'),
            value: isOpenToAll,
            onChanged: (val) => setState(() => isOpenToAll = val ?? false),
          ),
          CheckboxListTile(
            title: const Text('Yêu cầu duyệt trước'),
            value: requiresApproval,
            onChanged: (val) => setState(() => requiresApproval = val ?? false),
          ),
          CheckboxListTile(
            title: const Text('Chỉ dành cho khách mời'),
            value: inviteOnly,
            onChanged: (val) => setState(() => inviteOnly = val ?? false),
          ),
          const SizedBox(height: 16),
          TextField(
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: deadline ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => deadline = picked);
            },
            decoration: InputDecoration(
              labelText: 'Hạn chót đăng ký',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              hintText: deadline == null ? 'Chọn ngày' : '${deadline!.day}/${deadline!.month}/${deadline!.year}',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                widget.eventData.detailDescription = detailController.text;
                widget.eventData.isOpenToAll = isOpenToAll;
                widget.eventData.requiresApproval = requiresApproval;
                widget.eventData.inviteOnly = inviteOnly;
                widget.eventData.deadline = deadline;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateEventStep4Page(eventData: widget.eventData)),
                );
              },
              child: const Text('Tiếp theo', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}
