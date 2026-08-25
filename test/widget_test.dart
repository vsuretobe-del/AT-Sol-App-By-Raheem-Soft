import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atsol_mobile/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();
    expect(find.text('AT Sol'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
