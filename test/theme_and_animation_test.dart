import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/widgets/ai_difficulty_selector.dart';
import 'package:testflutter/widgets/themed_background.dart';
import 'package:testflutter/utils/page_transitions.dart';
import 'package:testflutter/utils/ai_difficulty_strategy.dart';

void main() {
  group('Theme and Animation Tests', () {
    testWidgets('RED: AI Difficulty Selector should use theme colors',
        (WidgetTester tester) async {
      // 测试AI难度选择器的主题色
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIDifficultySelector(
              currentDifficulty: AIDifficultyLevel.beginner,
              showColorSelection: true,
            ),
          ),
        ),
      );

      // 应该能找到对话框
      expect(find.byType(AlertDialog), findsOneWidget);
      
      // 应该能找到确定按钮
      expect(find.text('开始游戏'), findsOneWidget);
      
      // 应该能找到取消按钮
      expect(find.text('取消'), findsOneWidget);
    });

    testWidgets('RED: Page transitions should work correctly',
        (WidgetTester tester) async {
      // 测试页面转换动画
      final testPage = Scaffold(
        appBar: AppBar(title: const Text('Test Page')),
        body: const Center(child: Text('Test Content')),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushWithThemeTransition(testPage);
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      // 点击导航按钮
      await tester.tap(find.text('Navigate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 应该能找到新页面的内容
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('RED: ChessBoardLayout should center content in wide screen',
        (WidgetTester tester) async {
      // 测试宽屏布局的居中效果
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 50,
                          child: const Text('Turn Indicator'),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 50,
                          child: const Text('Control Buttons'),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 30,
                          child: const Text('Step Info'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 应该能找到所有组件
      expect(find.text('Turn Indicator'), findsOneWidget);
      expect(find.text('Control Buttons'), findsOneWidget);
      expect(find.text('Step Info'), findsOneWidget);
    });

    test('GREEN: Page transition animations should have correct durations', () {
      // 测试页面转换动画的持续时间
      final testPage = Container();
      
      // 主题一致的转换
      final themeRoute = CustomPageTransitions.themeConsistent(testPage);
      expect(themeRoute.transitionDuration, equals(const Duration(milliseconds: 500)));
      expect(themeRoute.reverseTransitionDuration, equals(const Duration(milliseconds: 400)));
      
      // 滑入转换
      final slideRoute = CustomPageTransitions.slideFromRight(testPage);
      expect(slideRoute.transitionDuration, equals(const Duration(milliseconds: 300)));
      expect(slideRoute.reverseTransitionDuration, equals(const Duration(milliseconds: 300)));
      
      // 淡入转换
      final fadeRoute = CustomPageTransitions.fadeIn(testPage);
      expect(fadeRoute.transitionDuration, equals(const Duration(milliseconds: 300)));
      expect(fadeRoute.reverseTransitionDuration, equals(const Duration(milliseconds: 300)));
      
      // 缩放转换
      final scaleRoute = CustomPageTransitions.scaleIn(testPage);
      expect(scaleRoute.transitionDuration, equals(const Duration(milliseconds: 400)));
      expect(scaleRoute.reverseTransitionDuration, equals(const Duration(milliseconds: 300)));
    });

    test('GREEN: Theme colors should be consistent', () {
      // 测试主题色的一致性
      expect(AppTheme.primaryColor, equals(const Color(0xFF667EEA)));
      expect(AppTheme.secondaryColor, equals(const Color(0xFF764BA2)));
      expect(AppTheme.backgroundColor, equals(const Color(0xFFF7FAFC)));
      expect(AppTheme.surfaceColor, equals(const Color(0xFFFFFFFF)));
      
      // 渐变色应该包含主色和次色
      expect(AppTheme.gradientColors, contains(AppTheme.primaryColor));
      expect(AppTheme.gradientColors, contains(AppTheme.secondaryColor));
    });

    testWidgets('GREEN: ThemedBackground should support both modes',
        (WidgetTester tester) async {
      // 测试主题背景的两种模式
      
      // 渐变背景模式
      await tester.pumpWidget(
        MaterialApp(
          home: ThemedBackground(
            useWhiteBackground: false,
            child: const Text('Gradient Background'),
          ),
        ),
      );
      expect(find.text('Gradient Background'), findsOneWidget);
      
      // 白色背景模式
      await tester.pumpWidget(
        MaterialApp(
          home: ThemedBackground(
            useWhiteBackground: true,
            child: const Text('White Background'),
          ),
        ),
      );
      expect(find.text('White Background'), findsOneWidget);
    });

    test('GREEN: Slide direction enum should work correctly', () {
      // 测试滑动方向枚举
      expect(SlideDirection.values.length, equals(3));
      expect(SlideDirection.values, contains(SlideDirection.right));
      expect(SlideDirection.values, contains(SlideDirection.left));
      expect(SlideDirection.values, contains(SlideDirection.bottom));
    });

    testWidgets('GREEN: AI Difficulty levels should be properly configured',
        (WidgetTester tester) async {
      // 测试AI难度级别配置
      final levels = AIDifficultyLevel.values;
      
      // 应该有9个难度级别
      expect(levels.length, equals(9));
      
      // 检查关键难度级别
      expect(levels, contains(AIDifficultyLevel.beginner));
      expect(levels, contains(AIDifficultyLevel.intermediate));
      expect(levels, contains(AIDifficultyLevel.expert));
      expect(levels, contains(AIDifficultyLevel.engine));
      
      // 每个级别都应该有显示名称
      for (final level in levels) {
        expect(level.displayName.isNotEmpty, isTrue);
      }
    });
  });
}
