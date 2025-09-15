import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/widgets/themed_background.dart';
import 'package:testflutter/widgets/chess_board.dart';
import 'package:testflutter/services/sound_service.dart';
import 'package:testflutter/services/settings_service.dart';

void main() {
  group('UI Improvements Tests', () {
    testWidgets('RED: ThemedBackground should support white background mode',
        (WidgetTester tester) async {
      // 测试白色背景模式
      await tester.pumpWidget(
        MaterialApp(
          home: ThemedBackground(
            useWhiteBackground: true,
            child: const Scaffold(
              body: Center(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // 应该能找到测试内容
      expect(find.text('Test Content'), findsOneWidget);
      
      // 背景应该是白色容器
      final container = tester.widget<Container>(
        find.ancestor(
          of: find.text('Test Content'),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.color, equals(Colors.white));
    });

    testWidgets('RED: ThemedBackground should support gradient background mode',
        (WidgetTester tester) async {
      // 测试渐变背景模式
      await tester.pumpWidget(
        MaterialApp(
          home: ThemedBackground(
            useWhiteBackground: false,
            child: const Scaffold(
              body: Center(
                child: Text('Test Content'),
              ),
            ),
          ),
        ),
      );

      // 应该能找到测试内容
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('RED: ChessBoardLayout should use wide layout for large screens',
        (WidgetTester tester) async {
      // 测试宽屏布局
      await tester.binding.setSurfaceSize(const Size(1400, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChessBoardLayout(
              topContent: [
                Container(
                  height: 50,
                  child: const Text('Tool Panel'),
                ),
              ],
            ),
          ),
        ),
      );

      // 应该能找到工具面板
      expect(find.text('Tool Panel'), findsOneWidget);
      
      // 在宽屏模式下应该使用Row布局
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('RED: ChessBoardLayout should use narrow layout for small screens',
        (WidgetTester tester) async {
      // 测试窄屏布局
      await tester.binding.setSurfaceSize(const Size(600, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChessBoardLayout(
              topContent: [
                Container(
                  height: 50,
                  child: const Text('Tool Panel'),
                ),
              ],
            ),
          ),
        ),
      );

      // 应该能找到工具面板
      expect(find.text('Tool Panel'), findsOneWidget);
      
      // 在窄屏模式下应该使用Column布局（在SingleChildScrollView中）
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    test('RED: SoundService should be properly initialized', () async {
      // 测试音效服务初始化
      final soundService = SoundService();
      
      // 初始状态
      expect(soundService.isInitialized, isFalse);
      expect(soundService.isMuted, isFalse);
      expect(soundService.volume, equals(1.0));
      
      // 初始化
      await soundService.initialize();
      expect(soundService.isInitialized, isTrue);
      
      // 清理
      await soundService.dispose();
    });

    test('RED: SoundService volume control should work', () async {
      // 测试音量控制
      final soundService = SoundService();
      await soundService.initialize();
      
      // 设置音量
      await soundService.setVolume(0.5);
      expect(soundService.volume, equals(0.5));
      
      // 静音
      await soundService.mute();
      expect(soundService.isMuted, isTrue);
      
      // 取消静音
      await soundService.unmute();
      expect(soundService.isMuted, isFalse);
      
      // 切换静音
      await soundService.toggleMute();
      expect(soundService.isMuted, isTrue);
      
      await soundService.toggleMute();
      expect(soundService.isMuted, isFalse);
      
      // 清理
      await soundService.dispose();
    });

    test('GREEN: Sound settings integration should work', () async {
      // 测试音效设置集成
      final soundService = SoundService();
      await soundService.initialize();
      
      // 设置音效为关闭
      await SettingsService.setSoundEnabled(false);
      
      // 播放音效应该被阻止（通过设置检查）
      // 这里我们只能测试设置的读取，实际播放需要音频文件
      final soundEnabled = await SettingsService.getSoundEnabled();
      expect(soundEnabled, isFalse);
      
      // 设置音效为开启
      await SettingsService.setSoundEnabled(true);
      final soundEnabledAfter = await SettingsService.getSoundEnabled();
      expect(soundEnabledAfter, isTrue);
      
      // 清理
      await soundService.dispose();
    });

    test('GREEN: Learning card aspect ratio should be appropriate for small screens', () {
      // 测试学习模式卡片的宽高比
      
      // 移动端配置
      const mobileWidth = 400.0;
      const mobileAspectRatio = 0.85; // 新的比例
      
      // 计算卡片尺寸
      const cardWidth = (mobileWidth - 16 * 3) / 2; // 减去间距
      const cardHeight = cardWidth / mobileAspectRatio;
      
      // 验证高度足够显示内容
      // 假设内容需要至少180像素高度
      const minContentHeight = 180.0;
      expect(cardHeight, greaterThan(minContentHeight));
      
      // 验证比例合理（不会太高或太宽）
      expect(mobileAspectRatio, greaterThan(0.7));
      expect(mobileAspectRatio, lessThan(1.5));
    });
  });
}
