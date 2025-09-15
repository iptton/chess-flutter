import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('简单Dialog测试', () {
    testWidgets('验证ConfirmLessonCompletion事件处理', (WidgetTester tester) async {
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

      // 验证初始状态
      expect(learningBloc.state.isLessonCompleted, isTrue);
      expect(learningBloc.state.currentLesson, isNotNull);

      // Act - 触发ConfirmLessonCompletion事件
      learningBloc.add(const ConfirmLessonCompletion());
      
      // 等待状态更新
      await tester.pump();

      // Assert - 验证状态被正确重置
      expect(learningBloc.state.isLessonCompleted, isFalse);
      expect(learningBloc.state.currentLesson, isNull);
    });

    testWidgets('测试简单的对话框显示和关闭', (WidgetTester tester) async {
      bool dialogShown = false;
      bool dialogClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  dialogShown = true;
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('测试对话框'),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            dialogClosed = true;
                          },
                          child: const Text('关闭'),
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

      expect(dialogShown, isTrue);
      expect(find.text('测试对话框'), findsOneWidget);
      expect(find.text('关闭'), findsOneWidget);

      // 点击关闭按钮
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();

      expect(dialogClosed, isTrue);
      expect(find.text('测试对话框'), findsNothing);
      expect(find.text('关闭'), findsNothing);
    });

    testWidgets('测试BlocListener中的对话框', (WidgetTester tester) async {
      final learningBloc = LearningBloc();
      bool dialogShown = false;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: Scaffold(
              body: BlocListener<LearningBloc, LearningState>(
                listener: (context, state) {
                  if (state.isLessonCompleted && !dialogShown) {
                    dialogShown = true;
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('课程完成'),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              dialogShown = false;
                              // 不触发任何事件，只是关闭对话框
                            },
                            child: const Text('确定'),
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

      await tester.pumpAndSettle();

      expect(dialogShown, isTrue);
      expect(find.text('课程完成'), findsOneWidget);

      // 点击确定按钮
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(dialogShown, isFalse);
      expect(find.text('课程完成'), findsNothing);
    });
  });
}
