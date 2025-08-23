import '../models/chess_models.dart';

/// Stockfish引擎适配器的抽象接口
/// 定义了跨平台的统一API
abstract class StockfishAdapterInterface {
  /// 初始化Stockfish引擎
  static Future<void> initialize() async {
    throw UnimplementedError(
        'initialize() must be implemented by platform-specific adapter');
  }

  /// 获取AI的最佳移动
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
    throw UnimplementedError(
        'getBestMove() must be implemented by platform-specific adapter');
  }

  /// 释放资源
  static Future<void> dispose() async {
    throw UnimplementedError(
        'dispose() must be implemented by platform-specific adapter');
  }

  /// 检查引擎是否准备就绪
  static bool get isReady {
    throw UnimplementedError(
        'isReady getter must be implemented by platform-specific adapter');
  }
}
