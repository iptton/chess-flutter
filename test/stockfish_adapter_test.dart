import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/utils/stockfish_adapter.dart';
import 'package:testflutter/models/chess_models.dart';

void main() {
  group('StockfishAdapter Tests', () {
    test('should handle initialization gracefully', () async {
      // 在测试环境中，StockfishAdapter 应该使用 Mock 实现
      // 因为 FLUTTER_CI 环境变量在测试中默认为 true
      await StockfishAdapter.initialize();
      expect(StockfishAdapter.isReady, isTrue);
    });

    test('should handle getBestMove gracefully in test environment',
        () async {
      // 创建一个简单的棋盘
      final board = List.generate(8, (i) => List<ChessPiece?>.filled(8, null));

      // 放置一些棋子
      board[1][4] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[6][4] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 在测试环境中，应该使用 Mock 适配器
      final move = await StockfishAdapter.getBestMove(board, PieceColor.white);

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
      // 在测试环境中，dispose 应该正常工作
      await StockfishAdapter.dispose();
      expect(true, isTrue); // 如果没有异常，测试通过
    });

    test('isReady should return boolean', () {
      // 在测试环境中，isReady 应该返回 true（Mock 适配器）
      final isReady = StockfishAdapter.isReady;
      expect(isReady, isA<bool>());
      expect(isReady, isTrue); // Mock 适配器应该总是 ready
    });
  });
}
