import 'package:event_connect/features/event_creation/presentation/screens/create_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CreateEventScreen shows validation errors when fields are empty', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateEventScreen(clubId: '1')));

    await tester.tap(find.text('Tạo'));
    await tester.pump();

    expect(find.text('Vui lòng nhập tên sự kiện'), findsOneWidget);
    expect(find.text('Vui lòng nhập mô tả'), findsOneWidget);
    expect(find.text('Vui lòng nhập địa điểm'), findsOneWidget);
    expect(find.text('Vui lòng nhập sức chứa'), findsOneWidget);
    expect(find.text('Vui lòng điền đầy đủ thông tin'), findsOneWidget);
  });

  testWidgets('CreateEventScreen requires start time before submit', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreateEventScreen(clubId: '1')));

    await tester.enterText(find.widgetWithText(TextFormField, 'Tên sự kiện *'), 'Hackathon 2025');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mô tả *'), 'Cuộc thi lập trình kéo dài 48 giờ với nhiều đội tham gia.');
    await tester.enterText(find.widgetWithText(TextFormField, 'Địa điểm *'), 'Phòng A1');
    await tester.enterText(find.widgetWithText(TextFormField, 'Sức chứa *'), '50');

    await tester.tap(find.text('Tạo'));
    await tester.pump();

    expect(find.text('Vui lòng chọn thời gian bắt đầu'), findsOneWidget);
    expect(find.text('Vui lòng nhập tên sự kiện'), findsNothing);
    expect(find.text('Vui lòng nhập mô tả'), findsNothing);
    expect(find.text('Vui lòng nhập địa điểm'), findsNothing);
    expect(find.text('Vui lòng nhập sức chứa'), findsNothing);
  });
}
