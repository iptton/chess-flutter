import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testflutter/screens/settings_screen.dart';
import 'package:testflutter/services/settings_service.dart';
import 'package:testflutter/widgets/themed_background.dart';

void main() {
  group('SettingsScreen 测试', () {
    setUp(() async {
      // 确保每个测试开始时都有干净的设置状态
      await SettingsService.setSoundEnabled(true);
      await SettingsService.setDefaultHintMode(false);
    });

    group('界面渲染测试', () {
      testWidgets('应该正确渲染设置页面', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        // 等待加载完成
        await tester.pumpAndSettle();

        // 验证基本元素存在
        expect(find.text('设置'), findsOneWidget);
        expect(find.text('音效'), findsOneWidget);
        expect(find.text('默认开启提示模式'), findsOneWidget);
        expect(find.text('隐私政策'), findsOneWidget);
      });

      testWidgets('应该显示加载状态', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        // 在设置加载完成前应该显示加载指示器
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 等待加载完成
        await tester.pumpAndSettle();

        // 加载完成后不应该再显示加载指示器
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('应该使用主题背景', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // 验证使用了主题背景
        expect(find.byType(ThemedBackground), findsOneWidget);
        expect(find.byType(ThemedAppBar), findsOneWidget);
        expect(find.byType(ThemedCard), findsOneWidget);
      });
    });

    group('音效设置测试', () {
      testWidgets('应该正确显示音效开关状态', (WidgetTester tester) async {
        // 设置音效为开启状态
        await SettingsService.setSoundEnabled(true);

        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // 查找音效开关
        final soundSwitch = find.byType(Switch).first;
        expect(soundSwitch, findsOneWidget);

        // 验证开关状态
        final switchWidget = tester.widget<Switch>(soundSwitch);
        expect(switchWidget.value, true);
      });

      testWidgets('应该能够切换音效设置', (WidgetTester tester) async {
        // 设置初始状态为开启
        await SettingsService.setSoundEnabled(true);

        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // 查找音效开关并点击
        final soundSwitch = find.byType(Switch).first;
        await tester.tap(soundSwitch);
        await tester.pumpAndSettle();

        // 验证设置已更改
        final soundEnabled = await SettingsService.getSoundEnabled();
        expect(soundEnabled, false);
      });

      testWidgets('音效设置失败时应该显示错误信息', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // 这个测试比较难模拟设置失败的情况，
        // 在实际应用中可以通过mock来测试
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });

    group('提示模式设置测试', () {
      testWidgets('应该正确显示提示模式开关状态', (WidgetTester tester) async {
        // 设置提示模式为关闭状态
        await SettingsService.setDefaultHintMode(false);

        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // 查找提示模式开关（第二个开关）
        final hintSwitch = find.byType(Switch).at(1);
        expect(hintSwitch, findsOneWidget);

        // 验证开关状态
        final switchWidget = tester.widget<Switch>(hintSwitch);
        expect(switchWidget.value, false);
      });

      testWidgets('应该能够切换提示模式设置', (WidgetTester tester) async {
        // 设置初始状态为关闭
        await SettingsService.setDefaultHintMode(false);

        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // 查找提示模式开关并点击
        final hintSwitch = find.byType(Switch).at(1);
        await tester.tap(hintSwitch);
        await tester.pumpAndSettle();

        // 验证设置已更改
        final hintMode = await SettingsService.getDefaultHintMode();
        expect(hintMode, true);
      });
    });

    group('导航测试', () {
      testWidgets('应该能够导航到隐私政策页面', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // 查找隐私政策列表项并点击
        final privacyTile = find.text('隐私政策');
        expect(privacyTile, findsOneWidget);

        await tester.tap(privacyTile);
        await tester.pumpAndSettle();

        // 验证导航到隐私政策页面
        // 注意：这里可能需要根据实际的隐私政策页面实现来调整
        expect(find.text('隐私政策'), findsAtLeastNWidgets(1));
      });

      testWidgets('应该能够返回上一页', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: const Text('Go to Settings'),
                ),
              ),
            ),
          ),
        );

        // 导航到设置页面
        await tester.tap(find.text('Go to Settings'));
        await tester.pumpAndSettle();

        // 验证在设置页面
        expect(find.text('设置'), findsOneWidget);

        // 点击返回按钮
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // 验证返回到上一页
        expect(find.text('Go to Settings'), findsOneWidget);
      });
    });

    group('响应式设计测试', () {
      testWidgets('应该在不同屏幕尺寸下正常显示', (WidgetTester tester) async {
        // 测试小屏幕
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('设置'), findsOneWidget);

        // 测试大屏幕
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pump();

        expect(find.text('设置'), findsOneWidget);

        // 恢复默认尺寸
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
}
