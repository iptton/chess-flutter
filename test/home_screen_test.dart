import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/screens/home_screen.dart';

void main() {
  group('HomeScreen Tests', () {
    testWidgets('should display animated chess menu with all buttons',
        (WidgetTester tester) async {
      // Build the HomeScreen widget
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
        ),
      );

      // Wait for initial render
      await tester.pump();

      // Wait for some animations to start
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the title is displayed
      expect(find.text('一起下棋'), findsOneWidget);

      // Verify the subtitle is displayed
      expect(find.text('选择游戏模式开始对弈'), findsOneWidget);

      // Verify all menu buttons are displayed
      expect(find.text('面对面对战'), findsOneWidget);
      expect(find.text('AI 对战'), findsOneWidget);
      expect(find.text('复盘'), findsOneWidget);
      expect(find.text('学习模式'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      // Verify emojis are displayed
      expect(find.text('👥'), findsOneWidget);
      expect(find.text('🤖'), findsOneWidget);
      expect(find.text('📋'), findsOneWidget);
      expect(find.text('📚'), findsOneWidget);
      expect(find.text('⚙️'), findsOneWidget);

      // Verify floating pieces are present (multiple instances expected)
      expect(find.text('♔'), findsWidgets);
      expect(find.text('♛'), findsWidgets);
    });

    testWidgets('should show snackbar when learning mode is tapped',
        (WidgetTester tester) async {
      // Build the HomeScreen widget with larger screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
        ),
      );

      // Wait for initial render and some animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Tap on the learning mode button
      await tester.tap(find.text('学习模式'));
      await tester.pump();

      // Verify snackbar is shown
      expect(find.text('学习模式正在开发中'), findsOneWidget);

      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('should navigate to chess board when PvP is tapped',
        (WidgetTester tester) async {
      // Build the HomeScreen widget with larger screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
        ),
      );

      // Wait for initial render and some animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Tap on the PvP button
      await tester.tap(find.text('面对面对战'));
      await tester.pump();

      // Wait for navigation to complete
      await tester.pump(const Duration(milliseconds: 100));

      // Verify navigation occurred (we should see a loading indicator or chess board)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Reset screen size
      addTearDown(tester.view.reset);
    });

    testWidgets('should show AI difficulty dialog when AI is tapped',
        (WidgetTester tester) async {
      // Build the HomeScreen widget with larger screen size
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
        ),
      );

      // Wait for initial render and some animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Tap on the AI button
      await tester.tap(find.text('AI 对战'));
      await tester.pump();

      // Verify AI difficulty dialog is shown (look for any dialog content)
      expect(find.byType(Dialog), findsOneWidget);

      // Reset screen size
      addTearDown(tester.view.reset);
    });
  });
}
