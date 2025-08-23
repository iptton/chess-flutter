import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/utils/stockfish_adapter_mock.dart';
import 'package:testflutter/models/chess_models.dart';

void main() {
  group('StockfishMockAdapter Tests', () {
    test('should handle initialization gracefully', () async {
      // 直接测试 Mock 适配器的初始化
      await StockfishMockAdapter.initialize();
      expect(StockfishMockAdapter.isReady, isTrue);
    });

    test('should handle getBestMove gracefully', () async {
      // 创建一个简单的棋盘
      final board = List.generate(8, (i) => List<ChessPiece?>.filled(8, null));

      // 放置一些棋子
      board[1][4] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[6][4] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 测试 Mock 适配器的 getBestMove 方法
      final move =
          await StockfishMockAdapter.getBestMove(board, PieceColor.white);

      // Mock 适配器应该返回一个有效的移动或 null
      expect(move == null || move is ChessMove, isTrue);

      if (move != null) {
        expect(move.piece.color, PieceColor.white);
        expect(move.from.row >= 0 && move.from.row <= 7, isTrue);
        expect(move.from.col >= 0 && move.from.col <= 7, isTrue);
        expect(move.to.row >= 0 && move.to.row <= 7, isTrue);
        expect(move.to.col >= 0 && move.to.col <= 7, isTrue);
      }
    });

    test('should handle dispose gracefully', () async {
      // 测试 Mock 适配器的 dispose 方法
      await StockfishMockAdapter.dispose();
      expect(true, isTrue); // 如果没有异常，测试通过

      // 验证 dispose 后的状态
      expect(StockfishMockAdapter.isReady, isFalse);
    });

    test('isReady should return boolean', () async {
      // 重新初始化以确保正确的状态
      await StockfishMockAdapter.initialize();

      // 测试 isReady 属性
      final isReady = StockfishMockAdapter.isReady;
      expect(isReady, isA<bool>());
      expect(isReady, isTrue); // Mock 适配器初始化后应该 ready
    });

    test('should return valid moves for different board positions', () async {
      // 测试不同棋盘位置的移动生成
      final board = List.generate(8, (i) => List<ChessPiece?>.filled(8, null));

      // 测试场景1：白兵可以向前移动
      board[6][3] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

      final move1 =
          await StockfishMockAdapter.getBestMove(board, PieceColor.white);
      expect(move1, isNotNull);
      expect(move1!.piece.type, PieceType.pawn);
      expect(move1.piece.color, PieceColor.white);

      // 清理棋盘
      board[6][3] = null;

      // 测试场景2：黑兵可以向前移动
      board[1][3] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      final move2 =
          await StockfishMockAdapter.getBestMove(board, PieceColor.black);
      expect(move2, isNotNull);
      expect(move2!.piece.type, PieceType.pawn);
      expect(move2.piece.color, PieceColor.black);
    });

    test('should handle empty board gracefully', () async {
      // 测试空棋盘情况
      final emptyBoard =
          List.generate(8, (i) => List<ChessPiece?>.filled(8, null));

      final move =
          await StockfishMockAdapter.getBestMove(emptyBoard, PieceColor.white);
      expect(move, isNull); // 空棋盘应该返回 null
    });
  });
}
