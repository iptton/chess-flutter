import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/screens/learning_screen.dart';

void main() {
  group('RED: LearningScreen Dialog关闭问题测试', () {
    testWidgets('实际学习界面中的对话框应该正确关闭', (WidgetTester tester) async {
      // Arrange
      final learningBloc = LearningBloc();
      
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
            child: LearningScreen(),
          ),
        ),
      );

      // Act - 触发课程完成状态
      learningBloc.add(const CompleteLesson());
      await tester.pumpAndSettle();

      // Assert - 验证对话框显示
      expect(find.text('🎉 课程完成！'), findsOneWidget);
      expect(find.text('返回学习首页'), findsOneWidget);

      // Act - 点击"返回学习首页"按钮
      await tester.tap(find.text('返回学习首页'));
      await tester.pumpAndSettle();

      // Assert - 验证对话框关闭
      expect(find.text('🎉 课程完成！'), findsNothing);
      expect(find.text('返回学习首页'), findsNothing);
      
      // 验证状态已重置
      expect(learningBloc.state.isLessonCompleted, isFalse);
      expect(learningBloc.state.currentLesson, isNull);
    });

    testWidgets('多次快速点击不应该导致问题', (WidgetTester tester) async {
      // Arrange
      final learningBloc = LearningBloc();
      
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
            child: LearningScreen(),
          ),
        ),
      );

      // Act - 触发课程完成状态
      learningBloc.add(const CompleteLesson());
      await tester.pumpAndSettle();

      // 验证对话框显示
      expect(find.text('🎉 课程完成！'), findsOneWidget);
      
      // Act - 快速多次点击按钮
      final button = find.text('返回学习首页');
      await tester.tap(button);
      await tester.pump(); // 不等待settle，模拟快速点击
      
      // 尝试再次点击（如果按钮还存在）
      if (tester.any(button)) {
        await tester.tap(button);
      }
      
      await tester.pumpAndSettle();

      // Assert - 对话框应该关闭，状态应该正确
      expect(find.text('🎉 课程完成！'), findsNothing);
      expect(learningBloc.state.isLessonCompleted, isFalse);
      expect(learningBloc.state.currentLesson, isNull);
    });
  });
}
