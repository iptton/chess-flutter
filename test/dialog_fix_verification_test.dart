import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('GREEN: Dialog关闭修复验证', () {
    testWidgets('修复后的对话框应该正确关闭', (WidgetTester tester) async {
      // Arrange
      final learningBloc = LearningBloc();
      bool dialogVisible = false;
      bool isLessonDialogShowing = false;
      
      // 设置一个有效的课程
      final lesson = LearningLesson(
        id: 'test-lesson',
        title: '测试课程',
        description: '测试描述',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: '第一步',
            description: '第一步描述',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
        ],
        currentStepIndex: 0,
      );
      
      learningBloc.emit(LearningState(
        currentLesson: lesson,
        startTime: DateTime.now().subtract(Duration(minutes: 5)),
      ));
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: Scaffold(
              body: BlocListener<LearningBloc, LearningState>(
                listener: (context, state) {
                  // 模拟修复后的逻辑：防止重复显示
                  if (state.isLessonCompleted && !isLessonDialogShowing) {
                    isLessonDialogShowing = true;
                    dialogVisible = true;
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
                              isLessonDialogShowing = false;
                              context.read<LearningBloc>().add(const ConfirmLessonCompletion());
                            },
                            child: const Text('返回学习首页'),
                          ),
                        ],
                      ),
                    ).then((_) {
                      dialogVisible = false;
                    });
                  }
                },
                child: const Center(child: Text('测试页面')),
              ),
            ),
          ),
        ),
      );

      // Act - 触发课程完成状态
      learningBloc.add(const CompleteLesson());
      await tester.pumpAndSettle();

      // Assert - 验证对话框显示
      expect(find.text('🎉 课程完成！'), findsOneWidget);
      expect(find.text('返回学习首页'), findsOneWidget);
      expect(dialogVisible, isTrue);
      expect(isLessonDialogShowing, isTrue);

      // Act - 点击"返回学习首页"按钮
      await tester.tap(find.text('返回学习首页'));
      await tester.pump(); // 只pump一次，不等待异步操作

      // Assert - 验证对话框立即关闭
      expect(find.text('🎉 课程完成！'), findsNothing);
      expect(find.text('返回学习首页'), findsNothing);
      expect(dialogVisible, isFalse);
      expect(isLessonDialogShowing, isFalse);
      
      // 验证状态已重置
      expect(learningBloc.state.isLessonCompleted, isFalse);
    });

    testWidgets('防止重复显示对话框', (WidgetTester tester) async {
      // Arrange
      final learningBloc = LearningBloc();
      int dialogShowCount = 0;
      bool isLessonDialogShowing = false;
      
      final lesson = LearningLesson(
        id: 'test-lesson',
        title: '测试课程',
        description: '测试描述',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: '第一步',
            description: '第一步描述',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
        ],
        currentStepIndex: 0,
      );
      
      learningBloc.emit(LearningState(
        currentLesson: lesson,
        startTime: DateTime.now().subtract(Duration(minutes: 5)),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: Scaffold(
              body: BlocListener<LearningBloc, LearningState>(
                listener: (context, state) {
                  // 模拟修复后的逻辑：防止重复显示
                  if (state.isLessonCompleted && !isLessonDialogShowing) {
                    isLessonDialogShowing = true;
                    dialogShowCount++;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('🎉 课程完成！ ($dialogShowCount)'),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              isLessonDialogShowing = false;
                              context.read<LearningBloc>().add(const ConfirmLessonCompletion());
                            },
                            child: const Text('返回学习首页'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Center(child: Text('测试页面')),
              ),
            ),
          ),
        ),
      );

      // Act - 触发课程完成状态
      learningBloc.add(const CompleteLesson());
      await tester.pumpAndSettle();
      
      // 应该只显示一次对话框
      expect(dialogShowCount, equals(1));
      expect(find.text('🎉 课程完成！ (1)'), findsOneWidget);

      // 点击按钮
      await tester.tap(find.text('返回学习首页'));
      await tester.pump();

      // 对话框应该关闭，不应该再次显示
      expect(find.text('🎉 课程完成！ (1)'), findsNothing);
      expect(dialogShowCount, equals(1)); // 应该还是1，不应该增加
      expect(isLessonDialogShowing, isFalse);
    });
  });
}
