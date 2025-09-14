import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/widgets/enhanced_learning_board.dart';
import 'package:testflutter/widgets/enhanced_learning_instruction_panel.dart';
import 'package:testflutter/widgets/learning_stats_panel.dart';

void main() {
  group('Enhanced Learning Mode Tests', () {
    late LearningBloc learningBloc;

    setUp(() {
      learningBloc = LearningBloc();
    });

    tearDown(() {
      learningBloc.close();
    });

    group('Enhanced Learning Board Tests', () {
      testWidgets('should display correct/incorrect move feedback',
          (WidgetTester tester) async {
        // Arrange: Create a practice step with required moves
        final practiceStep = LearningStep(
          id: 'test_practice',
          title: '测试练习',
          description: '测试正确错误提示',
          type: StepType.practice,
          requiredMoves: [
            ChessMove(
              from: const Position(row: 6, col: 4),
              to: const Position(row: 4, col: 4),
              piece: const ChessPiece(
                  type: PieceType.pawn, color: PieceColor.white),
            ),
          ],
          successMessage: '正确！',
          failureMessage: '错误，请再试一次',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: learningBloc,
              child: EnhancedLearningBoard(
                boardState: GameState.initial().board,
                currentStep: practiceStep,
                onMove: (from, to) =>
                    learningBloc.add(ExecuteLearningMove(from, to)),
                isInteractive: true,
                showFeedback: true,
              ),
            ),
          ),
        );

        // Act: Make a correct move
        await tester.tap(find.byKey(const Key('square_6_4')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('square_4_4')));
        await tester.pump();

        // Assert: Should show success feedback
        expect(find.text('正确！'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should show incorrect move feedback',
          (WidgetTester tester) async {
        // Arrange: Create a practice step with specific required moves
        final practiceStep = LearningStep(
          id: 'test_practice',
          title: '测试练习',
          description: '测试错误提示',
          type: StepType.practice,
          requiredMoves: [
            ChessMove(
              from: const Position(row: 6, col: 4),
              to: const Position(row: 4, col: 4),
              piece: const ChessPiece(
                  type: PieceType.pawn, color: PieceColor.white),
            ),
          ],
          failureMessage: '错误，请再试一次',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: learningBloc,
              child: EnhancedLearningBoard(
                boardState: GameState.initial().board,
                currentStep: practiceStep,
                onMove: (from, to) =>
                    learningBloc.add(ExecuteLearningMove(from, to)),
                isInteractive: true,
                showFeedback: true,
              ),
            ),
          ),
        );

        // Act: Make an incorrect move
        await tester.tap(find.byKey(const Key('square_6_4')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('square_5_4'))); // Wrong move
        await tester.pump();

        // Assert: Should show error feedback
        expect(find.text('错误，请再试一次'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should adapt to different screen widths',
          (WidgetTester tester) async {
        final practiceStep = LearningStep(
          id: 'test_responsive',
          title: '响应式测试',
          description: '测试屏幕适配',
          type: StepType.practice,
        );

        // Test mobile layout (narrow screen)
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: learningBloc,
              child: EnhancedLearningBoard(
                boardState: GameState.initial().board,
                currentStep: practiceStep,
                onMove: (from, to) =>
                    learningBloc.add(ExecuteLearningMove(from, to)),
                isInteractive: true,
                showFeedback: true,
              ),
            ),
          ),
        );

        await tester.pump();

        // Assert: Should use mobile layout
        expect(find.byKey(const Key('mobile_layout')), findsOneWidget);

        // Test tablet/desktop layout (wide screen)
        tester.view.physicalSize = const Size(1200, 800);
        await tester.pump();

        // Assert: Should use desktop layout
        expect(find.byKey(const Key('desktop_layout')), findsOneWidget);

        addTearDown(tester.view.reset);
      });
    });

    group('Learning Stats Panel Tests', () {
      testWidgets('should display step count and completion status',
          (WidgetTester tester) async {
        // Arrange: Create lesson with multiple steps
        final lesson = LearningLesson(
          id: 'test_lesson',
          title: '测试课程',
          description: '测试统计面板',
          mode: LearningMode.pieceMovement,
          steps: [
            LearningStep(
              id: 'step1',
              title: '步骤1',
              description: '第一步',
              type: StepType.explanation,
              status: StepStatus.completed,
            ),
            LearningStep(
              id: 'step2',
              title: '步骤2',
              description: '第二步',
              type: StepType.practice,
              status: StepStatus.inProgress,
            ),
            LearningStep(
              id: 'step3',
              title: '步骤3',
              description: '第三步',
              type: StepType.quiz,
              status: StepStatus.notStarted,
            ),
          ],
          currentStepIndex: 1,
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

        // Assert: Should display step progress
        expect(find.text('步骤 2 / 3'), findsOneWidget);
        expect(find.text('67% 完成'), findsOneWidget);

        // Assert: Should display move statistics
        expect(find.text('5'), findsOneWidget); // moveCount value
        expect(find.text('移动次数'), findsOneWidget); // moveCount label
        expect(find.text('3'), findsOneWidget); // correctMoves value
        expect(find.text('正确'), findsOneWidget); // correctMoves label
        expect(find.text('2'), findsOneWidget); // incorrectMoves value
        expect(find.text('错误'), findsOneWidget); // incorrectMoves label
        expect(find.text('准确率: 60%'), findsOneWidget);

        // Assert: Should display elapsed time
        expect(find.text('用时: 2:30'), findsOneWidget);
      });

      testWidgets('should show completion celebration',
          (WidgetTester tester) async {
        // Arrange: Create completed lesson
        final completedLesson = LearningLesson(
          id: 'completed_lesson',
          title: '已完成课程',
          description: '测试完成庆祝',
          mode: LearningMode.basicRules,
          steps: [
            LearningStep(
              id: 'step1',
              title: '步骤1',
              description: '第一步',
              type: StepType.explanation,
              status: StepStatus.completed,
            ),
          ],
          currentStepIndex: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: LearningStatsPanel(
              lesson: completedLesson,
              moveCount: 10,
              correctMoves: 8,
              incorrectMoves: 2,
              elapsedTime: const Duration(minutes: 5),
              isCompleted: true,
            ),
          ),
        );

        // Assert: Should show completion celebration
        expect(find.text('🎉 恭喜完成！'), findsOneWidget);
        expect(find.byIcon(Icons.celebration), findsOneWidget);
        expect(find.text('100% 完成'), findsOneWidget);
      });
    });

    group('Enhanced Learning Instruction Panel Tests', () {
      testWidgets('should display interactive instructions with progress',
          (WidgetTester tester) async {
        final practiceStep = LearningStep(
          id: 'interactive_step',
          title: '交互式步骤',
          description: '测试交互式指令',
          type: StepType.practice,
          instructions: [
            '第一条指令',
            '第二条指令',
            '第三条指令',
          ],
          requiredMoves: [
            ChessMove(
              from: const Position(row: 6, col: 4),
              to: const Position(row: 4, col: 4),
              piece: const ChessPiece(
                  type: PieceType.pawn, color: PieceColor.white),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: EnhancedLearningInstructionPanel(
              step: practiceStep,
              currentInstructionIndex: 0,
              totalInstructions: 3,
              onNextInstruction: () {},
              onPreviousInstruction: () {},
              showProgress: true,
            ),
          ),
        );

        // Assert: Should display current instruction with progress
        expect(find.text('第一条指令'), findsOneWidget);
        expect(find.text('1 / 3'), findsOneWidget);

        // Assert: Should show navigation buttons
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets(
          'should adapt instruction panel layout for different screen sizes',
          (WidgetTester tester) async {
        final step = LearningStep(
          id: 'responsive_step',
          title: '响应式步骤',
          description: '测试响应式布局',
          type: StepType.explanation,
          instructions: ['测试指令'],
        );

        // Test mobile layout
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: EnhancedLearningInstructionPanel(
              step: step,
              currentInstructionIndex: 0,
              totalInstructions: 1,
              onNextInstruction: () {},
              onPreviousInstruction: () {},
              showProgress: true,
            ),
          ),
        );

        await tester.pump();

        // Assert: Should use compact mobile layout
        expect(find.byKey(const Key('compact_instruction_layout')),
            findsOneWidget);

        // Test desktop layout
        tester.view.physicalSize = const Size(1200, 800);
        await tester.pump();

        // Assert: Should use expanded desktop layout
        expect(find.byKey(const Key('expanded_instruction_layout')),
            findsOneWidget);

        addTearDown(tester.view.reset);
      });
    });
  });
}
