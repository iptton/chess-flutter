import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';

void main() {
  group('Learning Controls Bug Tests', () {
    late LearningBloc bloc;

    setUp(() {
      bloc = LearningBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('GREEN: RestartCurrentStep should reset step status and reinitialize', () async {
      // 创建一个练习步骤
      const lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: 'Practice Step',
            description: 'Practice moving',
            type: StepType.practice,
            status: StepStatus.inProgress, // 已经在进行中
            requiredMoves: [
              ChessMove(
                from: Position(row: 6, col: 4), // e2
                to: Position(row: 4, col: 4), // e4
                piece: ChessPiece(type: PieceType.pawn, color: PieceColor.white),
              ),
            ],
          ),
        ],
        currentStepIndex: 0,
      );

      // 设置初始状态
      bloc.emit(LearningState(currentLesson: lesson));
      
      // 验证初始状态
      expect(bloc.state.currentLesson?.steps[0].status, equals(StepStatus.inProgress));
      
      // 触发重新开始事件
      bloc.add(const RestartCurrentStep());
      
      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 步骤状态应该被重置为未开始
      expect(bloc.state.currentLesson?.steps[0].status, equals(StepStatus.notStarted));
    });

    test('GREEN: ShowHint should provide helpful hints for different step types', () async {
      // 测试解释步骤的提示
      const explanationLesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: 'Explanation Step',
            description: 'Learn the basics',
            type: StepType.explanation,
            status: StepStatus.inProgress,
          ),
        ],
        currentStepIndex: 0,
      );

      bloc.emit(LearningState(currentLesson: explanationLesson));
      
      // 触发显示提示事件
      bloc.add(const ShowHint());
      
      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 应该显示解释步骤的提示
      expect(bloc.state.currentInstruction, contains('解释步骤'));
      expect(bloc.state.currentInstruction, contains('下一步'));
    });

    test('GREEN: ShowHint should highlight positions for practice steps', () async {
      // 测试练习步骤的提示
      const practiceLesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: 'Practice Step',
            description: 'Practice moving',
            type: StepType.practice,
            status: StepStatus.inProgress,
            requiredMoves: [
              ChessMove(
                from: Position(row: 6, col: 4), // e2
                to: Position(row: 4, col: 4), // e4
                piece: ChessPiece(type: PieceType.pawn, color: PieceColor.white),
              ),
            ],
          ),
        ],
        currentStepIndex: 0,
      );

      bloc.emit(LearningState(currentLesson: practiceLesson));
      
      // 触发显示提示事件
      bloc.add(const ShowHint());
      
      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 应该高亮提示位置
      expect(bloc.state.highlightedPositions.length, equals(2));
      expect(bloc.state.highlightedPositions, contains(const Position(row: 6, col: 4)));
      expect(bloc.state.highlightedPositions, contains(const Position(row: 4, col: 4)));
      
      // 应该显示移动提示
      expect(bloc.state.currentInstruction, contains('e2'));
      expect(bloc.state.currentInstruction, contains('e4'));
    });

    test('GREEN: SkipCurrentStep should only work for practice steps', () async {
      // 测试跳过练习步骤
      const practiceLesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: 'Practice Step',
            description: 'Practice moving',
            type: StepType.practice,
            status: StepStatus.inProgress,
          ),
          LearningStep(
            id: 'step2',
            title: 'Next Step',
            description: 'Next step',
            type: StepType.explanation,
            status: StepStatus.notStarted,
          ),
        ],
        currentStepIndex: 0,
      );

      bloc.emit(LearningState(currentLesson: practiceLesson));
      
      // 触发跳过事件
      bloc.add(const SkipCurrentStep());
      
      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 当前步骤应该被标记为完成
      expect(bloc.state.currentLesson?.steps[0].status, equals(StepStatus.completed));
      expect(bloc.state.currentInstruction, contains('已跳过'));
    });

    test('GREEN: SkipCurrentStep should not work for explanation steps', () async {
      // 测试跳过解释步骤（应该无效）
      const explanationLesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          LearningStep(
            id: 'step1',
            title: 'Explanation Step',
            description: 'Learn the basics',
            type: StepType.explanation,
            status: StepStatus.inProgress,
          ),
        ],
        currentStepIndex: 0,
      );

      bloc.emit(LearningState(currentLesson: explanationLesson));
      
      final initialInstruction = bloc.state.currentInstruction;
      
      // 触发跳过事件
      bloc.add(const SkipCurrentStep());
      
      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 解释步骤不应该被跳过，状态应该保持不变
      expect(bloc.state.currentLesson?.steps[0].status, equals(StepStatus.inProgress));
      expect(bloc.state.currentInstruction, equals(initialInstruction));
    });
  });
}
