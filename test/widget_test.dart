import 'package:event_connect/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EventConnectApp builds initial screen', (tester) async {
    await tester.pumpWidget(const EventConnectApp());
    await tester.pumpAndSettle();

    // Basic smoke test: app renders a MaterialApp without throwing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
