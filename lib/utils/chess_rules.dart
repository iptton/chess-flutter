import '../models/chess_models.dart';

class ChessRules {
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

    // 获取所有可能的移动
    List<Position> possibleMoves;
    switch (piece.type) {
      case PieceType.pawn:
        possibleMoves = _getPawnMoves(board, position, piece.color);
        break;
      case PieceType.rook:
        possibleMoves = _getRookMoves(board, position, piece.color);
        break;
      case PieceType.knight:
        possibleMoves = _getKnightMoves(board, position, piece.color);
        break;
      case PieceType.bishop:
        possibleMoves = _getBishopMoves(board, position, piece.color);
        break;
      case PieceType.queen:
        possibleMoves = _getQueenMoves(board, position, piece.color);
        break;
      case PieceType.king:
        possibleMoves = _getKingMoves(
          board,
          position,
          piece.color,
          hasKingMoved: hasKingMoved,
          hasRookMoved: hasRookMoved,
        );
        break;
    }

    // 检查每个移动是否会导致自己被将军
    List<Position> legalMoves = [];
    for (final move in possibleMoves) {
      final newBoard = List<List<ChessPiece?>>.from(
        board.map((row) => List<ChessPiece?>.from(row))
      );
      newBoard[move.row][move.col] = newBoard[position.row][position.col];
      newBoard[position.row][position.col] = null;

      // 如果移动后自己不会被将军，这是一个合法移动
      if (!isInCheck(newBoard, piece.color)) {
        legalMoves.add(move);
      }
    }

    // 如果当前被将军，只返回能解除将军的移动
    if (isInCheck(board, piece.color)) {
      return legalMoves;
    }

    // 如果是兵的特殊移动（吃过路兵），需要额外检查
    if (piece.type == PieceType.pawn &&
        lastPawnDoubleMoved != null &&
        lastPawnDoubleMovedNumber != null &&
        currentMoveNumber != null) {
      final opponentColor = piece.color == PieceColor.white ? PieceColor.black : PieceColor.white;
      if (lastPawnDoubleMovedNumber == currentMoveNumber - 1) {
        if (piece.color == PieceColor.white && position.row == 3) {
          if (lastPawnDoubleMoved.row == 3 &&
              (lastPawnDoubleMoved.col - position.col).abs() == 1) {
            final enPassantMove = Position(row: 2, col: lastPawnDoubleMoved.col);
            if (legalMoves.any((move) => move.row == enPassantMove.row && move.col == enPassantMove.col)) {
              legalMoves.add(enPassantMove);
            }
          }
        } else if (piece.color == PieceColor.black && position.row == 4) {
          if (lastPawnDoubleMoved.row == 4 &&
              (lastPawnDoubleMoved.col - position.col).abs() == 1) {
            final enPassantMove = Position(row: 5, col: lastPawnDoubleMoved.col);
            if (legalMoves.any((move) => move.row == enPassantMove.row && move.col == enPassantMove.col)) {
              legalMoves.add(enPassantMove);
            }
          }
        }
      }
    }

    return legalMoves;
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

  // 检查指定颜色的王是否被将军
  static bool isInCheck(List<List<ChessPiece?>> board, PieceColor kingColor) {
    // 找到王的位置
    Position? kingPosition;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece?.type == PieceType.king && piece?.color == kingColor) {
          kingPosition = Position(row: row, col: col);
          break;
        }
      }
      if (kingPosition != null) break;
    }

    if (kingPosition == null) return false;

    // 检查对手的所有棋子是否可以攻击到王
    final opponentColor = kingColor == PieceColor.white ? PieceColor.black : PieceColor.white;
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece?.color == opponentColor) {
          final moves = getValidMovesWithoutCheckingCheck(
            board,
            Position(row: row, col: col),
          );
          if (moves.any((pos) => pos.row == kingPosition!.row && pos.col == kingPosition!.col)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  // 检查指定颜色是否被将死
  static bool isCheckmate(
    List<List<ChessPiece?>> board,
    PieceColor color,
    Map<PieceColor, bool> hasKingMoved,
    Map<PieceColor, Map<String, bool>> hasRookMoved,
    Map<PieceColor, Position?> lastPawnDoubleMoved,
    Map<PieceColor, int> lastPawnDoubleMovedNumber,
    int currentMoveNumber,
  ) {
    // 如果没有被将军，就不可能被将死
    if (!isInCheck(board, color)) return false;

    // 检查所有己方棋子的所有可能移动
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece?.color == color) {
          final moves = getValidMoves(
            board,
            Position(row: row, col: col),
            hasKingMoved: hasKingMoved,
            hasRookMoved: hasRookMoved,
            lastPawnDoubleMoved: lastPawnDoubleMoved[color == PieceColor.white ? PieceColor.black : PieceColor.white],
            lastPawnDoubleMovedNumber: lastPawnDoubleMovedNumber[color == PieceColor.white ? PieceColor.black : PieceColor.white],
            currentMoveNumber: currentMoveNumber,
          );

          // 对于每个可能的移动，检查是否能解除将军
          for (final move in moves) {
            final newBoard = List<List<ChessPiece?>>.from(
              board.map((row) => List<ChessPiece?>.from(row))
            );
            newBoard[move.row][move.col] = newBoard[row][col];
            newBoard[row][col] = null;

            if (!isInCheck(newBoard, color)) {
              return false;  // 找到一个可以解除将军的移动，不是将死
            }
          }
        }
      }
    }
    return true;  // 没有找到任何可以解除将军的移动，是将死
  }

  // 检查是否是和棋（无子可动）
  static bool isStalemate(
    List<List<ChessPiece?>> board,
    PieceColor color,
    Map<PieceColor, bool> hasKingMoved,
    Map<PieceColor, Map<String, bool>> hasRookMoved,
    Map<PieceColor, Position?> lastPawnDoubleMoved,
    Map<PieceColor, int> lastPawnDoubleMovedNumber,
    int currentMoveNumber,
  ) {
    // 如果被将军，就不是和棋
    if (isInCheck(board, color)) return false;

    // 检查是否有任何合法移动
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece?.color == color) {
          final moves = getValidMoves(
            board,
            Position(row: row, col: col),
            hasKingMoved: hasKingMoved,
            hasRookMoved: hasRookMoved,
            lastPawnDoubleMoved: lastPawnDoubleMoved[color == PieceColor.white ? PieceColor.black : PieceColor.white],
            lastPawnDoubleMovedNumber: lastPawnDoubleMovedNumber[color == PieceColor.white ? PieceColor.black : PieceColor.white],
            currentMoveNumber: currentMoveNumber,
          );
          if (moves.isNotEmpty) {
            return false;  // 找到一个合法移动，不是和棋
          }
        }
      }
    }
    return true;  // 没有任何合法移动，是和棋
  }

  // 获取所有可能的移动，不检查是否会导致自己被将军
  static List<Position> getValidMovesWithoutCheckingCheck(
    List<List<ChessPiece?>> board,
    Position position,
  ) {
    final piece = board[position.row][position.col];
    if (piece == null) return [];

    switch (piece.type) {
      case PieceType.pawn:
        return _getPawnMoves(board, position, piece.color);
      case PieceType.rook:
        return _getRookMoves(board, position, piece.color);
      case PieceType.knight:
        return _getKnightMoves(board, position, piece.color);
      case PieceType.bishop:
        return _getBishopMoves(board, position, piece.color);
      case PieceType.queen:
        return _getQueenMoves(board, position, piece.color);
      case PieceType.king:
        return _getKingMoves(board, position, piece.color);
    }
  }
}