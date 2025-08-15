import 'dart:math';
import 'package:chess/chess.dart' as chess_lib;
import '../models/chess_models.dart';
import '../utils/chess_adapter.dart';

/// AI难度等级
enum AIDifficulty {
  easy,    // 简单：深度1，随机性高
  medium,  // 中等：深度2-3，一些随机性
  hard,    // 困难：深度3-4，很少随机性
}

/// 简单的国际象棋AI引擎
class ChessAI {
  final AIDifficulty difficulty;
  final Random _random = Random();
  
  // 棋子价值表
  static final Map<chess_lib.PieceType, int> _pieceValues = {
    chess_lib.Chess.PAWN: 100,
    chess_lib.Chess.KNIGHT: 320,
    chess_lib.Chess.BISHOP: 330,
    chess_lib.Chess.ROOK: 500,
    chess_lib.Chess.QUEEN: 900,
    chess_lib.Chess.KING: 20000,
  };

  // 位置价值表 - 兵
  static const List<List<int>> _pawnTable = [
    [0,  0,  0,  0,  0,  0,  0,  0],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [5,  5, 10, 25, 25, 10,  5,  5],
    [0,  0,  0, 20, 20,  0,  0,  0],
    [5, -5,-10,  0,  0,-10, -5,  5],
    [5, 10, 10,-20,-20, 10, 10,  5],
    [0,  0,  0,  0,  0,  0,  0,  0]
  ];

  // 位置价值表 - 马
  static const List<List<int>> _knightTable = [
    [-50,-40,-30,-30,-30,-30,-40,-50],
    [-40,-20,  0,  0,  0,  0,-20,-40],
    [-30,  0, 10, 15, 15, 10,  0,-30],
    [-30,  5, 15, 20, 20, 15,  5,-30],
    [-30,  0, 15, 20, 20, 15,  0,-30],
    [-30,  5, 10, 15, 15, 10,  5,-30],
    [-40,-20,  0,  5,  5,  0,-20,-40],
    [-50,-40,-30,-30,-30,-30,-40,-50],
  ];

  // 位置价值表 - 象
  static const List<List<int>> _bishopTable = [
    [-20,-10,-10,-10,-10,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5, 10, 10,  5,  0,-10],
    [-10,  5,  5, 10, 10,  5,  5,-10],
    [-10,  0, 10, 10, 10, 10,  0,-10],
    [-10, 10, 10, 10, 10, 10, 10,-10],
    [-10,  5,  0,  0,  0,  0,  5,-10],
    [-20,-10,-10,-10,-10,-10,-10,-20],
  ];

  // 位置价值表 - 车
  static const List<List<int>> _rookTable = [
    [0,  0,  0,  0,  0,  0,  0,  0],
    [5, 10, 10, 10, 10, 10, 10,  5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [0,  0,  0,  5,  5,  0,  0,  0]
  ];

  // 位置价值表 - 后
  static const List<List<int>> _queenTable = [
    [-20,-10,-10, -5, -5,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5,  5,  5,  5,  0,-10],
    [-5,  0,  5,  5,  5,  5,  0, -5],
    [0,  0,  5,  5,  5,  5,  0, -5],
    [-10,  5,  5,  5,  5,  5,  0,-10],
    [-10,  0,  5,  0,  0,  0,  0,-10],
    [-20,-10,-10, -5, -5,-10,-10,-20]
  ];

  // 位置价值表 - 王（中局）
  static const List<List<int>> _kingMiddleGameTable = [
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-20,-30,-30,-40,-40,-30,-30,-20],
    [-10,-20,-20,-20,-20,-20,-20,-10],
    [20, 20,  0,  0,  0,  0, 20, 20],
    [20, 30, 10,  0,  0, 10, 30, 20]
  ];

  ChessAI({this.difficulty = AIDifficulty.medium});

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
    final chess = ChessAdapter.createChessFromBoard(
      board,
      aiColor,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
    );

    if (chess.game_over) return null;

    final moves = chess.generate_moves();
    if (moves.isEmpty) return null;

    chess_lib.Move? bestMove;
    
    switch (difficulty) {
      case AIDifficulty.easy:
        bestMove = _getEasyMove(chess, moves);
        break;
      case AIDifficulty.medium:
        bestMove = _getMediumMove(chess, moves);
        break;
      case AIDifficulty.hard:
        bestMove = _getHardMove(chess, moves);
        break;
    }

    if (bestMove == null) return null;

