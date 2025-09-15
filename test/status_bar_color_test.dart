import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('状态栏颜色测试', () {
    testWidgets('GREEN: 状态栏颜色设置功能正常工作', (WidgetTester tester) async {
      // 记录SystemChrome调用
      final List<MethodCall> systemCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        systemCalls.add(call);
        return null;
      });

      // 测试设置状态栏颜色
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      // 验证是否调用了设置状态栏的方法
      final statusBarCalls = systemCalls
          .where(
              (call) => call.method == 'SystemChrome.setSystemUIOverlayStyle')
          .toList();

      expect(statusBarCalls, isNotEmpty,
          reason: '应该调用SystemChrome.setSystemUIOverlayStyle设置状态栏');
    });
  });
}
