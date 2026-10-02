// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:neon_finance/main.dart';

void main() {
  testWidgets('App renders splash screen test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NeonFinanceApp());

    // Verify that SWISS DIGITAL BANKING renders on animated splash.
    expect(find.text('SWISS DIGITAL BANKING'), findsWidgets);

    // Complete timer and settle animations
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}

