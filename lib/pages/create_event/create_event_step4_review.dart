// Step 4: review & send (works Web + Mobile)
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/event_data.dart';

class CreateEventStep4Page extends StatelessWidget {
  final EventData eventData;
  const CreateEventStep4Page({super.key, required this.eventData});

  ImageProvider<Object> getImageProvider() {
    if (eventData.imageBytes != null) {
      return MemoryImage(eventData.imageBytes!);
    }
    if (kIsWeb && eventData.imagePath != null) {
      // If you uploaded the image to a server earlier, use its URL here.
      // For local picks on web we used imageBytes; so fallback to asset:
      return const AssetImage('assets/images/conference.jpg');
    }
    if (!kIsWeb && eventData.imagePath != null) {
      return FileImage(File(eventData.imagePath!));
    }
    return const AssetImage('assets/images/conference.jpg');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tạo sự kiện: Xem lại & Gửi'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image(image: getImageProvider(), height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text(eventData.title ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('${eventData.category ?? ''}  •  ${eventData.location ?? ''}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          const Text('Mô tả chi tiết', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Text(eventData.detailDescription ?? 'Không có mô tả'),
          const Spacer(),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu nháp sự kiện!')));
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu nháp'),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: upload event to server or Firestore here if needed
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi sự kiện thành công!')));
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text('Gửi sự kiện', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ]),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
