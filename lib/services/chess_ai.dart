import 'dart:math';
import '../models/chess_models.dart';
import '../utils/chess_adapter.dart';
import '../utils/stockfish_adapter.dart';
import '../utils/ai_difficulty_strategy.dart';

/// 兼容性：保留原有的简化难度等级枚举
enum AIDifficulty {
  easy, // 简单：思考时间短，有随机性
  medium, // 中等：中等思考时间
  hard, // 困难：长思考时间，使用Stockfish最佳移动
}

/// 扩展方法：将旧的难度等级映射到新的系统
extension AIDifficultyExtension on AIDifficulty {
  AIDifficultyLevel toNewDifficultyLevel() {
    switch (this) {
      case AIDifficulty.easy:
        return AIDifficultyLevel.novice;
      case AIDifficulty.medium:
        return AIDifficultyLevel.intermediate;
      case AIDifficulty.hard:
        return AIDifficultyLevel.expert;
    }
  }
}

/// 增强的国际象棋AI引擎，支持智能难度分级
class ChessAI {
  final AIDifficulty difficulty;
  final AIDifficultyLevel advancedDifficulty;
  final DeviceType deviceType;
  final AIDifficultyConfig config;
  final Random _random = Random();

  /// 使用旧的难度系统（向后兼容）
  ChessAI({required this.difficulty})
      : advancedDifficulty = difficulty.toNewDifficultyLevel(),
        deviceType = AIDifficultyStrategy.getCurrentDeviceType(),
        config = AIDifficultyStrategy.getConfigForDifficulty(
          difficulty.toNewDifficultyLevel(),
          null,
        );

  /// 使用新的高级难度系统
  ChessAI.advanced({
    required this.advancedDifficulty,
    DeviceType? deviceType,
  })  : difficulty = _mapToOldDifficulty(advancedDifficulty),
        deviceType = deviceType ?? AIDifficultyStrategy.getCurrentDeviceType(),
        config = AIDifficultyStrategy.getConfigForDifficulty(
          advancedDifficulty,
          deviceType,
        );

  /// 将新难度等级映射回旧的枚举（用于兼容性）
  static AIDifficulty _mapToOldDifficulty(AIDifficultyLevel level) {
    if (level.level <= 3) return AIDifficulty.easy;
    if (level.level <= 6) return AIDifficulty.medium;
    return AIDifficulty.hard;
  }

  /// 获取AI的最佳移动（增强版本）
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
      print('ChessAI: 开始计算最佳移动');
      print(
          '  - 难度: ${advancedDifficulty.displayName} (${advancedDifficulty.name})');
      print('  - 设备类型: ${deviceType.name}');
      print('  - 思考时间: ${config.thinkingTimeMs}ms');
      print(
          '  - 随机性概率: ${(config.randomnessProbability * 100).toStringAsFixed(1)}%');
      print(
          '  - 搜索深度: ${config.searchDepth == 0 ? "无限制" : config.searchDepth}');
      print('  - 多线程: ${config.threads}');

      // 检查是否应该使用随机移动
      if (AIDifficultyStrategy.shouldUseRandomMove(
          config.randomnessProbability)) {
        print('ChessAI: 随机性触发，使用随机移动');
        final randomMove = _getRandomMove(board, aiColor,
            hasKingMoved: hasKingMoved,
            hasRookMoved: hasRookMoved,
            enPassantTarget: enPassantTarget);
        if (randomMove != null) {
          return randomMove;
        }
        print('ChessAI: 随机移动失败，回退到引擎计算');
      }

      // 使用Stockfish获取最佳移动
      final bestMove = await _getEngineMove(
        board,
        aiColor,
        hasKingMoved: hasKingMoved,
        hasRookMoved: hasRookMoved,
        enPassantTarget: enPassantTarget,
        halfMoveClock: halfMoveClock,
        fullMoveNumber: fullMoveNumber,
      );

      print('ChessAI: 引擎返回结果: $bestMove');
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

