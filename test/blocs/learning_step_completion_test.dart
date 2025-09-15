import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';

void main() {
  group('LearningBloc 步骤完成功能', () {
    late LearningBloc learningBloc;

    setUp(() {
      learningBloc = LearningBloc();
    });

    tearDown(() {
      learningBloc.close();
    });

    group('练习步骤完成', () {
      blocTest<LearningBloc, LearningState>(
        '当练习步骤完成时应该设置isStepCompleted为true',
        build: () => learningBloc,
        act: (bloc) {
          // 设置一个包含练习步骤的课程
          final lesson = LearningLesson(
            id: 'test-lesson',
            title: '测试课程',
            description: '测试描述',
            mode: LearningMode.pieceMovement,
            steps: [
              LearningStep(
                id: 'practice-step',
                title: '练习步骤',
                description: '这是一个练习步骤',
                type: StepType.practice,
                requiredMoves: [
                  ChessMove(
                    from: Position(row: 6, col: 4),
                    to: Position(row: 4, col: 4),
                    piece: ChessPiece(
                        type: PieceType.pawn, color: PieceColor.white),
                  ),
                ],
                successMessage: '太棒了！您完成了这个练习！',
              ),
            ],
          );

          // 设置初始状态
          bloc.emit(LearningState(
            currentLesson: lesson,
            currentBoard: _createInitialBoard(),
            isWaitingForMove: true,
          ));

          // 执行正确的移动
          bloc.add(ExecuteLearningMove(
            Position(row: 6, col: 4),
            Position(row: 4, col: 4),
          ));
        },
        expect: () => [
          // 第一个状态：移动执行后
          isA<LearningState>()
              .having((s) => s.currentInstruction, 'currentInstruction',
                  contains('太棒了！您完成了这个练习！'))
              .having((s) => s.isStepCompleted, 'isStepCompleted', true),
        ],
      );

      blocTest<LearningBloc, LearningState>(
        '确认步骤完成后应该重置isStepCompleted并进入下一步',
        build: () => learningBloc,
        act: (bloc) {
          // 设置步骤完成状态
          bloc.emit(LearningState(
            currentLesson: LearningLesson(
              id: 'test-lesson',
              title: '测试课程',
              description: '测试描述',
              mode: LearningMode.pieceMovement,
              steps: [
                LearningStep(
                  id: 'step1',
                  title: '第一步',
                  description: '第一步描述',
                  type: StepType.practice,
                  status: StepStatus.completed,
                ),
                LearningStep(
                  id: 'step2',
                  title: '第二步',
                  description: '第二步描述',
                  type: StepType.explanation,
                ),
              ],
              currentStepIndex: 0,
            ),
            isStepCompleted: true,
          ));

          // 确认步骤完成
          bloc.add(const ConfirmStepCompletion());
        },
        expect: () => [
          // 重置isStepCompleted
          isA<LearningState>()
              .having((s) => s.isStepCompleted, 'isStepCompleted', false),
          // 进入下一步
          isA<LearningState>().having(
              (s) => s.currentLesson?.currentStepIndex, 'currentStepIndex', 1),
        ],
      );
    });

    group('非练习步骤完成', () {
      blocTest<LearningBloc, LearningState>(
        '解释步骤完成时应该自动进入下一步而不显示确认对话框',
        build: () => learningBloc,
        act: (bloc) {
          // 设置一个包含解释步骤的课程
          final lesson = LearningLesson(
            id: 'test-lesson',
            title: '测试课程',
            description: '测试描述',
            mode: LearningMode.basicRules,
            steps: [
              LearningStep(
                id: 'explanation-step',
                title: '解释步骤',
                description: '这是一个解释步骤',
                type: StepType.explanation,
              ),
              LearningStep(
                id: 'next-step',
                title: '下一步',
                description: '下一步描述',
                type: StepType.explanation,
              ),
            ],
          );

          // 设置初始状态
          bloc.emit(LearningState(
            currentLesson: lesson,
          ));

          // 模拟步骤完成（通过内部方法）
          bloc.add(const NextStep());
        },
        expect: () => [
          // 应该直接进入下一步，不设置isStepCompleted
          isA<LearningState>()
              .having((s) => s.currentLesson?.currentStepIndex,
                  'currentStepIndex', 1)
              .having((s) => s.isStepCompleted, 'isStepCompleted', false),
        ],
      );
    });
  });
}

/// 创建初始棋盘状态
List<List<ChessPiece?>> _createInitialBoard() {
  final board = List.generate(8, (row) {
    return List.generate(8, (col) {
      return _getInitialPiece(row, col);
    });
  });
  return board;
}

/// 获取初始位置的棋子
ChessPiece? _getInitialPiece(int row, int col) {
  if (row == 1) {
    return const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
  } else if (row == 6) {
    return const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
  } else if (row == 0 || row == 7) {
    final color = row == 0 ? PieceColor.black : PieceColor.white;
    switch (col) {
      case 0:
      case 7:
        return ChessPiece(type: PieceType.rook, color: color);
      case 1:
      case 6:
        return ChessPiece(type: PieceType.knight, color: color);
      case 2:
      case 5:
        return ChessPiece(type: PieceType.bishop, color: color);
      case 3:
        return ChessPiece(type: PieceType.queen, color: color);
      case 4:
        return ChessPiece(type: PieceType.king, color: color);
    }
  }
  return null;
}
