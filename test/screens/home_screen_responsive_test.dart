import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/screens/home_screen.dart';

void main() {
  group('HomeScreen 响应式布局测试', () {
    testWidgets('小屏幕时应该去掉背景渐变和立体效果', (WidgetTester tester) async {
      // Act - 构建HomeScreen with small screen size
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(600, 800)),
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // 等待初始渲染完成
      await tester.pump();

      // 手动推进时间来处理Future.delayed
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - 验证背景Container没有decoration
      final backgroundContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AnimatedBuilder),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(backgroundContainer.decoration, isNull);

      // Assert - 验证Card没有elevation
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(0));
      expect(card.shadowColor, isNull);
    });

    testWidgets('大屏幕时应该保持背景渐变和立体效果', (WidgetTester tester) async {
      // Act - 构建HomeScreen with large screen size
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // 等待初始渲染完成
      await tester.pump();

      // 手动推进时间来处理Future.delayed
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - 验证背景Container有decoration
      final backgroundContainer = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AnimatedBuilder),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(backgroundContainer.decoration, isNotNull);
      expect(backgroundContainer.decoration, isA<BoxDecoration>());

      // Assert - 验证Card有elevation
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(25));
      expect(card.shadowColor, isNotNull);
    });
  });
}
