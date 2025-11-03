import 'package:flutter/material.dart';

class ClubEventsPage extends StatelessWidget {
  const ClubEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sự kiện của CLB'),
      ),
      body: const Center(
        child: Text('Danh sách sự kiện của CLB (placeholder)'),
      ),
    );
  }
}
