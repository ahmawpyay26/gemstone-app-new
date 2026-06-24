// Basic smoke test for the Gemstone Management app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gemstone_management/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const GemstoneManagementApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
