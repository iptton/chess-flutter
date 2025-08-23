import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chess_models.dart';
import 'stockfish_adapter_interface.dart';

// 平台特定的导入
import 'stockfish_adapter_mobile.dart'
    if (dart.library.js) 'stockfish_adapter_web.dart' as platform;

/// 跨平台Stockfish引擎适配器
/// 根据运行平台自动选择合适的实现
class StockfishAdapter {
  /// 初始化Stockfish引擎
  static Future<void> initialize() async {
    return platform.initialize();
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
    return platform.getBestMove(
      board,
      aiColor,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
      thinkingTimeMs: thinkingTimeMs,
    );
  }

  /// 释放资源
  static Future<void> dispose() async {
    return platform.dispose();
  }

  /// 检查引擎是否准备就绪
  static bool get isReady => platform.isReady;
}
