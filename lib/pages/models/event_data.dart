import 'dart:typed_data';
import 'package:flutter/material.dart';

class EventData {
  String? imagePath;
  Uint8List? imageBytes; // for web preview
  String? title;
  String? category;
  String? shortDescription;
  String? detailDescription;
  DateTime? date;
  TimeOfDay? time;
  String? location;
  int? attendees;
  bool? isOpenToAll;
  bool? requiresApproval;
  bool? inviteOnly;
  DateTime? deadline;

  EventData({
    this.imagePath,
    this.imageBytes,
    this.title,
    this.category,
    this.shortDescription,
    this.detailDescription,
    this.date,
    this.time,
    this.location,
    this.attendees,
    this.isOpenToAll,
    this.requiresApproval,
    this.inviteOnly,
    this.deadline,
  });
}
