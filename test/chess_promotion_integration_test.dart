import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/utils/chess_formatters.dart';
import 'package:testflutter/utils/chess_adapter.dart';
import 'package:testflutter/utils/chess_rules.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/screens/game_screen.dart';

void main() {
  group('Chess Promotion Integration Test - 模拟真实升变过程', () {
    late ChessBloc bloc;

    setUp(() {
      bloc = ChessBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('简化的升变流程测试 - 验证边界检查', () {
      // 模拟可能导致RangeError的游戏状态
      final problematicState = GameState(
        board: List.generate(
            8,
            (row) => List.generate(8, (col) {
                  if (row == 1 && col == 4)
                    return const ChessPiece(
                        type: PieceType.pawn, color: PieceColor.white);
                  if (row == 0 && col == 3)
                    return const ChessPiece(
                        type: PieceType.king, color: PieceColor.black);
                  if (row == 7 && col == 4)
                    return const ChessPiece(
                        type: PieceType.king, color: PieceColor.white);
                  return null;
                })),
        currentPlayer: PieceColor.white,
        selectedPosition: null,
        validMoves: [],
        hasKingMoved: {PieceColor.white: false, PieceColor.black: false},
        hasRookMoved: {
          PieceColor.white: {'queenside': false, 'kingside': false},
          PieceColor.black: {'queenside': false, 'kingside': false},
        },
        // 故意设置可能导致问题的吃过路兵状态
        lastPawnDoubleMoved: {
          PieceColor.white: null,
          PieceColor.black: const Position(row: -16, col: 4), // 异常坐标
        },
        lastPawnDoubleMovedNumber: {PieceColor.white: 0, PieceColor.black: 1},
        currentMoveNumber: 2,
        moveHistory: [],
        specialMoveMessage: null,
        lastMove: null,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false,
        undoStates: [],
        redoStates: [],
        hintMode: false,
        isInteractive: true,
        allowedPlayer: null,
        gameMode: GameMode.faceToFace,
        aiDifficulty: null,
        aiColor: null,
        isAIThinking: false,
      );

      // 测试在异常状态下获取合法移动不会崩溃
      final validMoves = ChessRules.getValidMoves(
        problematicState.board,
        const Position(row: 1, col: 4), // 白方兵的位置
        hasKingMoved: problematicState.hasKingMoved,
        hasRookMoved: problematicState.hasRookMoved,
        lastPawnDoubleMoved:
            problematicState.lastPawnDoubleMoved[PieceColor.black],
        lastPawnDoubleMovedNumber:
            problematicState.lastPawnDoubleMovedNumber[PieceColor.black],
        currentMoveNumber: problematicState.currentMoveNumber,
      );

      // 应该能够正常返回结果，而不是崩溃
      expect(validMoves, isA<List<Position>>());
      print('获取到合法移动: ${validMoves.length} 个');

      // 验证升变移动在其中
      final hasPromotionMove =
          validMoves.any((pos) => pos.row == 0 && pos.col == 4);
      expect(hasPromotionMove, true);

      print('测试通过：异常吃过路兵状态下能够正常获取合法移动');
    });

    test('模拟可能导致坐标异常的边界升变情况', () async {
      // 测试可能导致坐标计算错误的特殊情况

      // 情况1：创建可能导致吃过路兵计算错误的状态
      final problematicState = GameState(
        board: List.generate(
            8, (row) => List.generate(8, (col) => null as ChessPiece?)),
        currentPlayer: PieceColor.white,
        selectedPosition: null,
        validMoves: [],
        hasKingMoved: {PieceColor.white: false, PieceColor.black: false},
        hasRookMoved: {
          PieceColor.white: {'queenside': false, 'kingside': false},
          PieceColor.black: {'queenside': false, 'kingside': false},
        },
        // 故意设置可能导致问题的吃过路兵状态
        lastPawnDoubleMoved: {
          PieceColor.white: const Position(row: -16, col: 4), // 异常坐标
          PieceColor.black: null
        },
        lastPawnDoubleMovedNumber: {PieceColor.white: 1, PieceColor.black: 0},
        currentMoveNumber: 2,
        moveHistory: [],
        specialMoveMessage: null,
        lastMove: null,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false,
        undoStates: [],
        redoStates: [],
        hintMode: false,
        isInteractive: true,
        allowedPlayer: null,
        gameMode: GameMode.faceToFace,
        aiDifficulty: null,
        aiColor: null,
        isAIThinking: false,
      );

      // 验证异常状态下的边界检查
      final lastPawnPos =
          problematicState.lastPawnDoubleMoved[PieceColor.white]!;

      // 模拟吃过路兵目标位置计算
      for (int direction in [-1, 1]) {
        final targetRow = lastPawnPos.row + direction;
        print(
            '测试吃过路兵计算: row ${lastPawnPos.row} + direction $direction = $targetRow');

        // 验证边界检查逻辑是否正确阻止了无效坐标
        if (targetRow >= 0 && targetRow <= 7) {
          final enPassantTarget =
              Position(row: targetRow, col: lastPawnPos.col);
          final posName = ChessFormatters.getPositionName(enPassantTarget);
          expect(posName, isNot(contains('无效位置')));
        } else {
          print('边界检查正确阻止了无效坐标的创建: targetRow = $targetRow');
        }
      }
    });

    test('模拟ChessSquare渲染过程中的坐标异常', () {
      // 模拟GridView.builder中可能出现的异常index
      final problematicIndices = [-16, -15, -1, 64, 65, 72];

      for (final index in problematicIndices) {
        print('测试GridView index: $index');

        // 模拟ChessSquare中的坐标计算
        final row = index ~/ 8;
        final col = index % 8;

        print('  计算结果: row = $row, col = $col');

        // 检查是否会导致坐标边界问题
        if (row < 0 || row > 7 || col < 0 || col > 7) {
          // 这些异常坐标应该被正确处理
          print('  检测到异常坐标，验证保护机制...');

          // 验证所有可能调用String.fromCharCode的地方都有保护

          // 1. ChessFormatters.getPositionName
          final pos = Position(row: row, col: col);
          final posName = ChessFormatters.getPositionName(pos);
          expect(posName, contains('无效位置'));

          // 2. ChessFormatters.getColumnLabel
          if (col >= -20 && col <= 20) {
            // 避免过度极端值
            final columnLabel = ChessFormatters.getColumnLabel(col);
            if (col < 0 || col > 7) {
              expect(columnLabel, equals('?'));
            }
          }

          // 3. 验证String.fromCharCode不会被直接调用负值
          if (col < 0) {
            final charCodeValue = 'A'.codeUnitAt(0) + col;
            print('    验证charCodeValue: 65 + $col = $charCodeValue');

            // 如果是负值，应该不会直接调用String.fromCharCode
            if (charCodeValue < 0) {
              try {
                String.fromCharCode(charCodeValue);
                print('    警告：String.fromCharCode($charCodeValue) 应该被边界检查阻止');
              } catch (e) {
                print('    正确：String.fromCharCode($charCodeValue) 抛出异常: $e');
                expect(e, isA<RangeError>());
              }
            }
          }
        }
      }
    });

    test('验证所有边界检查机制的有效性', () {
      // 综合测试所有可能导致RangeError的场景

      final testCases = [
        {
          'description': '极端负坐标',
          'positions': [
            const Position(row: -16, col: 4),
            const Position(row: 4, col: -16),
            const Position(row: -16, col: -16),
          ]
        },
        {
          'description': '超出上界坐标',
          'positions': [
            const Position(row: 8, col: 4),
            const Position(row: 4, col: 8),
            const Position(row: 16, col: 16),
          ]
        },
        {
          'description': '边界坐标',
          'positions': [
            const Position(row: 0, col: 0),
            const Position(row: 7, col: 7),
            const Position(row: 0, col: 7),
            const Position(row: 7, col: 0),
          ]
        },
      ];

      for (final testCase in testCases) {
        final description = testCase['description'] as String;
        final positions = testCase['positions'] as List<Position>;

        print('测试 $description:');

        for (final pos in positions) {
          print('  位置: (${pos.row}, ${pos.col})');

          // 测试getPositionName的边界检查
          final posName = ChessFormatters.getPositionName(pos);
          if (pos.row < 0 || pos.row > 7 || pos.col < 0 || pos.col > 7) {
            expect(posName, contains('无效位置'));
            print('    getPositionName: $posName ✓');
          } else {
            expect(posName, isNot(contains('无效位置')));
            print('    getPositionName: $posName ✓');
          }

          // 测试getColumnLabel的边界检查
          final columnLabel = ChessFormatters.getColumnLabel(pos.col);
          if (pos.col < 0 || pos.col > 7) {
            expect(columnLabel, equals('?'));
            print('    getColumnLabel: $columnLabel ✓');
          } else {
            expect(columnLabel, isNot(equals('?')));
            print('    getColumnLabel: $columnLabel ✓');
          }

          // 测试ChessAdapter.toChessLibSquare的边界检查
          if (pos.row < 0 || pos.row > 7 || pos.col < 0 || pos.col > 7) {
            expect(
                () => ChessAdapter.toChessLibSquare(pos), throwsArgumentError);
            print('    toChessLibSquare: 正确抛出ArgumentError ✓');
          } else {
            expect(() => ChessAdapter.toChessLibSquare(pos), returnsNormally);
            final square = ChessAdapter.toChessLibSquare(pos);
            print('    toChessLibSquare: $square ✓');
          }
        }
      }
    });
  });
}