    return ChessAdapter.fromChessLibMove(bestMove, chess);
  }

  /// 简单难度：使用浅层搜索，带较多随机性
  chess_lib.Move _getEasyMove(chess_lib.Chess chess, List<chess_lib.Move> moves) {
    final result = _minimax(chess, 2, true, double.negativeInfinity, double.infinity);

    // 20% 概率选择次优移动增加变化
    if (_random.nextDouble() < 0.2 && moves.length > 1) {
      // 获取前几个较好的移动
      final evaluatedMoves = <_EvaluatedMove>[];
      for (final move in moves.take(10)) { // 只评估前10个移动以节省时间
        chess.make_move(move);
        final score = _evaluatePosition(chess);
        chess.undo_move();
        evaluatedMoves.add(_EvaluatedMove(move, score));
      }

      // 按分数排序
      evaluatedMoves.sort((a, b) => b.score.compareTo(a.score));

      // 从前3个移动中随机选择
      final topMoves = evaluatedMoves.take(3).toList();
      return topMoves[_random.nextInt(topMoves.length)].move;
    }

    return result.move!;
  }

  /// 中等难度：使用中等深度搜索
  chess_lib.Move _getMediumMove(chess_lib.Chess chess, List<chess_lib.Move> moves) {
    final result = _minimax(chess, 3, true, double.negativeInfinity, double.infinity);
    return result.move!;
  }

  /// 困难难度：使用较深搜索
  chess_lib.Move _getHardMove(chess_lib.Chess chess, List<chess_lib.Move> moves) {
    final depth = moves.length > 35 ? 4 : 5; // 根据移动数量调整深度
    final result = _minimax(chess, depth, true, double.negativeInfinity, double.infinity);
    return result.move!;
  }

  /// Minimax算法实现
  _MinimaxResult _minimax(
    chess_lib.Chess chess,
    int depth,
    bool maximizingPlayer,
    double alpha,
    double beta,
  ) {
    if (depth == 0 || chess.game_over) {
      return _MinimaxResult(_evaluatePosition(chess), null);
    }

    final moves = chess.generate_moves();
    chess_lib.Move? bestMove;

    if (maximizingPlayer) {
      double maxEval = double.negativeInfinity;
      
      for (final move in moves) {
        chess.make_move(move);
        final eval = _minimax(chess, depth - 1, false, alpha, beta);
        chess.undo_move();

        if (eval.score > maxEval) {
          maxEval = eval.score;
          bestMove = move;
        }

        alpha = max(alpha, eval.score);
        if (beta <= alpha) break; // Alpha-beta剪枝
      }

      return _MinimaxResult(maxEval, bestMove);
    } else {
      double minEval = double.infinity;
      
      for (final move in moves) {
        chess.make_move(move);
        final eval = _minimax(chess, depth - 1, true, alpha, beta);
        chess.undo_move();

        if (eval.score < minEval) {
          minEval = eval.score;
          bestMove = move;
        }

        beta = min(beta, eval.score);
        if (beta <= alpha) break; // Alpha-beta剪枝
      }

      return _MinimaxResult(minEval, bestMove);
    }
  }

  /// 评估当前局面（从当前玩家的视角）
  double _evaluatePosition(chess_lib.Chess chess) {
    if (chess.in_checkmate) {
      return -9999; // 当前玩家被将死是最坏的结果
    }

    if (chess.in_stalemate || chess.in_draw) {
      return 0;
    }

    double score = 0;
    final currentPlayer = chess.turn;

    // 计算材料价值和位置价值
    for (int square = 0; square < 64; square++) {
      final piece = chess.board[square];
      if (piece != null) {
        final pieceValue = _getPieceValue(piece, square);
        // 从当前玩家视角评估：己方棋子为正，对方棋子为负
        if (piece.color == currentPlayer) {
          score += pieceValue;
        } else {
          score -= pieceValue;
        }
      }
    }

    // 移动能力评估
    final currentPlayerMoves = chess.generate_moves().length;
    final opponentMoves = _countMoves(chess, currentPlayer == chess_lib.Color.WHITE
        ? chess_lib.Color.BLACK
        : chess_lib.Color.WHITE);

    score += (currentPlayerMoves - opponentMoves) * 10;

    // 王的安全性
    if (chess.in_check) {
      score -= 50; // 被将军是不好的
    }

    // 控制中心的奖励
    score += _evaluateCenterControl(chess, currentPlayer);

    return score;
  }

  /// 获取棋子的价值（包括位置价值）
  double _getPieceValue(chess_lib.Piece piece, int square) {
    final baseValue = _pieceValues[piece.type] ?? 0;
    final row = chess_lib.Chess.rank(square);
    final col = chess_lib.Chess.file(square);
    
    // 对于黑方，翻转行坐标
    final tableRow = piece.color == chess_lib.Color.WHITE ? 7 - row : row;
    
    int positionValue = 0;
    
    switch (piece.type) {
      case chess_lib.Chess.PAWN:
        positionValue = _pawnTable[tableRow][col];
        break;
      case chess_lib.Chess.KNIGHT:
        positionValue = _knightTable[tableRow][col];
        break;
      case chess_lib.Chess.BISHOP:
        positionValue = _bishopTable[tableRow][col];
        break;
      case chess_lib.Chess.ROOK:
        positionValue = _rookTable[tableRow][col];
        break;
      case chess_lib.Chess.QUEEN:
        positionValue = _queenTable[tableRow][col];
        break;
      case chess_lib.Chess.KING:
        positionValue = _kingMiddleGameTable[tableRow][col];
        break;
    }

    return (baseValue + positionValue).toDouble();
  }

  /// 计算指定颜色的移动数量
  int _countMoves(chess_lib.Chess chess, chess_lib.Color color) {
    final originalTurn = chess.turn;
    chess.turn = color;
    final moveCount = chess.generate_moves().length;
    chess.turn = originalTurn;
    return moveCount;
  }

  /// 评估中心控制
  double _evaluateCenterControl(chess_lib.Chess chess, chess_lib.Color color) {
    double score = 0;

    // 中心四格：e4, e5, d4, d5
    final centerSquares = [28, 29, 36, 37]; // chess库中的方格编号

    for (final square in centerSquares) {
      final piece = chess.board[square];
      if (piece != null) {
        if (piece.color == color) {
          score += piece.type == chess_lib.Chess.PAWN ? 20 : 10;
        } else {
          score -= piece.type == chess_lib.Chess.PAWN ? 20 : 10;
        }
      }
    }

    return score;
  }
}

/// Minimax算法结果
class _MinimaxResult {
  final double score;
  final chess_lib.Move? move;

  _MinimaxResult(this.score, this.move);
}

/// 评估过的移动
class _EvaluatedMove {
  final chess_lib.Move move;
  final double score;

  _EvaluatedMove(this.move, this.score);
}
