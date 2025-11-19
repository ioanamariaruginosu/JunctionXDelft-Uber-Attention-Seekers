import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uber_copilot/main.dart';

void main() {
  testWidgets('App launches and shows auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(const UberCopilotApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
