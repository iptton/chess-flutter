import 'dart:async';
import '../models/chess_models.dart';

/// Mock Stockfish 适配器，用于 CI 环境
/// 提供基本的接口实现，但不包含实际的 AI 逻辑
class StockfishMockAdapter {
  static bool _isInitialized = false;

  /// 初始化 Mock Stockfish 引擎
  static Future<void> initialize() async {
    print('StockfishMockAdapter: 初始化 Mock 引擎...');
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
    print('StockfishMockAdapter: Mock 引擎初始化完成');
  }

  /// 获取 Mock AI 的最佳移动
  /// 返回一个简单的随机移动或 null
  static Future<ChessMove?> getBestMove(
    List<List<ChessPiece?>> board,
    PieceColor aiColor, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
    int halfMoveClock = 0,
    int fullMoveNumber = 1,
    int thinkingTimeMs = 1000,
  }) async {
    print('StockfishMockAdapter: 获取最佳移动 (Mock)...');

    if (!_isInitialized) {
      await initialize();
    }

    // 模拟思考时间
    await Future.delayed(Duration(milliseconds: thinkingTimeMs ~/ 10));

    // 查找第一个可能的移动作为 Mock 返回
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece?.color == aiColor) {
          // 尝试不同类型棋子的移动
          switch (piece!.type) {
            case PieceType.pawn:
              // 兵的移动
              final direction = aiColor == PieceColor.white ? -1 : 1;
              final newRow = row + direction;

              if (newRow >= 0 && newRow < 8 && board[newRow][col] == null) {
                print(
                    'StockfishMockAdapter: 返回兵移动: ($row,$col) -> ($newRow,$col)');
                return ChessMove(
                  from: Position(row: row, col: col),
                  to: Position(row: newRow, col: col),
                  piece: piece,
                  capturedPiece: null,
                  isPromotion: false,
                  isEnPassant: false,
                  isCastling: false,
                  promotionType: null,
                );
              }
              break;

            case PieceType.queen:
            case PieceType.rook:
            case PieceType.bishop:
            case PieceType.knight:
            case PieceType.king:
              // 其他棋子的基本移动
              final directions = _getMoveDirections(piece.type);
              for (final direction in directions) {
                final newRow = row + direction[0];
                final newCol = col + direction[1];

                if (newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8) {
                  final targetPiece = board[newRow][newCol];
                  if (targetPiece == null || targetPiece.color != aiColor) {
                    print(
                        'StockfishMockAdapter: 返回${piece.type}移动: ($row,$col) -> ($newRow,$newCol)');
                    return ChessMove(
                      from: Position(row: row, col: col),
                      to: Position(row: newRow, col: newCol),
                      piece: piece,
                      capturedPiece: targetPiece,
                      isPromotion: false,
                      isEnPassant: false,
                      isCastling: false,
                      promotionType: null,
                    );
                  }
                }
              }
              break;
          }
        }
      }
    }

    print('StockfishMockAdapter: 未找到有效移动，返回 null');
    return null;
  }

  /// 释放 Mock 资源
  static Future<void> dispose() async {
    print('StockfishMockAdapter: 释放 Mock 引擎资源...');
    _isInitialized = false;
    await Future.delayed(const Duration(milliseconds: 50));
    print('StockfishMockAdapter: Mock 引擎资源已释放');
  }

  /// 检查 Mock 引擎是否准备就绪
  static bool get isReady => _isInitialized;

  /// 获取棋子的基本移动方向
  static List<List<int>> _getMoveDirections(PieceType type) {
    switch (type) {
      case PieceType.king:
        return [
          [-1, -1],
          [-1, 0],
          [-1, 1],
          [0, -1],
          [0, 1],
          [1, -1],
          [1, 0],
          [1, 1]
        ];
      case PieceType.queen:
        return [
          [-1, -1],
          [-1, 0],
          [-1, 1],
          [0, -1],
          [0, 1],
          [1, -1],
          [1, 0],
          [1, 1]
        ];
      case PieceType.rook:
        return [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1]
        ];
      case PieceType.bishop:
        return [
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1]
        ];
      case PieceType.knight:
        return [
          [-2, -1],
          [-2, 1],
          [-1, -2],
          [-1, 2],
          [1, -2],
          [1, 2],
          [2, -1],
          [2, 1]
        ];
      case PieceType.pawn:
        return []; // 兵的移动已经在上面单独处理
    }
  }
}

// 导出平台特定的API (Mock 版本)
Future<void> initialize() => StockfishMockAdapter.initialize();
Future<ChessMove?> getBestMove(
  List<List<ChessPiece?>> board,
  PieceColor aiColor, {
  Map<PieceColor, bool>? hasKingMoved,
  Map<PieceColor, Map<String, bool>>? hasRookMoved,
  Position? enPassantTarget,
  int halfMoveClock = 0,
  int fullMoveNumber = 1,
  int thinkingTimeMs = 1000,
}) =>
    StockfishMockAdapter.getBestMove(
      board,
      aiColor,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
      thinkingTimeMs: thinkingTimeMs,
    );
Future<void> dispose() => StockfishMockAdapter.dispose();
bool get isReady => StockfishMockAdapter.isReady;
