import '../models/chess_models.dart';

class ChessRules {
  static List<Position> getValidMoves(
    List<List<ChessPiece?>> board,
    Position position,
    {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? lastPawnDoubleMoved,
    int? lastPawnDoubleMovedNumber,
    int? currentMoveNumber,
    }
  ) {
    final piece = board[position.row][position.col];
    if (piece == null) return [];

    List<Position> validMoves = [];

    switch (piece.type) {
      case PieceType.pawn:
        validMoves.addAll(_getPawnMoves(
          board, 
          position, 
          piece.color,
          lastPawnDoubleMoved: lastPawnDoubleMoved,
          lastPawnDoubleMovedNumber: lastPawnDoubleMovedNumber,
          currentMoveNumber: currentMoveNumber,
        ));
        break;
      case PieceType.rook:
        validMoves.addAll(_getRookMoves(board, position, piece.color));
        break;
      case PieceType.knight:
        validMoves.addAll(_getKnightMoves(board, position, piece.color));
        break;
      case PieceType.bishop:
        validMoves.addAll(_getBishopMoves(board, position, piece.color));
        break;
      case PieceType.queen:
        validMoves.addAll(_getQueenMoves(board, position, piece.color));
        break;
      case PieceType.king:
        validMoves.addAll(_getKingMoves(
          board, 
          position, 
          piece.color,
          hasKingMoved: hasKingMoved,
          hasRookMoved: hasRookMoved,
        ));
        break;
    }

    return validMoves;
  }

  static List<Position> _getPawnMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color, {
    Position? lastPawnDoubleMoved,
    int? lastPawnDoubleMovedNumber,
    int? currentMoveNumber,
  }) {
    List<Position> moves = [];
    final direction = color == PieceColor.white ? -1 : 1;
    final startRow = color == PieceColor.white ? 6 : 1;

    // 前进一步
    if (_isValidPosition(position.row + direction, position.col) &&
        board[position.row + direction][position.col] == null) {
      moves.add(Position(row: position.row + direction, col: position.col));

      // 如果在起始位置，可以前进两步
      if (position.row == startRow &&
          _isValidPosition(position.row + 2 * direction, position.col) &&
          board[position.row + 2 * direction][position.col] == null) {
        moves.add(Position(row: position.row + 2 * direction, col: position.col));
      }
    }

    // 常规吃子移动
    for (final colOffset in [-1, 1]) {
      final newRow = position.row + direction;
      final newCol = position.col + colOffset;
      if (_isValidPosition(newRow, newCol)) {
        final targetPiece = board[newRow][newCol];
        if (targetPiece != null && targetPiece.color != color) {
          moves.add(Position(row: newRow, col: newCol));
        }
      }
    }

    // 吃过路兵
    if (lastPawnDoubleMoved != null && 
        lastPawnDoubleMovedNumber == currentMoveNumber! - 1 &&
        position.row == (color == PieceColor.white ? 3 : 4) &&
        (position.col - lastPawnDoubleMoved.col).abs() == 1 &&
        board[lastPawnDoubleMoved.row][lastPawnDoubleMoved.col]?.type == PieceType.pawn &&
        board[lastPawnDoubleMoved.row][lastPawnDoubleMoved.col]?.color != color) {
      moves.add(Position(
        row: position.row + direction,
        col: lastPawnDoubleMoved.col,
      ));
    }

    return moves;
  }

  static List<Position> _getRookMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color,
  ) {
    List<Position> moves = [];
    final directions = [
      [-1, 0], // 上
      [1, 0],  // 下
      [0, -1], // 左
      [0, 1],  // 右
    ];

    for (final direction in directions) {
      var currentRow = position.row;
      var currentCol = position.col;

      while (true) {
        currentRow += direction[0];
        currentCol += direction[1];

        if (!_isValidPosition(currentRow, currentCol)) break;

        final targetPiece = board[currentRow][currentCol];
        if (targetPiece == null) {
          moves.add(Position(row: currentRow, col: currentCol));
        } else {
          if (targetPiece.color != color) {
            moves.add(Position(row: currentRow, col: currentCol));
          }
          break;
        }
      }
    }

    return moves;
  }

  static List<Position> _getKnightMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color,
  ) {
    List<Position> moves = [];
    final offsets = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1],
    ];

    for (final offset in offsets) {
      final newRow = position.row + offset[0];
      final newCol = position.col + offset[1];

      if (_isValidPosition(newRow, newCol)) {
        final targetPiece = board[newRow][newCol];
        if (targetPiece == null || targetPiece.color != color) {
          moves.add(Position(row: newRow, col: newCol));
        }
      }
    }

    return moves;
  }

  static List<Position> _getBishopMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color,
  ) {
    List<Position> moves = [];
    final directions = [
      [-1, -1], // 左上
      [-1, 1],  // 右上
      [1, -1],  // 左下
      [1, 1],   // 右下
    ];

    for (final direction in directions) {
      var currentRow = position.row;
      var currentCol = position.col;

      while (true) {
        currentRow += direction[0];
        currentCol += direction[1];

        if (!_isValidPosition(currentRow, currentCol)) break;

        final targetPiece = board[currentRow][currentCol];
        if (targetPiece == null) {
          moves.add(Position(row: currentRow, col: currentCol));
        } else {
          if (targetPiece.color != color) {
            moves.add(Position(row: currentRow, col: currentCol));
          }
          break;
        }
      }
    }

    return moves;
  }

  static List<Position> _getQueenMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color,
  ) {
    var moves = _getRookMoves(board, position, color);
    moves.addAll(_getBishopMoves(board, position, color));
    return moves;
  }

  static List<Position> _getKingMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
  }) {
    List<Position> moves = [];
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];

    // 常规移动
    for (final direction in directions) {
      final newRow = position.row + direction[0];
      final newCol = position.col + direction[1];

      if (_isValidPosition(newRow, newCol)) {
        final targetPiece = board[newRow][newCol];
        if (targetPiece == null || targetPiece.color != color) {
          moves.add(Position(row: newRow, col: newCol));
        }
      }
    }

    // 王车易位
    if (hasKingMoved != null && 
        hasRookMoved != null && 
        !hasKingMoved[color]!) {
      final row = color == PieceColor.white ? 7 : 0;

      // 王翼易位
      if (!hasRookMoved[color]!['kingside']! &&
          board[row][5] == null &&
          board[row][6] == null &&
          board[row][7]?.type == PieceType.rook) {
        moves.add(Position(row: row, col: 6));
      }

      // 后翼易位
      if (!hasRookMoved[color]!['queenside']! &&
          board[row][1] == null &&
          board[row][2] == null &&
          board[row][3] == null &&
          board[row][0]?.type == PieceType.rook) {
        moves.add(Position(row: row, col: 2));
      }
    }

    return moves;
  }

  static bool _isValidPosition(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }
} 