import 'dart:math';
import '../models/chess_models.dart';
import '../utils/chess_adapter.dart';
import '../utils/stockfish_adapter.dart';

/// AI难度等级
enum AIDifficulty {
  easy, // 简单：思考时间短，有随机性
  medium, // 中等：中等思考时间
  hard, // 困难：长思考时间，使用Stockfish最佳移动
}

/// 简单的国际象棋AI引擎
class ChessAI {
  final AIDifficulty difficulty;
  final Random _random = Random();

  ChessAI({required this.difficulty});

  /// 获取AI的最佳移动
  Future<ChessMove?> getBestMove(
    List<List<ChessPiece?>> board,
    PieceColor aiColor, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
    int halfMoveClock = 0,
    int fullMoveNumber = 1,
  }) async {
    try {
      // 根据难度设置思考时间
      int thinkingTimeMs;
      switch (difficulty) {
        case AIDifficulty.easy:
          thinkingTimeMs = 500; // 0.5秒
          break;
        case AIDifficulty.medium:
          thinkingTimeMs = 1500; // 1.5秒
          break;
        case AIDifficulty.hard:
          thinkingTimeMs = 3000; // 3秒
          break;
      }

      print('ChessAI: 开始计算最佳移动, 难度=$difficulty, 思考时间=${thinkingTimeMs}ms');

      // 使用Stockfish获取最佳移动
      final bestMove = await StockfishAdapter.getBestMove(
        board,
        aiColor,
        hasKingMoved: hasKingMoved,
        hasRookMoved: hasRookMoved,
        enPassantTarget: enPassantTarget,
        halfMoveClock: halfMoveClock,
        fullMoveNumber: fullMoveNumber,
        thinkingTimeMs: thinkingTimeMs,
      );

      print('ChessAI: Stockfish返回结果: $bestMove');

      // 对于简单难度，添加一些随机性
      if (difficulty == AIDifficulty.easy && bestMove != null) {
        return _addRandomnessToMove(board, aiColor, bestMove,
            hasKingMoved: hasKingMoved,
            hasRookMoved: hasRookMoved,
            enPassantTarget: enPassantTarget);
      }

      return bestMove;
    } catch (e) {
      print('ChessAI: AI移动计算错误: $e');
      // 如果Stockfish失败，回退到随机移动
      print('ChessAI: 回退到随机移动');
      return _getRandomMove(board, aiColor,
          hasKingMoved: hasKingMoved,
          hasRookMoved: hasRookMoved,
          enPassantTarget: enPassantTarget);
    }
  }

  /// 为简单难度添加随机性
  ChessMove? _addRandomnessToMove(
    List<List<ChessPiece?>> board,
    PieceColor aiColor,
    ChessMove bestMove, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    // 20% 概率选择随机移动而不是最佳移动
    if (_random.nextDouble() < 0.2) {
      return _getRandomMove(board, aiColor,
          hasKingMoved: hasKingMoved,
          hasRookMoved: hasRookMoved,
          enPassantTarget: enPassantTarget);
    }
    return bestMove;
  }

  /// 获取随机移动作为回退方案
  ChessMove? _getRandomMove(
    List<List<ChessPiece?>> board,
    PieceColor aiColor, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    try {
      final allMoves = ChessAdapter.getLegalMoves(
        board,
        aiColor,
        hasKingMoved: hasKingMoved,
        hasRookMoved: hasRookMoved,
        enPassantTarget: enPassantTarget,
      );

      if (allMoves.isEmpty) return null;

      return allMoves[_random.nextInt(allMoves.length)];
    } catch (e) {
      print('Error getting random move: $e');
      return null;
    }
  }
}
