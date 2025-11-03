// Step 1: basic info + pick image (works Web + Mobile)
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event_data.dart';
import 'create_event_step2_date_location.dart';

class CreateEventStep1Page extends StatefulWidget {
  final EventData? eventData;
  const CreateEventStep1Page({super.key, this.eventData});

  @override
  State<CreateEventStep1Page> createState() => _CreateEventStep1PageState();
}

class _CreateEventStep1PageState extends State<CreateEventStep1Page> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController shortDescController = TextEditingController();
  String? category;
  String? imagePath;
  Uint8List? webImageBytes;

  @override
  void initState() {
    super.initState();
    if (widget.eventData != null) {
      imagePath = widget.eventData!.imagePath;
      webImageBytes = widget.eventData!.imageBytes;
      titleController.text = widget.eventData!.title ?? '';
      shortDescController.text = widget.eventData!.shortDescription ?? '';
      category = widget.eventData!.category;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          webImageBytes = bytes;
          imagePath = pickedFile.name; // name only on web
        });
      } else {
        setState(() {
          imagePath = pickedFile.path;
          webImageBytes = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = webImageBytes != null
        ? Image.memory(webImageBytes!, fit: BoxFit.cover, width: double.infinity)
        : (imagePath != null && !kIsWeb)
        ? Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity)
        : const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 32),
          SizedBox(height: 8),
          Text('Chạm để thêm ảnh', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo sự kiện: Thông tin cơ bản'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bước 1 trên 4',
              style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.hardEdge,
              child: imageWidget,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Tiêu đề sự kiện',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: category,
            decoration: const InputDecoration(
              labelText: 'Hạng mục',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Công nghệ', child: Text('Công nghệ')),
              DropdownMenuItem(value: 'Giáo dục', child: Text('Giáo dục')),
              DropdownMenuItem(value: 'Giải trí', child: Text('Giải trí')),
            ],
            onChanged: (value) => setState(() => category = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: shortDescController,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Mô tả ngắn',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final event = EventData(
                  imagePath: imagePath,
                  imageBytes: webImageBytes,
                  title: titleController.text,
                  category: category,
                  shortDescription: shortDescController.text,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateEventStep2Page(eventData: event)),
                );
              },
              child: const Text('Tiếp theo', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          )
        ]),
      ),
    );
  }
}
