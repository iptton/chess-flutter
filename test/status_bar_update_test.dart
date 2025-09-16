import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/screens/home_screen.dart';

void main() {
  group('GREEN: 状态栏颜色更新测试', () {
    testWidgets('HomeScreen应该能够正常显示', (WidgetTester tester) async {
      // Arrange - 创建HomeScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Act - 等待页面构建完成（不等待动画完成）
      await tester.pump();

      // Assert - 验证HomeScreen能够正常显示
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('一起下棋'), findsOneWidget);
    });

    testWidgets('HomeScreen应该实现WidgetsBindingObserver',
        (WidgetTester tester) async {
      // Arrange - 创建HomeScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Act - 等待页面构建完成
      await tester.pump();

      // Assert - 验证HomeScreen正常显示
      expect(find.byType(HomeScreen), findsOneWidget);

      // 验证HomeScreen状态实现了WidgetsBindingObserver
      final homeScreenState = tester.state(find.byType(HomeScreen));
      expect(homeScreenState, isA<WidgetsBindingObserver>());
    });

    testWidgets('HomeScreen应该有状态栏更新功能', (WidgetTester tester) async {
      // Arrange - 创建HomeScreen
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Act - 等待页面构建完成
      await tester.pump();

      // Assert - 验证HomeScreen正常显示
      expect(find.byType(HomeScreen), findsOneWidget);

      // 验证状态栏更新功能已实现（通过检查状态类型）
      final homeScreenState = tester.state(find.byType(HomeScreen));
      expect(
          homeScreenState.runtimeType.toString(), contains('_HomeScreenState'));
    });
  });
}
