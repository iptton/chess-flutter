import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/widgets/learning_progress_bar.dart';
import 'package:testflutter/widgets/learning_stats_panel.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
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

  group('Real-world Progress Bug Simulation', () {
    test('RED: Progress should update when steps are completed in sequence',
        () {
      // 模拟真实的学习过程：从0%开始，逐步完成
      var lesson = const LearningLesson(
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
            status: StepStatus.notStarted, // 初始状态
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

      // 初始状态：0% 完成
      expect(lesson.progress, equals(0.0));
      expect((lesson.progress * 100).toInt(), equals(0));

      // 完成第一步
      final updatedSteps1 = List<LearningStep>.from(lesson.steps);
      updatedSteps1[0] =
          updatedSteps1[0].copyWith(status: StepStatus.completed);
      lesson = lesson.copyWith(steps: updatedSteps1, currentStepIndex: 1);

      // 应该是 33% 完成
      expect(lesson.progress, closeTo(1.0 / 3.0, 0.01));
      expect((lesson.progress * 100).toInt(), equals(33));

      // 完成第二步
      final updatedSteps2 = List<LearningStep>.from(lesson.steps);
      updatedSteps2[1] =
          updatedSteps2[1].copyWith(status: StepStatus.completed);
      lesson = lesson.copyWith(steps: updatedSteps2, currentStepIndex: 2);

      // 应该是 67% 完成
      expect(lesson.progress, closeTo(2.0 / 3.0, 0.01));
      expect((lesson.progress * 100).toInt(), equals(66));

      // 完成第三步
      final updatedSteps3 = List<LearningStep>.from(lesson.steps);
      updatedSteps3[2] =
          updatedSteps3[2].copyWith(status: StepStatus.completed);
      lesson = lesson.copyWith(steps: updatedSteps3, currentStepIndex: 2);

      // 应该是 100% 完成
      expect(lesson.progress, equals(1.0));
      expect((lesson.progress * 100).toInt(), equals(100));
    });

    test(
        'RED: Progress should not be stuck at 0% when steps have wrong initial status',
        () {
      // 检查是否因为初始状态设置错误导致进度卡在0%
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
            // 注意：如果默认状态不是 notStarted，可能导致问题
          ),
          LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Test step 2',
            type: StepType.explanation,
          ),
        ],
        currentStepIndex: 0,
      );

      // 检查默认状态
      expect(lesson.steps[0].status, equals(StepStatus.notStarted));
      expect(lesson.steps[1].status, equals(StepStatus.notStarted));

      // 初始进度应该是 0%
      expect(lesson.progress, equals(0.0));
    });

    test('RED: Learning bloc should update progress when completing steps',
        () async {
      // 测试学习bloc是否正确更新进度
      final bloc = LearningBloc();

      // 创建一个简单的课程
      final lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: const [
          LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Test step 1',
            type: StepType.explanation,
            status: StepStatus.notStarted,
          ),
          LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Test step 2',
            type: StepType.explanation,
            status: StepStatus.notStarted,
          ),
        ],
        currentStepIndex: 0,
      );

      // 设置初始状态
      bloc.emit(LearningState(currentLesson: lesson));

      // 初始进度应该是 0%
      expect(bloc.state.currentLesson?.progress, equals(0.0));

      // 模拟完成第一步
      final updatedSteps = List<LearningStep>.from(lesson.steps);
      updatedSteps[0] = updatedSteps[0].copyWith(status: StepStatus.completed);
      final updatedLesson =
          lesson.copyWith(steps: updatedSteps, currentStepIndex: 1);

      bloc.emit(LearningState(currentLesson: updatedLesson));

      // 进度应该是 50%
      expect(bloc.state.currentLesson?.progress, equals(0.5));
      expect((bloc.state.currentLesson!.progress * 100).toInt(), equals(50));

      // 完成第二步
      final finalSteps = List<LearningStep>.from(updatedLesson.steps);
      finalSteps[1] = finalSteps[1].copyWith(status: StepStatus.completed);
      final finalLesson = updatedLesson.copyWith(steps: finalSteps);

      bloc.emit(LearningState(currentLesson: finalLesson));

      // 进度应该是 100%
      expect(bloc.state.currentLesson?.progress, equals(1.0));
      expect((bloc.state.currentLesson!.progress * 100).toInt(), equals(100));

      await bloc.close();
    });

    test('RED: Real learning flow should update progress correctly', () async {
      // 测试真实的学习流程：从加载课程到完成步骤
      final bloc = LearningBloc();

      // 创建一个包含不同类型步骤的课程
      final lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: const [
          LearningStep(
            id: 'step1',
            title: 'Explanation Step',
            description: 'Learn the basics',
            type: StepType.explanation,
            instructions: ['This is an explanation'],
            status: StepStatus.notStarted,
          ),
          LearningStep(
            id: 'step2',
            title: 'Practice Step',
            description: 'Practice what you learned',
            type: StepType.practice,
            instructions: ['Make the required move'],
            status: StepStatus.notStarted,
            // 这个步骤有必需的移动
            requiredMoves: [
              ChessMove(
                from: Position(row: 6, col: 4), // e2
                to: Position(row: 4, col: 4), // e4
                piece:
                    ChessPiece(type: PieceType.pawn, color: PieceColor.white),
              ),
            ],
          ),
        ],
        currentStepIndex: 0,
      );

      // 开始课程
      bloc.emit(LearningState(currentLesson: lesson));

      // 初始进度应该是 0%
      expect(bloc.state.currentLesson?.progress, equals(0.0));

      // 模拟用户点击"下一步"完成第一个解释步骤
      // 这应该触发 _completeCurrentStep
      final updatedSteps1 = List<LearningStep>.from(lesson.steps);
      updatedSteps1[0] =
          updatedSteps1[0].copyWith(status: StepStatus.completed);
      final updatedLesson1 =
          lesson.copyWith(steps: updatedSteps1, currentStepIndex: 1);

      bloc.emit(LearningState(currentLesson: updatedLesson1));

      // 进度应该是 50% (1/2 完成)
      expect(bloc.state.currentLesson?.progress, equals(0.5));
      expect((bloc.state.currentLesson!.progress * 100).toInt(), equals(50));

      // 模拟用户完成练习步骤的必需移动
      final updatedSteps2 = List<LearningStep>.from(updatedLesson1.steps);
      updatedSteps2[1] =
          updatedSteps2[1].copyWith(status: StepStatus.completed);
      final updatedLesson2 = updatedLesson1.copyWith(steps: updatedSteps2);

      bloc.emit(LearningState(currentLesson: updatedLesson2));

      // 进度应该是 100% (2/2 完成)
      expect(bloc.state.currentLesson?.progress, equals(1.0));
      expect((bloc.state.currentLesson!.progress * 100).toInt(), equals(100));

      await bloc.close();
    });

    test(
        'GREEN: NextStep should mark current step as completed and update progress',
        () async {
      // 测试修复后的NextStep行为
      final bloc = LearningBloc();

      // 创建一个简单的课程
      final lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: const [
          LearningStep(
            id: 'step1',
            title: 'Explanation Step',
            description: 'Learn the basics',
            type: StepType.explanation,
            instructions: ['This is an explanation'],
            status: StepStatus.notStarted,
          ),
          LearningStep(
            id: 'step2',
            title: 'Another Explanation',
            description: 'Learn more',
            type: StepType.explanation,
            instructions: ['This is another explanation'],
            status: StepStatus.notStarted,
          ),
        ],
        currentStepIndex: 0,
      );

      // 开始课程
      bloc.emit(LearningState(currentLesson: lesson));

      // 初始进度应该是 0%
      expect(bloc.state.currentLesson?.progress, equals(0.0));
      expect(bloc.state.currentLesson?.steps[0].status,
          equals(StepStatus.notStarted));

      // 触发NextStep事件
      bloc.add(const NextStep());

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));

      // 第一步应该被标记为完成，进度应该是 50%
      expect(bloc.state.currentLesson?.steps[0].status,
          equals(StepStatus.completed));
      expect(bloc.state.currentLesson?.progress, equals(0.5));
      expect((bloc.state.currentLesson!.progress * 100).toInt(), equals(50));
      expect(bloc.state.currentLesson?.currentStepIndex, equals(1));

      // 再次触发NextStep事件
      bloc.add(const NextStep());

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));

      // 第二步也应该被标记为完成，进度应该是 100%
      expect(bloc.state.currentLesson?.steps[1].status,
          equals(StepStatus.completed));
      expect(bloc.state.currentLesson?.progress, equals(1.0));
      expect((bloc.state.currentLesson!.progress * 100).toInt(), equals(100));

      await bloc.close();
    });
  });
}
