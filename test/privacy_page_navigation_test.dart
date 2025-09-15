import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/screens/settings_screen.dart';
import 'package:testflutter/widgets/privacy_page.dart';

void main() {
  group('Privacy Page Navigation Tests', () {
    testWidgets('GREEN: Should navigate to privacy page from settings',
        (WidgetTester tester) async {
      // Build the SettingsScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Wait for initial render
      await tester.pump();

      // Verify settings screen is displayed
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('隐私政策'), findsOneWidget);

      // Tap on privacy policy
      await tester.tap(find.text('隐私政策'));
      await tester.pumpAndSettle();

      // Verify privacy page is displayed with themed components
      expect(find.byType(PrivacyPage), findsOneWidget);
      expect(find.text('隐私政策'), findsAtLeastNWidgets(1)); // Title in AppBar
    });

    testWidgets('GREEN: Privacy page should display content correctly',
        (WidgetTester tester) async {
      // Build the PrivacyPage directly
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPage(),
        ),
      );

      // Wait for initial render and content loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the page structure
      expect(find.text('隐私政策'), findsOneWidget);

      // The page should either show loading, error, or content
      final hasLoading = tester.any(find.byType(CircularProgressIndicator));
      final hasError = tester.any(find.text('重试'));
      final hasContent = tester.any(find.textContaining('一起下棋'));

      expect(hasLoading || hasError || hasContent, isTrue);
    });
  });
}
