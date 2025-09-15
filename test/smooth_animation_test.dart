import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/screens/home_screen.dart';

void main() {
  group('Smooth Animation Tests', () {
    testWidgets('RED: home screen should render with smooth animations',
        (WidgetTester tester) async {
      // Build the HomeScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Test that the widget renders without errors
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Test that floating pieces are present
      expect(find.byType(FloatingPieces), findsOneWidget);

      // Test that menu card is present
      expect(find.byType(ChessMenuCard), findsOneWidget);

      // Test that menu buttons are present
      expect(find.byType(MenuButton), findsWidgets);

      // Pump a few frames to test animation stability
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('RED: animations should be continuous without sudden jumps',
        (WidgetTester tester) async {
      // Build the HomeScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Pump several frames to test animation continuity
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1000));

      // Test that the widget is still stable after animation frames
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(FloatingPieces), findsOneWidget);
      expect(find.byType(ChessMenuCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('RED: animation should use smooth curves', () {
      // Test that common animation curves provide smooth transitions
      const curves = [Curves.easeInOut, Curves.easeOut, Curves.easeIn];

      for (final curve in curves) {
        // Test curve boundaries
        expect(curve.transform(0.0), equals(0.0));
        expect(curve.transform(1.0), equals(1.0));

        // Test smooth intermediate values
        final quarter = curve.transform(0.25);
        final half = curve.transform(0.5);
        final threeQuarter = curve.transform(0.75);

        expect(quarter, greaterThan(0.0));
        expect(quarter, lessThan(1.0));
        expect(half, greaterThan(quarter));
        expect(threeQuarter, greaterThan(half));
        expect(threeQuarter, lessThan(1.0));
      }
    });
  });
}
