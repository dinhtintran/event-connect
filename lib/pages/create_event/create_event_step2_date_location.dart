// Step 2: date, time, location, attendees
import 'package:flutter/material.dart';
import '../models/event_data.dart';
import 'create_event_step3_detail.dart';

class CreateEventStep2Page extends StatefulWidget {
  final EventData eventData;
  const CreateEventStep2Page({super.key, required this.eventData});

  @override
  State<CreateEventStep2Page> createState() => _CreateEventStep2PageState();
}

class _CreateEventStep2PageState extends State<CreateEventStep2Page> {
  DateTime? eventDate;
  TimeOfDay? eventTime;
  final TextEditingController locationController = TextEditingController();
  final TextEditingController attendeesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // preload if available
    eventDate = widget.eventData.date;
    eventTime = widget.eventData.time;
    locationController.text = widget.eventData.location ?? '';
    attendeesController.text = widget.eventData.attendees?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo sự kiện: Ngày & Địa điểm'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Bước 2 trên 4',
              style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),

          // date
          TextField(
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: eventDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => eventDate = picked);
            },
            decoration: InputDecoration(
              labelText: 'Ngày sự kiện',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
              hintText: eventDate == null ? 'Chọn ngày' : '${eventDate!.day}/${eventDate!.month}/${eventDate!.year}',
            ),
          ),
          const SizedBox(height: 16),

          // time
          TextField(
            readOnly: true,
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: eventTime ?? TimeOfDay.now());
              if (picked != null) setState(() => eventTime = picked);
            },
            decoration: InputDecoration(
              labelText: 'Thời gian sự kiện',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.access_time),
              hintText: eventTime == null ? 'Chọn giờ' : '${eventTime!.hour}:${eventTime!.minute.toString().padLeft(2,'0')}',
            ),
          ),
          const SizedBox(height: 16),

          // location
          TextField(
            controller: locationController,
            decoration: const InputDecoration(
              labelText: 'Địa điểm',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // attendees
          TextField(
            controller: attendeesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số lượng người tham dự',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.people_outline),
            ),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                // update eventData
                widget.eventData.date = eventDate;
                widget.eventData.time = eventTime;
                widget.eventData.location = locationController.text;
                widget.eventData.attendees = int.tryParse(attendeesController.text) ?? 0;

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateEventStep3Page(eventData: widget.eventData)),
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
