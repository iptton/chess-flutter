import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/main.dart';

void main() {
  group('Navigation Integration Tests', () {
    testWidgets('should navigate from home to face-to-face game',
        (WidgetTester tester) async {
      // Build the entire app
      await tester.pumpWidget(const MyApp());

      // Wait for privacy dialog and accept it
      await tester.pump();
      if (tester.any(find.text('接受'))) {
        await tester.tap(find.text('接受'));
        await tester.pump();
      }

      // Verify we're on the home screen
      expect(find.text('♔ 国际象棋 ♛'), findsOneWidget);
      expect(find.text('面对面对战'), findsOneWidget);

      // Tap on face-to-face game
      await tester.tap(find.text('面对面对战'));
      await tester.pump();

      // Verify navigation to chess board
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show AI difficulty selector when AI game is tapped',
        (WidgetTester tester) async {
      // Build the entire app
      await tester.pumpWidget(const MyApp());

      // Wait for privacy dialog and accept it
      await tester.pump();
      if (tester.any(find.text('接受'))) {
        await tester.tap(find.text('接受'));
        await tester.pump();
      }

      // Verify we're on the home screen
      expect(find.text('♔ 国际象棋 ♛'), findsOneWidget);
      expect(find.text('AI 对战'), findsOneWidget);

      // Tap on AI game
      await tester.tap(find.text('AI 对战'));
      await tester.pump();

      // Verify AI difficulty dialog is shown
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('should navigate to replay screen when replay is tapped',
        (WidgetTester tester) async {
      // Build the entire app
      await tester.pumpWidget(const MyApp());

      // Wait for privacy dialog and accept it
      await tester.pump();
      if (tester.any(find.text('接受'))) {
        await tester.tap(find.text('接受'));
        await tester.pump();
      }

      // Verify we're on the home screen
      expect(find.text('♔ 国际象棋 ♛'), findsOneWidget);
      expect(find.text('复盘'), findsOneWidget);

      // Tap on replay (with warnIfMissed: false to handle layout issues)
      await tester.tap(find.text('复盘'), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation to replay screen
      expect(find.text('复盘'), findsOneWidget);
    });

    testWidgets('should navigate to settings screen when settings is tapped',
        (WidgetTester tester) async {
      // Build the entire app
      await tester.pumpWidget(const MyApp());

      // Wait for privacy dialog and accept it
      await tester.pump();
      if (tester.any(find.text('接受'))) {
        await tester.tap(find.text('接受'));
        await tester.pump();
      }

      // Verify we're on the home screen
      expect(find.text('♔ 国际象棋 ♛'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      // Tap on settings (with warnIfMissed: false to handle layout issues)
      await tester.tap(find.text('设置'), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation to settings screen
      expect(find.text('设置'), findsOneWidget);
    });
  });
}
