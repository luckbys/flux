// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bkcrm_flutter/main.dart';

void main() {
  testWidgets('BKCRM app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BKCRMApp());

    // Verify that the splash screen shows the app name
    expect(find.text('BKCRM'), findsOneWidget);

    // Verify support agent icon is present
    expect(find.byIcon(Icons.support_agent), findsOneWidget);
  });
}
