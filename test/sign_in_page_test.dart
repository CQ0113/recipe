import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savora/core/theme/app_theme.dart';
import 'package:savora/features/auth/presentation/auth_gate.dart';

void main() {
  testWidgets(
    'sign-in page communicates the product value and primary action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SignInPage()),
      );

      expect(find.text('SAVORA'), findsOneWidget);
      expect(find.text('Your everyday\ncooking companion.'), findsOneWidget);
      expect(find.byKey(const Key('googleSignInButton')), findsOneWidget);
    },
  );
}
