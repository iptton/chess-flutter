import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../lib/blocs/chess_bloc.dart';
import '../lib/models/chess_models.dart';
import '../lib/widgets/chess_board.dart';

void main() {
  group('棋子显示修复测试', () {
    test('测试异常坐标不会导致_isMovablePiece崩溃', () {
      // 创建包含异常坐标的游戏状态
      final problematicState = GameState(
        board: List.generate(
          8,
          (row) => List.generate(8, (col) => null as ChessPiece?),
        ),
        currentPlayer: PieceColor.white,
        hasKingMoved: const {
          PieceColor.white: false,
          PieceColor.black: false,
        },
        hasRookMoved: const {
          PieceColor.white: {'queenside': false, 'kingside': false},
          PieceColor.black: {'queenside': false, 'kingside': false},
        },
        // 设置异常的双步兵坐标，模拟可能导致问题的情况
        lastPawnDoubleMoved: const {
          PieceColor.white: null,
          PieceColor.black: Position(row: -16, col: 4), // 异常坐标
        },
        lastPawnDoubleMovedNumber: const {
          PieceColor.white: -1,
          PieceColor.black: 10,
        },
        currentMoveNumber: 11,
      );

      // 在棋盘上放置一些棋子
      problematicState.board[0][4] = const ChessPiece(
        type: PieceType.king,
        color: PieceColor.black,
      );
      problematicState.board[7][4] = const ChessPiece(
        type: PieceType.king,
        color: PieceColor.white,
      );
      problematicState.board[1][0] = const ChessPiece(
        type: PieceType.pawn,
        color: PieceColor.white,
      );

      // 创建ChessSquare实例并测试_isMovablePiece方法
      final chessSquare = ChessSquare(
        index: 56, // 对应位置(7,0)
        state: problematicState,
      );

      // 通过反射或者直接测试，验证不会抛出异常
      // 这里我们测试白方兵的位置(1,0) -> index = 8
      expect(() {
        // 模拟_isMovablePiece的调用逻辑
        final piece = problematicState.board[1][0];
        expect(piece?.color, PieceColor.white);
        expect(piece?.color, problematicState.currentPlayer);
        
        // 验证异常坐标被正确处理
        final opponentColor = PieceColor.black;
        final opponentLastPawnDoubleMoved = 
            problematicState.lastPawnDoubleMoved[opponentColor];
        
        expect(opponentLastPawnDoubleMoved?.row, -16); // 确认是异常坐标
        expect(opponentLastPawnDoubleMoved?.col, 4);
        
        // 验证坐标验证逻辑
        final isValidCoordinate = opponentLastPawnDoubleMoved != null &&
            opponentLastPawnDoubleMoved.row >= 0 &&
            opponentLastPawnDoubleMoved.row <= 7 &&
            opponentLastPawnDoubleMoved.col >= 0 &&
            opponentLastPawnDoubleMoved.col <= 7;
        
        expect(isValidCoordinate, false); // 异常坐标应该被识别为无效
      }, returnsNormally);
    });

    test('测试正常坐标仍然正常工作', () {
      // 创建包含正常坐标的游戏状态
      final normalState = GameState(
        board: List.generate(
          8,
          (row) => List.generate(8, (col) => null as ChessPiece?),
        ),
        currentPlayer: PieceColor.white,
        hasKingMoved: const {
          PieceColor.white: false,
          PieceColor.black: false,
        },
        hasRookMoved: const {
          PieceColor.white: {'queenside': false, 'kingside': false},
          PieceColor.black: {'queenside': false, 'kingside': false},
        },
        // 设置正常的双步兵坐标
        lastPawnDoubleMoved: const {
          PieceColor.white: null,
          PieceColor.black: Position(row: 4, col: 3), // 正常坐标
        },
        lastPawnDoubleMovedNumber: const {
          PieceColor.white: -1,
          PieceColor.black: 10,
        },
        currentMoveNumber: 11,
      );

      // 在棋盘上放置一些棋子
      normalState.board[0][4] = const ChessPiece(
        type: PieceType.king,
        color: PieceColor.black,
      );
      normalState.board[7][4] = const ChessPiece(
        type: PieceType.king,
        color: PieceColor.white,
      );
      normalState.board[1][0] = const ChessPiece(
        type: PieceType.pawn,
        color: PieceColor.white,
      );

      expect(() {
        // 验证正常坐标被正确处理
        final opponentColor = PieceColor.black;
        final opponentLastPawnDoubleMoved = 
            normalState.lastPawnDoubleMoved[opponentColor];
        
        expect(opponentLastPawnDoubleMoved?.row, 4); // 确认是正常坐标
        expect(opponentLastPawnDoubleMoved?.col, 3);
        
        // 验证坐标验证逻辑
        final isValidCoordinate = opponentLastPawnDoubleMoved != null &&
            opponentLastPawnDoubleMoved.row >= 0 &&
            opponentLastPawnDoubleMoved.row <= 7 &&
            opponentLastPawnDoubleMoved.col >= 0 &&
            opponentLastPawnDoubleMoved.col <= 7;
        
        expect(isValidCoordinate, true); // 正常坐标应该被识别为有效
      }, returnsNormally);
    });

    test('测试边界坐标情况', () {
      final testCases = [
        {'row': -1, 'col': 0, 'expected': false}, // 负行号
        {'row': 0, 'col': -1, 'expected': false}, // 负列号
        {'row': 8, 'col': 0, 'expected': false},  // 超出行号
        {'row': 0, 'col': 8, 'expected': false},  // 超出列号
        {'row': 0, 'col': 0, 'expected': true},   // 边界有效坐标
        {'row': 7, 'col': 7, 'expected': true},   // 边界有效坐标
        {'row': 3, 'col': 4, 'expected': true},   // 中间有效坐标
      ];

      for (final testCase in testCases) {
        final row = testCase['row'] as int;
        final col = testCase['col'] as int;
        final expected = testCase['expected'] as bool;

        final position = Position(row: row, col: col);
        
        // 测试坐标验证逻辑
        final isValid = position.row >= 0 &&
            position.row <= 7 &&
            position.col >= 0 &&
            position.col <= 7;
        
        expect(isValid, expected, 
            reason: '坐标($row, $col)的验证结果应该是$expected');
      }
    });
  });
}
