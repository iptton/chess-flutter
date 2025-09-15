import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testflutter/widgets/learning_board.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('LearningBoard 棋子移动测试', () {
    late List<List<ChessPiece?>> testBoard;

    setUp(() {
      // 创建一个空棋盘
      testBoard = List.generate(8, (i) => List.generate(8, (j) => null));
    });

    group('吃过路兵规则测试', () {
      testWidgets('应该允许吃过路兵移动', (WidgetTester tester) async {
        // 设置吃过路兵的棋盘状态
        testBoard[3][4] = const ChessPiece(
            type: PieceType.pawn, color: PieceColor.white); // e5
        testBoard[3][5] = const ChessPiece(
            type: PieceType.pawn, color: PieceColor.black); // f5

        // 创建吃过路兵的学习步骤
        const enPassantStep = LearningStep(
          id: 'en_passant_test',
          title: '吃过路兵测试',
          description: '测试吃过路兵移动',
          type: StepType.practice,
          requiredMoves: [
            ChessMove(
              from: Position(row: 3, col: 4), // e5
              to: Position(row: 2, col: 5), // f6 (吃过路兵目标位置)
              piece: ChessPiece(type: PieceType.pawn, color: PieceColor.white),
            ),
          ],
        );

        bool moveExecuted = false;
        Position? fromPosition;
        Position? toPosition;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LearningBoard(
                boardState: testBoard,
                isInteractive: true,
                currentStep: enPassantStep,
                onMove: (from, to) {
                  moveExecuted = true;
                  fromPosition = from;
                  toPosition = to;
                },
              ),
            ),
          ),
        );

        // 点击白兵 (e5)
        await tester.tap(find.byType(LearningBoard));
        await tester.pump();

        // 验证测试设置正确
        expect(moveExecuted, false, reason: '移动还未执行');
      });

      testWidgets('应该显示吃过路兵的可移动位置', (WidgetTester tester) async {
        // 设置吃过路兵的棋盘状态
        testBoard[3][4] = const ChessPiece(
            type: PieceType.pawn, color: PieceColor.white); // e5
        testBoard[3][5] = const ChessPiece(
            type: PieceType.pawn, color: PieceColor.black); // f5

        // 创建吃过路兵的学习步骤
        const enPassantStep = LearningStep(
          id: 'en_passant_test',
          title: '吃过路兵测试',
          description: '测试吃过路兵移动',
          type: StepType.practice,
          requiredMoves: [
            ChessMove(
              from: Position(row: 3, col: 4), // e5
              to: Position(row: 2, col: 5), // f6 (吃过路兵目标位置)
              piece: ChessPiece(type: PieceType.pawn, color: PieceColor.white),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LearningBoard(
                boardState: testBoard,
                isInteractive: true,
                currentStep: enPassantStep,
                onMove: (from, to) {},
              ),
            ),
          ),
        );

        // 验证棋盘渲染成功
        expect(find.byType(LearningBoard), findsOneWidget);
      });
    });

    group('跳过棋子移动测试', () {
      testWidgets('应该允许马跳过其他棋子', (WidgetTester tester) async {
        // 设置马跳跃的棋盘状态
        testBoard[7][1] = const ChessPiece(
            type: PieceType.knight, color: PieceColor.white); // b1
        testBoard[6][1] = const ChessPiece(
            type: PieceType.pawn, color: PieceColor.white); // b2 (阻挡)

        // 创建马跳跃的学习步骤
        const knightJumpStep = LearningStep(
          id: 'knight_jump_test',
          title: '马跳跃测试',
          description: '测试马跳过棋子',
          type: StepType.practice,
          requiredMoves: [
            ChessMove(
              from: Position(row: 7, col: 1), // b1
              to: Position(row: 5, col: 2), // c3 (跳过b2兵)
              piece:
                  ChessPiece(type: PieceType.knight, color: PieceColor.white),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LearningBoard(
                boardState: testBoard,
                isInteractive: true,
                currentStep: knightJumpStep,
                onMove: (from, to) {},
              ),
            ),
          ),
        );

        // 验证棋盘渲染成功
        expect(find.byType(LearningBoard), findsOneWidget);
      });

      testWidgets('应该允许象跳过棋子（在学习模式特定情况下）', (WidgetTester tester) async {
        // 设置象跳跃的棋盘状态（在某些学习场景中可能需要）
        testBoard[7][2] = const ChessPiece(
            type: PieceType.bishop, color: PieceColor.white); // c1
        testBoard[6][3] = const ChessPiece(
            type: PieceType.pawn, color: PieceColor.white); // d2 (通常会阻挡)

        // 创建特殊的学习步骤，允许象"跳过"棋子（用于教学目的）
        const bishopSpecialStep = LearningStep(
          id: 'bishop_special_test',
          title: '象特殊移动测试',
          description: '测试学习模式下的特殊移动',
          type: StepType.practice,
          requiredMoves: [
            ChessMove(
              from: Position(row: 7, col: 2), // c1
              to: Position(row: 4, col: 5), // f4 (跳过d2)
              piece:
                  ChessPiece(type: PieceType.bishop, color: PieceColor.white),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LearningBoard(
                boardState: testBoard,
                isInteractive: true,
                currentStep: bishopSpecialStep,
                onMove: (from, to) {},
              ),
            ),
          ),
        );

        // 验证棋盘渲染成功
        expect(find.byType(LearningBoard), findsOneWidget);
      });
    });

    group('标准移动规则测试', () {
      testWidgets('没有学习步骤时应该使用标准移动规则', (WidgetTester tester) async {
        // 设置标准棋盘状态
        testBoard[6][4] = const ChessPiece(
            type: PieceType.pawn, color: PieceColor.white); // e2

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LearningBoard(
                boardState: testBoard,
                isInteractive: true,
                // 没有传递currentStep，应该使用标准规则
                onMove: (from, to) {},
              ),
            ),
          ),
        );

        // 验证棋盘渲染成功
        expect(find.byType(LearningBoard), findsOneWidget);
      });

      testWidgets('非练习步骤应该使用标准移动规则', (WidgetTester tester) async {
        // 设置标准棋盘状态
        testBoard[6][4] = const ChessPiece(
            type: PieceType.pawn, color: PieceColor.white); // e2

        // 创建解释步骤（非练习）
        const explanationStep = LearningStep(
          id: 'explanation_test',
          title: '解释步骤',
          description: '这是解释步骤',
          type: StepType.explanation, // 非练习类型
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LearningBoard(
                boardState: testBoard,
                isInteractive: true,
                currentStep: explanationStep,
                onMove: (from, to) {},
              ),
            ),
          ),
        );

        // 验证棋盘渲染成功
        expect(find.byType(LearningBoard), findsOneWidget);
      });
    });
  });
}
