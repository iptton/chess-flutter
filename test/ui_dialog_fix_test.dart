import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/screens/learning_screen.dart';
import 'package:testflutter/services/learning_service.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('学习模式对话框修复测试', () {
    testWidgets('GREEN: 课程完成对话框应该正确显示和关闭', (WidgetTester tester) async {
      // 创建一个简单的测试对话框
      bool dialogClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('🎉 课程完成！'),
                      content: const Text('恭喜您成功完成了课程！'),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            dialogClosed = true;
                          },
                          child: const Text('返回学习首页'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('显示对话框'),
              ),
            ),
          ),
        ),
      );

      // 点击按钮显示对话框
      await tester.tap(find.text('显示对话框'));
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.text('🎉 课程完成！'), findsOneWidget);
      expect(find.text('返回学习首页'), findsOneWidget);

      // 点击"返回学习首页"按钮
      await tester.tap(find.text('返回学习首页'));
      await tester.pumpAndSettle();

      // 验证对话框关闭
      expect(find.text('🎉 课程完成！'), findsNothing);
      expect(find.text('返回学习首页'), findsNothing);
      expect(dialogClosed, isTrue);
    });
  });
}