  /// 使用引擎计算最佳移动
  Future<ChessMove?> _getEngineMove(
    List<List<ChessPiece?>> board,
    PieceColor aiColor, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
    int halfMoveClock = 0,
    int fullMoveNumber = 1,
  }) async {
    // 根据配置调用Stockfish
    return await StockfishAdapter.getBestMove(
      board,
      aiColor,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
      thinkingTimeMs: config.thinkingTimeMs,
      // 在实际的Stockfish适配器中，可以考虑传递更多参数：
      // searchDepth: config.searchDepth,
      // threads: config.threads,
      // useOpeningBook: config.useOpeningBook,
    );
  }

  /// 获取智能随机移动（考虑难度等级的随机性）
  ChessMove? _getIntelligentRandomMove(
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

      // 根据难度等级选择移动策略
      switch (advancedDifficulty) {
        case AIDifficultyLevel.beginner:
          // 完全随机
          return allMoves[_random.nextInt(allMoves.length)];

        case AIDifficultyLevel.novice:
        case AIDifficultyLevel.casual:
          // 70% 随机，30% 选择吃子移动
          if (_random.nextDouble() < 0.7 || !_hasCaptureMoves(allMoves)) {
            return allMoves[_random.nextInt(allMoves.length)];
          }
          return _selectCapturingMove(allMoves) ??
              allMoves[_random.nextInt(allMoves.length)];

        default:
          // 高级难度的随机移动倾向于选择更好的移动
          return _selectReasonableMove(allMoves);
      }
    } catch (e) {
      print('Error getting intelligent random move: $e');
      return null;
    }
  }

  /// 检查是否有吃子移动
  bool _hasCaptureMoves(List<ChessMove> moves) {
    return moves.any((move) => move.capturedPiece != null);
  }

  /// 选择一个吃子移动
  ChessMove? _selectCapturingMove(List<ChessMove> moves) {
    final captureMoves =
        moves.where((move) => move.capturedPiece != null).toList();
    if (captureMoves.isEmpty) return null;
    return captureMoves[_random.nextInt(captureMoves.length)];
  }

  /// 选择一个相对合理的移动
  ChessMove? _selectReasonableMove(List<ChessMove> moves) {
    if (moves.isEmpty) return null;

    // 优先选择吃子移动或中心移动
    final preferredMoves = moves.where((move) {
      // 吃子移动优先
      if (move.capturedPiece != null) return true;

      // 中心位置移动优先
      final toRow = move.to.row;
      final toCol = move.to.col;
      if ((toRow >= 3 && toRow <= 4) && (toCol >= 3 && toCol <= 4)) {
        return true;
      }

      return false;
    }).toList();

    if (preferredMoves.isNotEmpty) {
      return preferredMoves[_random.nextInt(preferredMoves.length)];
    }

    // 否则随机选择
    return moves[_random.nextInt(moves.length)];
  }

  /// 获取随机移动作为回退方案
  ChessMove? _getRandomMove(
    List<List<ChessPiece?>> board,
    PieceColor aiColor, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    // 使用智能随机移动而不是完全随机
    return _getIntelligentRandomMove(
      board,
      aiColor,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
    );
  }

  /// 获取难度描述
  String getDifficultyDescription() {
    return AIDifficultyStrategy.getDifficultyDescription(advancedDifficulty);
  }

  /// 获取当前难度的详细信息
  Map<String, dynamic> getDifficultyInfo() {
    return {
      'level': advancedDifficulty.level,
      'displayName': advancedDifficulty.displayName,
      'description': getDifficultyDescription(),
      'deviceType': deviceType.name,
      'thinkingTimeMs': config.thinkingTimeMs,
      'randomnessProbability': config.randomnessProbability,
      'searchDepth': config.searchDepth,
      'useOpeningBook': config.useOpeningBook,
      'useEndgameTablebase': config.useEndgameTablebase,
      'threads': config.threads,
    };
  }

  /// 静态方法：获取设备推荐的难度等级
  static List<AIDifficultyLevel> getRecommendedDifficulties(
      [DeviceType? deviceType]) {
    return AIDifficultyStrategy.getRecommendedDifficultiesForDevice(
      deviceType ?? AIDifficultyStrategy.getCurrentDeviceType(),
    );
  }
}
