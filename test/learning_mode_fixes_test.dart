import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/widgets/learning_step_controls.dart';
import 'package:testflutter/services/settings_service.dart';

void main() {
  group('Learning Mode Fixes Tests', () {
    testWidgets('RED: Learning mode should auto-return after completion',
        (WidgetTester tester) async {
      // 测试学习模式完成后自动返回首页
      final bloc = LearningBloc();
      
      // 创建一个简单的课程
      const lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Test step 1',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
        ],
        currentStepIndex: 0,
        isCompleted: true,
      );

      bloc.emit(LearningState(currentLesson: lesson));
      
      // 触发完成课程事件
      bloc.add(const CompleteLesson());
      
      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 课程应该被标记为完成
      expect(bloc.state.currentLesson?.isCompleted, isTrue);
      expect(bloc.state.currentInstruction, contains('恭喜'));
    });

    testWidgets('RED: Go to last step button should be enabled when not on last step',
        (WidgetTester tester) async {
      // 测试跳到最后一步按钮的状态
      const widget = LearningStepControls(
        canGoBack: true,
        canGoForward: true,
        canSkip: false,
        isLastStep: false,
        canGoToLast: true, // 不在最后一步时应该可用
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // 在宽屏布局中应该能找到"最后一步"按钮
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // 应该有"最后一步"按钮
      expect(find.text('最后一步'), findsOneWidget);
    });

    testWidgets('RED: Go to last step button should be disabled on last step',
        (WidgetTester tester) async {
      // 测试在最后一步时按钮应该被禁用
      const widget = LearningStepControls(
        canGoBack: true,
        canGoForward: true,
        canSkip: false,
        isLastStep: true,
        canGoToLast: false, // 在最后一步时应该不可用
      );

      await tester.binding.setSurfaceSize(const Size(1024, 768));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // 应该有"最后一步"按钮但是禁用状态
      expect(find.text('最后一步'), findsOneWidget);
      
      final button = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('最后一步'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(button.onPressed, isNull); // 按钮应该被禁用
    });

    test('RED: Sound settings should be persistent', () async {
      // 测试音效设置的持久化
      
      // 初始状态应该是关闭的
      final initialState = await SettingsService.getSoundEnabled();
      expect(initialState, isFalse);
      
      // 设置为开启
      await SettingsService.setSoundEnabled(true);
      final enabledState = await SettingsService.getSoundEnabled();
      expect(enabledState, isTrue);
      
      // 设置为关闭
      await SettingsService.setSoundEnabled(false);
      final disabledState = await SettingsService.getSoundEnabled();
      expect(disabledState, isFalse);
    });

    test('GREEN: Progress calculation should be correct', () {
      // 测试进度计算的正确性
      const lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Test step 1',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Test step 2',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          LearningStep(
            id: 'step3',
            title: 'Step 3',
            description: 'Test step 3',
            type: StepType.explanation,
            status: StepStatus.inProgress,
          ),
        ],
        currentStepIndex: 2,
      );

      // 2/3 完成 = 66.67%
      expect(lesson.progress, closeTo(0.6667, 0.001));
    });

    test('GREEN: GoToStep event should work correctly', () async {
      // 测试跳转到指定步骤的功能
      final bloc = LearningBloc();
      
      const lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Test step 1',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Test step 2',
            type: StepType.explanation,
            status: StepStatus.notStarted,
          ),
          LearningStep(
            id: 'step3',
            title: 'Step 3',
            description: 'Test step 3',
            type: StepType.explanation,
            status: StepStatus.notStarted,
          ),
        ],
        currentStepIndex: 0,
      );

      bloc.emit(LearningState(currentLesson: lesson));
      
      // 跳转到最后一步
      bloc.add(const GoToStep(2));
      
      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 应该跳转到第3步（索引2）
      expect(bloc.state.currentLesson?.currentStepIndex, equals(2));
    });
  });
}
