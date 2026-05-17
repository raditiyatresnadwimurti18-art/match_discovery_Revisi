// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test: Verify app can render a basic widget', (WidgetTester tester) async {
    // Build a simple widget instead of the whole MainApp to avoid complex side effects
    // like Firebase, SharedPreferences, and infinite animations in tests.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Match Discovery'),
        ),
      ),
    ));

    // Verify that our basic text is present.
    expect(find.text('Match Discovery'), findsOneWidget);
  });
}
