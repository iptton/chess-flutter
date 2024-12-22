import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/utils/chess_rules.dart';

void main() {
  group('En Passant Tests', () {
    late List<List<ChessPiece?>> board;

    setUp(() {
      // 创建一个空棋盘
      board = List.generate(
        8,
        (i) => List.generate(8, (j) => null),
      );
    });

    test('should allow en passant capture after pawn double move', () {
      // 设置初始位置：
      // 白方兵在 (3, 4)，即 e5
      // 黑方兵在起始位置 (1, 3)，即 d7
      board[3][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      
      // 模拟黑方兵双步移动到 d5
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      
      // 获取白方兵的有效移动
      final validMoves = ChessRules.getValidMoves(
        board,
        Position(row: 3, col: 4), // 白方兵的位置 e5
        lastPawnDoubleMoved: Position(row: 3, col: 3), // 黑方兵的位置 d5
        lastPawnDoubleMovedNumber: 0,
        currentMoveNumber: 1,
      );

      // 期望吃过路兵位置：(2, 3)，即 d6
      final expectedEnPassantMove = Position(row: 2, col: 3);

      // 验证可以吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isTrue,
        reason: '白方兵应该可以吃过路兵',
      );
    });

    test('should not allow en passant capture after other moves', () {
      // 设置相同的初始位置
      board[3][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 获取白方兵的有效移动，但不是在黑方兵刚移动两步后
      final validMoves = ChessRules.getValidMoves(
        board,
        Position(row: 3, col: 4),
        lastPawnDoubleMoved: Position(row: 3, col: 3),
        lastPawnDoubleMovedNumber: 0,
        currentMoveNumber: 2, // 已经过了一步
      );

      // 期望的吃过路兵位置
      final expectedEnPassantMove = Position(row: 2, col: 3);

      // 验证不能吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '不应���允许延迟的吃过路兵',
      );
    });

    test('should not allow en passant capture if pawn has not just moved', () {
      // 设置初始位置
      board[3][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 获取白方兵的有效移动，但没有最近的双步移动记录
      final validMoves = ChessRules.getValidMoves(
        board,
        Position(row: 3, col: 4),
        lastPawnDoubleMoved: null,
        lastPawnDoubleMovedNumber: -1,
        currentMoveNumber: 1,
      );

      // 期望的吃过路兵位置
      final expectedEnPassantMove = Position(row: 2, col: 3);

      // 验证不能吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '没有最近的双步移动记录时不应该允许吃过路兵',
      );
    });

    test('should only allow en passant capture by pawns', () {
      // 设置初始位置，但使用车而不是兵
      board[3][4] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 获取白方车的有效移动
      final validMoves = ChessRules.getValidMoves(
        board,
        Position(row: 3, col: 4),
        lastPawnDoubleMoved: Position(row: 3, col: 3),
        lastPawnDoubleMovedNumber: 0,
        currentMoveNumber: 1,
      );

      // 期望的吃过路兵位置
      final expectedEnPassantMove = Position(row: 2, col: 3);

      // 验证不能吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '非兵不应该能够吃过路兵',
      );
    });

    test('should only allow en passant capture immediately after double move', () {
      // 设置初始位置
      board[3][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 获取白方兵的有效移动，但在双步移动后等待了一步
      final validMoves = ChessRules.getValidMoves(
        board,
        Position(row: 3, col: 4),
        lastPawnDoubleMoved: Position(row: 3, col: 3),
        lastPawnDoubleMovedNumber: 0,
        currentMoveNumber: 3, // 已经过了两步
      );

      // 期望的吃过路兵位置
      final expectedEnPassantMove = Position(row: 2, col: 3);

      // 验证不能吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '不应该允许在双步移动后的第二步吃过路兵',
      );
    });
  });
} 