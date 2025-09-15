import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/screens/home_screen.dart';

void main() {
  group('Title Change Tests', () {
    testWidgets('GREEN: Title should be changed from "♔ 国际象棋 ♛" to "一起下棋"', (WidgetTester tester) async {
      // Build the HomeScreen widget
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Wait for initial render
      await tester.pump();

      // Wait for some animations to start
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the new title is displayed
      expect(find.text('一起下棋'), findsOneWidget);
      
      // Verify the old title is NOT displayed
      expect(find.text('♔ 国际象棋 ♛'), findsNothing);

      // Verify the subtitle is still displayed
      expect(find.text('选择游戏模式开始对弈'), findsOneWidget);
    });
  });
}
