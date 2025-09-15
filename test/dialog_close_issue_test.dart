import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('RED: Dialog关闭问题分析', () {
    testWidgets('验证ConfirmLessonCompletion事件是否正确处理状态', (WidgetTester tester) async {
      // Arrange
      final learningBloc = LearningBloc();
      
      // 设置课程完成状态
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
        isCompleted: true,
      );
      
      learningBloc.emit(LearningState(
        currentLesson: lesson,
        isLessonCompleted: true,
        startTime: DateTime.now().subtract(Duration(minutes: 5)),
      ));

      // Act - 触发ConfirmLessonCompletion事件
      learningBloc.add(const ConfirmLessonCompletion());
      
      // 等待状态更新，但不等待LoadAvailableLessons完成
      await tester.pump();

      // Assert - 验证isLessonCompleted被重置
      expect(learningBloc.state.isLessonCompleted, isFalse);
      expect(learningBloc.state.currentLesson, isNull);
    });

    testWidgets('模拟实际对话框关闭流程', (WidgetTester tester) async {
      // Arrange
      final learningBloc = LearningBloc();
      bool dialogClosed = false;
      
      // 设置课程完成状态
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
        isCompleted: true,
      );
      
      learningBloc.emit(LearningState(
        currentLesson: lesson,
        isLessonCompleted: true,
        startTime: DateTime.now().subtract(Duration(minutes: 5)),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: Scaffold(
              body: BlocListener<LearningBloc, LearningState>(
                listener: (context, state) {
                  // 模拟学习界面的对话框逻辑
                  if (state.isLessonCompleted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('🎉 课程完成！'),
                        content: const Text('恭喜您成功完成了课程！'),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              // 模拟实际的按钮点击逻辑
                              Navigator.of(dialogContext).pop();
                              context.read<LearningBloc>().add(const ConfirmLessonCompletion());
                            },
                            child: const Text('返回学习首页'),
                          ),
                        ],
                      ),
                    ).then((_) {
                      dialogClosed = true;
                    });
                  }
                },
                child: const Center(child: Text('测试页面')),
              ),
            ),
          ),
        ),
      );

      // 初始状态应该显示对话框
      await tester.pump();
      expect(find.text('🎉 课程完成！'), findsOneWidget);
      expect(find.text('返回学习首页'), findsOneWidget);

      // Act - 点击"返回学习首页"按钮
      await tester.tap(find.text('返回学习首页'));
      
      // 只pump一次，不等待异步操作完成
      await tester.pump();

      // Assert - 验证对话框立即关闭
      expect(find.text('🎉 课程完成！'), findsNothing);
      expect(find.text('返回学习首页'), findsNothing);
      expect(dialogClosed, isTrue);
      
      // 验证状态已重置
      expect(learningBloc.state.isLessonCompleted, isFalse);
    });

    testWidgets('检查是否存在状态重复触发问题', (WidgetTester tester) async {
      // Arrange
      final learningBloc = LearningBloc();
      int dialogShowCount = 0;
      
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
        isCompleted: true,
      );
      
      learningBloc.emit(LearningState(
        currentLesson: lesson,
        isLessonCompleted: true,
        startTime: DateTime.now().subtract(Duration(minutes: 5)),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: Scaffold(
              body: BlocListener<LearningBloc, LearningState>(
                listener: (context, state) {
                  if (state.isLessonCompleted) {
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

      await tester.pump();
      
      // 应该只显示一次对话框
      expect(dialogShowCount, equals(1));
      expect(find.text('🎉 课程完成！ (1)'), findsOneWidget);

      // 点击按钮
      await tester.tap(find.text('返回学习首页'));
      await tester.pump();

      // 对话框应该关闭，不应该再次显示
      expect(find.text('🎉 课程完成！ (1)'), findsNothing);
      expect(dialogShowCount, equals(1)); // 应该还是1，不应该增加
    });
  });
}
