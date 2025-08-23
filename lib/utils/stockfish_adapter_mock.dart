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
          // 尝试一个简单的移动（向前一步，如果是兵）
          if (piece!.type == PieceType.pawn) {
            final direction = aiColor == PieceColor.white ? -1 : 1;
            final newRow = row + direction;
            
            if (newRow >= 0 && newRow < 8 && board[newRow][col] == null) {
              print('StockfishMockAdapter: 返回 Mock 移动: ($row,$col) -> ($newRow,$col)');
              return ChessMove(
                from: Position(row: row, col: col),
                to: Position(row: newRow, col: col),
                piece: piece,
                capturedPiece: null,
                isPromotion: false,
                isEnPassant: false,
                isCastling: false,
                promotionPiece: null,
              );
            }
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
