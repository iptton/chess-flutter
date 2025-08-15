import '../models/chess_models.dart';
import 'chess_adapter.dart';

/// 使用 chess 包的新规则引擎
class ChessRules {
  /// 获取指定位置棋子的所有合法移动
  static List<Position> getValidMoves(
    List<List<ChessPiece?>> board,
    Position position, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? lastPawnDoubleMoved,
    int? lastPawnDoubleMovedNumber,
    int? currentMoveNumber,
  }) {
    final piece = board[position.row][position.col];
    if (piece == null) return [];

    // 计算吃过路兵目标位置
    Position? enPassantTarget;
    if (lastPawnDoubleMoved != null && 
        lastPawnDoubleMovedNumber != null &&
        currentMoveNumber != null &&
        lastPawnDoubleMovedNumber == currentMoveNumber - 1) {
      final direction = piece.color == PieceColor.white ? 1 : -1;
      enPassantTarget = Position(
        row: lastPawnDoubleMoved.row + direction,
        col: lastPawnDoubleMoved.col,
      );
    }

    // 使用 chess 包获取所有合法移动
    final allMoves = ChessAdapter.getLegalMoves(
      board,
      piece.color,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
      halfMoveClock: 0,
      fullMoveNumber: (currentMoveNumber ?? 0) ~/ 2 + 1,
    );

    // 过滤出从指定位置开始的移动
    return allMoves
        .where((move) => move.from.row == position.row && move.from.col == position.col)
        .map((move) => move.to)
        .toList();
  }

  /// 检查指定颜色是否被将军
  static bool isInCheck(
    List<List<ChessPiece?>> board,
    PieceColor color, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    return ChessAdapter.isInCheck(
      board,
      color,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
    );
  }

  /// 检查指定颜色是否被将死
  static bool isCheckmate(
    List<List<ChessPiece?>> board,
    PieceColor color,
    Map<PieceColor, bool> hasKingMoved,
    Map<PieceColor, Map<String, bool>> hasRookMoved,
    Map<PieceColor, Position?> lastPawnDoubleMoved,
    Map<PieceColor, int> lastPawnDoubleMovedNumber,
    int currentMoveNumber,
  ) {
    // 计算吃过路兵目标位置
    Position? enPassantTarget;
    final opponentColor = color == PieceColor.white ? PieceColor.black : PieceColor.white;
    final lastPawnPos = lastPawnDoubleMoved[opponentColor];
    final lastPawnMoveNum = lastPawnDoubleMovedNumber[opponentColor];
    
    if (lastPawnPos != null && 
        lastPawnMoveNum != null &&
        lastPawnMoveNum == currentMoveNumber - 1) {
      final direction = opponentColor == PieceColor.white ? 1 : -1;
      enPassantTarget = Position(
        row: lastPawnPos.row + direction,
        col: lastPawnPos.col,
      );
    }

    return ChessAdapter.isCheckmate(
      board,
      color,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
    );
  }

  /// 检查指定颜色是否和棋（逼和）
  static bool isStalemate(
    List<List<ChessPiece?>> board,
    PieceColor color,
    Map<PieceColor, bool> hasKingMoved,
    Map<PieceColor, Map<String, bool>> hasRookMoved,
    Map<PieceColor, Position?> lastPawnDoubleMoved,
    Map<PieceColor, int> lastPawnDoubleMovedNumber,
    int currentMoveNumber,
  ) {
    // 计算吃过路兵目标位置
    Position? enPassantTarget;
    final opponentColor = color == PieceColor.white ? PieceColor.black : PieceColor.white;
    final lastPawnPos = lastPawnDoubleMoved[opponentColor];
    final lastPawnMoveNum = lastPawnDoubleMovedNumber[opponentColor];
    
    if (lastPawnPos != null && 
        lastPawnMoveNum != null &&
        lastPawnMoveNum == currentMoveNumber - 1) {
      final direction = opponentColor == PieceColor.white ? 1 : -1;
      enPassantTarget = Position(
        row: lastPawnPos.row + direction,
        col: lastPawnPos.col,
      );
    }

    return ChessAdapter.isStalemate(
      board,
      color,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
    );
  }

  /// 检查游戏是否结束
  static bool isGameOver(
    List<List<ChessPiece?>> board,
    PieceColor color, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    return ChessAdapter.isGameOver(
      board,
      color,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
    );
  }

  /// 获取所有可能的移动，不检查是否会导致自己被将军
  /// 这个方法保持向后兼容性
  static List<Position> getValidMovesWithoutCheckingCheck(
    List<List<ChessPiece?>> board,
    Position position,
  ) {
    // 使用新的方法，但不进行将军检查
    // 注意：chess 包总是会检查将军，所以这个方法实际上和 getValidMoves 相同
    return getValidMoves(board, position);
  }

  /// 检查指定位置是否有效（在棋盘范围内）
  static bool isValidPosition(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  /// 获取所有合法移动（包含详细移动信息）
  static List<ChessMove> getAllLegalMoves(
    List<List<ChessPiece?>> board,
    PieceColor color, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
    int halfMoveClock = 0,
    int fullMoveNumber = 1,
  }) {
    return ChessAdapter.getLegalMoves(
      board,
      color,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
    );
  }

  /// 验证移动是否合法
  static bool isValidMove(
    List<List<ChessPiece?>> board,
    Position from,
    Position to, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    final piece = board[from.row][from.col];
    if (piece == null) return false;

    final validMoves = getValidMoves(
      board,
      from,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
    );

    return validMoves.any((pos) => pos.row == to.row && pos.col == to.col);
  }

  /// 获取棋子在指定位置的攻击范围（不考虑将军）
  static List<Position> getAttackingSquares(
    List<List<ChessPiece?>> board,
    Position position,
  ) {
    // 这个方法主要用于UI显示，使用简化实现
    return getValidMovesWithoutCheckingCheck(board, position);
  }
}
