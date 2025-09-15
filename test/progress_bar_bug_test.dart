import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/widgets/learning_progress_bar.dart';
import 'package:testflutter/widgets/learning_stats_panel.dart';
import 'package:flutter/material.dart';

void main() {
  group('Progress Bar Bug Tests', () {
    test('RED: LearningLesson progress should be 100% when all steps completed',
        () {
      // 创建一个有3个步骤的课程
      final lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          const LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Test step 1',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          const LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Test step 2',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          const LearningStep(
            id: 'step3',
            title: 'Step 3',
            description: 'Test step 3',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
        ],
        currentStepIndex: 2, // 最后一步 (0-based index)
      );

      // 当所有步骤都完成时，进度应该是100%
      expect(lesson.progress, equals(1.0));
    });

    test('RED: Progress calculation should be consistent across components',
        () {
      // 测试进度计算的一致性
      final lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          const LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Test step 1',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          const LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Test step 2',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          const LearningStep(
            id: 'step3',
            title: 'Step 3',
            description: 'Test step 3',
            type: StepType.explanation,
            status: StepStatus.inProgress,
          ),
        ],
        currentStepIndex: 2, // 在第3步 (0-based index)
      );

      // 当前步骤显示应该是 "3 / 3"
      final currentStepDisplay = lesson.currentStepIndex + 1;
      final totalSteps = lesson.steps.length;

      // 但进度应该是 2/3 = 0.67 (因为只有2步完成)
      final expectedProgress = 2.0 / 3.0;

      expect(currentStepDisplay, equals(3));
      expect(totalSteps, equals(3));
      expect(lesson.progress, closeTo(expectedProgress, 0.01));

      // 这里暴露了问题：显示"3/3"但进度不是100%
    });

    test(
        'RED: When on last step and completed, both display and progress should be 100%',
        () {
      // 测试最后一步完成时的情况
      final lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          const LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Test step 1',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          const LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Test step 2',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          const LearningStep(
            id: 'step3',
            title: 'Step 3',
            description: 'Test step 3',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
        ],
        currentStepIndex: 2, // 最后一步 (0-based index)
      );

      // 步骤显示
      final currentStepDisplay = lesson.currentStepIndex + 1;
      final totalSteps = lesson.steps.length;

      // 当显示 "3/3" 时，进度也应该是 100%
      expect(currentStepDisplay, equals(3));
      expect(totalSteps, equals(3));
      expect(lesson.progress, equals(1.0));

      // 进度百分比应该是 100%
      final progressPercentage = (lesson.progress * 100).toInt();
      expect(progressPercentage, equals(100));
    });

    testWidgets('RED: LearningProgressBar should show correct progress',
        (WidgetTester tester) async {
      // 测试进度条组件显示
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningProgressBar(
              currentStep: 2, // 第3步 (0-based)
              totalSteps: 3,
              progress: 1.0, // 100% 完成
            ),
          ),
        ),
      );

      // 应该显示 "步骤 3 / 3"
      expect(find.text('步骤 3 / 3'), findsOneWidget);

      // 应该显示 "100% 完成"
      expect(find.text('100% 完成'), findsOneWidget);

      // 进度条的值应该是 1.0
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, equals(1.0));
    });

    test('RED: Progress calculation edge cases', () {
      // 测试边界情况

      // 空步骤列表
      final emptyLesson = LearningLesson(
        id: 'empty',
        title: 'Empty Lesson',
        description: 'Empty',
        mode: LearningMode.basicRules,
        steps: [],
        currentStepIndex: 0,
      );
      expect(emptyLesson.progress, equals(0.0));

      // 单步骤课程
      final singleStepLesson = LearningLesson(
        id: 'single',
        title: 'Single Step Lesson',
        description: 'Single',
        mode: LearningMode.basicRules,
        steps: [
          const LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Test step 1',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
        ],
        currentStepIndex: 0,
      );
      expect(singleStepLesson.progress, equals(1.0));
    });

    testWidgets(
        'RED: LearningStatsPanel should use lesson.progress not currentStep calculation',
        (WidgetTester tester) async {
      // 创建一个在最后一步但未完成的课程
      final lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          const LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Test step 1',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          const LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Test step 2',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          const LearningStep(
            id: 'step3',
            title: 'Step 3',
            description: 'Test step 3',
            type: StepType.explanation,
            status: StepStatus.inProgress, // 最后一步进行中，未完成
          ),
        ],
        currentStepIndex: 2, // 在第3步 (0-based index)
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LearningStatsPanel(
            lesson: lesson,
            moveCount: 5,
            correctMoves: 3,
            incorrectMoves: 2,
            elapsedTime: const Duration(minutes: 2, seconds: 30),
          ),
        ),
      );

      // 应该显示 "步骤 3 / 3"
      expect(find.text('步骤 3 / 3'), findsOneWidget);

      // 但进度应该是 67% (2/3 完成)，不是 100%
      // 因为只有2步完成，第3步还在进行中
      final expectedProgress = (2.0 / 3.0 * 100).round(); // 67%
      expect(find.text('$expectedProgress% 完成'), findsOneWidget);

      // 进度条的值应该是 2/3 ≈ 0.67，不是 1.0
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, closeTo(2.0 / 3.0, 0.01));
    });
  });
}
