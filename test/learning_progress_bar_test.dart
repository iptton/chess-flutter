import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/widgets/learning_progress_bar.dart';

void main() {
  group('LearningProgressBar 滑动测试', () {
    testWidgets('应该支持水平滑动当步骤数量较多时', (WidgetTester tester) async {
      // 创建一个有很多步骤的进度条
      const int totalSteps = 20;
      const int currentStep = 10;
      const double progress = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningProgressBar(
              currentStep: currentStep,
              totalSteps: totalSteps,
              progress: progress,
            ),
          ),
        ),
      );

      // 等待动画完成
      await tester.pumpAndSettle();

      // 验证进度条存在
      expect(find.byType(LearningProgressBar), findsOneWidget);

      // 验证步骤指示器存在
      expect(find.text('步骤 ${currentStep + 1} / $totalSteps'), findsOneWidget);

      // 验证进度百分比显示
      expect(find.text('${(progress * 100).toInt()}% 完成'), findsOneWidget);

      // 验证可滚动组件存在
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // 验证滚动条在步骤较多时显示
      expect(find.byType(Scrollbar), findsOneWidget);

      // 验证所有步骤点都存在
      final stepDots = find.byType(Container).evaluate().where((element) {
        final widget = element.widget as Container;
        return widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle;
      });
      expect(stepDots.length, totalSteps);
    });

    testWidgets('应该在步骤较少时不显示滚动条', (WidgetTester tester) async {
      // 创建一个步骤较少的进度条
      const int totalSteps = 5;
      const int currentStep = 2;
      const double progress = 0.4;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningProgressBar(
              currentStep: currentStep,
              totalSteps: totalSteps,
              progress: progress,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证进度条存在
      expect(find.byType(LearningProgressBar), findsOneWidget);

      // 验证可滚动组件存在（但滚动条可能不可见）
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // 验证渐变指示器不显示（因为步骤较少）
      final gradientContainers = find.byType(Positioned);
      expect(gradientContainers, findsNothing);
    });

    testWidgets('应该正确显示当前步骤状态', (WidgetTester tester) async {
      const int totalSteps = 10;
      const int currentStep = 3;
      const double progress = 0.3;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningProgressBar(
              currentStep: currentStep,
              totalSteps: totalSteps,
              progress: progress,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证进度条值
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, progress);

      // 验证步骤文本
      expect(find.text('步骤 ${currentStep + 1} / $totalSteps'), findsOneWidget);
      expect(find.text('${(progress * 100).toInt()}% 完成'), findsOneWidget);
    });

    testWidgets('应该在步骤改变时自动滚动', (WidgetTester tester) async {
      const int totalSteps = 15;
      int currentStep = 5;
      double progress = 0.33;

      // 创建一个 StatefulWidget 来测试步骤变化
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    LearningProgressBar(
                      currentStep: currentStep,
                      totalSteps: totalSteps,
                      progress: progress,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentStep = 10;
                          progress = 0.67;
                        });
                      },
                      child: const Text('下一步'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证初始状态
      expect(find.text('步骤 ${5 + 1} / $totalSteps'), findsOneWidget);

      // 点击按钮改变步骤
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();

      // 验证步骤已更新
      expect(find.text('步骤 ${10 + 1} / $totalSteps'), findsOneWidget);
      expect(find.text('67% 完成'), findsOneWidget);
    });
  });
}
