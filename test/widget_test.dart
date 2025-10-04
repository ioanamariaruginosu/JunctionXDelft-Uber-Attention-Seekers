import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uber_copilot/main.dart';

void main() {
  testWidgets('App launches and shows auth screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const UberCopilotApp());

    // Verify that the app launches
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}