import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/widgets/themed_background.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Theme Implementation Tests', () {
    test('GREEN: AppTheme should have consistent colors', () {
      // 验证主题常量的定义
      expect(AppTheme.primaryColor.value, equals(0xFF667EEA));
      expect(AppTheme.secondaryColor.value, equals(0xFF764BA2));
      expect(AppTheme.backgroundColor.value, equals(0xFFF7FAFC));
      expect(AppTheme.surfaceColor.value, equals(0xFFFFFFFF));
      expect(AppTheme.primaryTextColor.value, equals(0xFF1A202C));
      expect(AppTheme.secondaryTextColor.value, equals(0xFF4A5568));
      expect(AppTheme.onPrimaryTextColor.value, equals(0xFFFFFFFF));
    });

    test('GREEN: AppTheme should have gradient colors', () {
      // 验证渐变色定义
      expect(AppTheme.gradientColors.length, equals(2));
      expect(AppTheme.gradientColors[0], equals(AppTheme.primaryColor));
      expect(AppTheme.gradientColors[1], equals(AppTheme.secondaryColor));
    });

    test('GREEN: AppTheme should have primary gradient', () {
      // 验证主渐变定义
      expect(AppTheme.primaryGradient.colors.length, equals(2));
      expect(AppTheme.primaryGradient.colors[0], equals(AppTheme.primaryColor));
      expect(AppTheme.primaryGradient.colors[1], equals(AppTheme.secondaryColor));
      expect(AppTheme.primaryGradient.begin, equals(Alignment.topLeft));
      expect(AppTheme.primaryGradient.end, equals(Alignment.bottomRight));
    });

    testWidgets('GREEN: ThemedBackground should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ThemedBackground(
            child: Container(
              child: const Text('Test'),
            ),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(ThemedBackground), findsOneWidget);
    });

    testWidgets('GREEN: ThemedAppBar should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: const ThemedAppBar(title: 'Test Title'),
            body: Container(),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byType(ThemedAppBar), findsOneWidget);
    });

    testWidgets('GREEN: ThemedCard should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemedCard(
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(ThemedCard), findsOneWidget);
    });

    testWidgets('GREEN: ThemedButton should render correctly', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemedButton(
              text: 'Test Button',
              onPressed: () {
                buttonPressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ThemedButton), findsOneWidget);

      // 测试按钮点击
      await tester.tap(find.byType(ThemedButton));
      await tester.pump();

      expect(buttonPressed, isTrue);
    });

    testWidgets('GREEN: ThemedButton with icon should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemedButton(
              text: 'Button with Icon',
              icon: Icons.star,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Button with Icon'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('GREEN: Secondary ThemedButton should render correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemedButton(
              text: 'Secondary Button',
              isSecondary: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Secondary Button'), findsOneWidget);
    });

    testWidgets('GREEN: Animated ThemedBackground should work', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ThemedBackground(
            animated: true,
            animationDuration: const Duration(milliseconds: 100),
            child: const Text('Animated Background'),
          ),
        ),
      );

      expect(find.text('Animated Background'), findsOneWidget);
      
      // 让动画运行一段时间
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    });
  });
}
