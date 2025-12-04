import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:incanteen/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const IncanteenApp());

    // Verify that the landing page or auth wrapper loads
    // Note: This test may need to be updated based on actual authentication state
    await tester.pumpAndSettle();
    
    // Basic check that the app initializes without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
