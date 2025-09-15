import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('RED: Dialog关闭问题测试', () {
    testWidgets('课程完成对话框应该在点击"返回学习首页"后立即关闭', (WidgetTester tester) async {
      // Arrange
      final learningBloc = LearningBloc();
      bool dialogVisible = false;

      // 先设置一个有效的课程
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
                  if (state.isLessonCompleted && !dialogVisible) {
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
                              context
                                  .read<LearningBloc>()
                                  .add(const ConfirmLessonCompletion());
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

      // Act - 点击"返回学习首页"按钮
      await tester.tap(find.text('返回学习首页'));
      await tester.pumpAndSettle();

      // Assert - 验证对话框关闭
      expect(find.text('🎉 课程完成！'), findsNothing);
      expect(find.text('返回学习首页'), findsNothing);
      expect(dialogVisible, isFalse);

      // 验证状态已重置
      expect(learningBloc.state.isLessonCompleted, isFalse);
      expect(learningBloc.state.currentLesson, isNull);
    });

    testWidgets('对话框关闭后不应该需要第二次点击', (WidgetTester tester) async {
      // Arrange
      final learningBloc = LearningBloc();
      int dialogCloseCount = 0;

      // 先设置一个有效的课程
      final lesson = LearningLesson(
        id: 'test-lesson-2',
        title: '测试课程2',
        description: '测试描述2',
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
        startTime: DateTime.now().subtract(Duration(minutes: 3)),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: Scaffold(
              body: BlocListener<LearningBloc, LearningState>(
                listener: (context, state) {
                  if (state.isLessonCompleted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('🎉 课程完成！'),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              dialogCloseCount++;
                              context
                                  .read<LearningBloc>()
                                  .add(const ConfirmLessonCompletion());
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

      // Act - 触发课程完成并点击按钮
      learningBloc.add(const CompleteLesson());
      await tester.pumpAndSettle();

      await tester.tap(find.text('返回学习首页'));
      await tester.pumpAndSettle();

      // Assert - 应该只需要点击一次
      expect(dialogCloseCount, equals(1));
      expect(find.text('🎉 课程完成！'), findsNothing);
    });
  });
}
