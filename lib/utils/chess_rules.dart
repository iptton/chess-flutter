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
        possibleMoves = _getPawnMoves(
          board,
          position,
          piece.color,
          lastPawnDoubleMoved: lastPawnDoubleMoved,
          lastPawnDoubleMovedNumber: lastPawnDoubleMovedNumber,
          currentMoveNumber: currentMoveNumber,
        );
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
    return _filterLegalMoves(board, position, piece, possibleMoves, lastPawnDoubleMoved);
  }

  static List<Position> _filterLegalMoves(
    List<List<ChessPiece?>> board,
    Position piecePosition,
    ChessPiece piece,
    List<Position> possibleMoves,
    Position? lastPawnDoubleMoved,
  ) {
    List<Position> legalMoves = [];
    for (final move in possibleMoves) {
      final newBoard = List<List<ChessPiece?>>.from(
        board.map((row) => List<ChessPiece?>.from(row))
      );

      // Simulate the move
      newBoard[move.row][move.col] = piece;
      newBoard[piecePosition.row][piecePosition.col] = null;

      // If it's an en passant capture, remove the captured pawn
      if (piece.type == PieceType.pawn &&
          lastPawnDoubleMoved != null &&
          move.col == lastPawnDoubleMoved.col &&
          move.row == (piece.color == PieceColor.white ? lastPawnDoubleMoved.row - 1 : lastPawnDoubleMoved.row + 1) &&
          (piecePosition.col - lastPawnDoubleMoved.col).abs() == 1) {
        newBoard[lastPawnDoubleMoved.row][lastPawnDoubleMoved.col] = null;
      }
      
      if (!isInCheck(newBoard, piece.color)) {
        legalMoves.add(move);
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
    _addPawnForwardMoves(board, position, color, moves);
    _addPawnCaptureMoves(board, position, color, moves);
    _addEnPassantMoves(board, position, color, lastPawnDoubleMoved, lastPawnDoubleMovedNumber, currentMoveNumber, moves);
    return moves;
  }

  static void _addPawnForwardMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color,
    List<Position> moves,
  ) {
    final direction = color == PieceColor.white ? -1 : 1;
    final startRow = color == PieceColor.white ? 6 : 1;

    // Forward one step
    final oneStepForwardRow = position.row + direction;
    if (_isValidPosition(oneStepForwardRow, position.col) &&
        board[oneStepForwardRow][position.col] == null) {
      moves.add(Position(row: oneStepForwardRow, col: position.col));

      // Forward two steps from start
      if (position.row == startRow) {
        final twoStepsForwardRow = position.row + 2 * direction;
        if (_isValidPosition(twoStepsForwardRow, position.col) &&
            board[twoStepsForwardRow][position.col] == null) {
          moves.add(Position(row: twoStepsForwardRow, col: position.col));
        }
      }
    }
  }
  
  static void _addPawnCaptureMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color,
    List<Position> moves,
  ) {
    final direction = color == PieceColor.white ? -1 : 1;
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
  }

  static void _addEnPassantMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color,
    Position? lastPawnDoubleMoved,
    int? lastPawnDoubleMovedNumber,
    int? currentMoveNumber,
    List<Position> moves,
  ) {
    if (lastPawnDoubleMoved == null || lastPawnDoubleMovedNumber == null || currentMoveNumber == null) {
      return;
    }
    if (lastPawnDoubleMovedNumber != currentMoveNumber - 1) {
      return;
    }

    final direction = color == PieceColor.white ? -1 : 1;
    final enPassantRow = color == PieceColor.white ? 3 : 4; // Row where the current pawn must be

    if (position.row == enPassantRow &&
        (position.col - lastPawnDoubleMoved.col).abs() == 1 &&
        lastPawnDoubleMoved.row == enPassantRow) { // Opponent's pawn must be on the same rank
        // Target square for en passant capture
        final targetRow = position.row + direction;
        final targetCol = lastPawnDoubleMoved.col;
        
        // Check if the opponent's piece that double-stepped is actually a pawn and of opponent color
        final opponentPawn = board[lastPawnDoubleMoved.row][lastPawnDoubleMoved.col];
        if (opponentPawn != null && opponentPawn.type == PieceType.pawn && opponentPawn.color != color) {
             moves.add(Position(row: targetRow, col: targetCol));
        }
    }
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
    _addStandardKingMoves(board, position, color, moves);
    _addCastlingMoves(board, position, color, hasKingMoved, hasRookMoved, moves);
    return moves;
  }

  static void _addStandardKingMoves(
    List<List<ChessPiece?>> board,
    Position position,
    PieceColor color,
    List<Position> moves,
  ) {
    final directions = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];

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
  }

  static void _addCastlingMoves(
    List<List<ChessPiece?>> board,
    Position position, // King's current position
    PieceColor color,
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    List<Position> moves,
  ) {
    if (hasKingMoved == null || hasRookMoved == null || hasKingMoved[color] == true) {
      return;
    }

    final kingRow = position.row; // King's current row, should match color's standard row

    // Kingside castling
    if (hasRookMoved[color]?['kingside'] == false &&
        board[kingRow][position.col + 1] == null &&
        board[kingRow][position.col + 2] == null &&
        board[kingRow][position.col + 3]?.type == PieceType.rook &&
        board[kingRow][position.col + 3]?.color == color) {
      // Check if squares king moves over are attacked
      if (!_isSquareAttacked(board, Position(row: kingRow, col: position.col + 1), color) &&
          !_isSquareAttacked(board, Position(row: kingRow, col: position.col + 2), color) &&
          !isInCheck(board, color)) { // King not currently in check
        moves.add(Position(row: kingRow, col: position.col + 2));
      }
    }

    // Queenside castling
    if (hasRookMoved[color]?['queenside'] == false &&
        board[kingRow][position.col - 1] == null &&
        board[kingRow][position.col - 2] == null &&
        board[kingRow][position.col - 3] == null &&
        board[kingRow][position.col - 4]?.type == PieceType.rook &&
        board[kingRow][position.col - 4]?.color == color) {
      // Check if squares king moves over are attacked
      if (!_isSquareAttacked(board, Position(row: kingRow, col: position.col - 1), color) &&
          !_isSquareAttacked(board, Position(row: kingRow, col: position.col - 2), color) &&
           !isInCheck(board, color)) { // King not currently in check
        moves.add(Position(row: kingRow, col: position.col - 2));
      }
    }
  }

  static bool _isValidPosition(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  // 检查指定颜色的王是否被将军
  static bool isInCheck(List<List<ChessPiece?>> board, PieceColor kingColor) {
    final kingPosition = _findKingPosition(board, kingColor);
    if (kingPosition == null) return false; // Should not happen in a valid game

    return _isSquareAttacked(board, kingPosition, kingColor);
  }

  static Position? _findKingPosition(List<List<ChessPiece?>> board, PieceColor kingColor) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece != null && piece.type == PieceType.king && piece.color == kingColor) {
          return Position(row: r, col: c);
        }
      }
    }
    return null;
  }

  static bool _isSquareAttacked(List<List<ChessPiece?>> board, Position square, PieceColor byPlayerColor) {
    // Check if any piece of the opponent can attack the given square.
    // Note: byPlayerColor is the color of the player *being attacked* on the square,
    // so we look for attackers of the opposite color.
    final attackerColor = byPlayerColor == PieceColor.white ? PieceColor.black : PieceColor.white;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece != null && piece.color == attackerColor) {
          // Use getValidMovesWithoutCheckingCheck to see if the attacker can move to the square.
          // This avoids recursion with isInCheck.
          final moves = getValidMovesWithoutCheckingCheck(board, Position(row: r, col: c));
          if (moves.any((move) => move.row == square.row && move.col == square.col)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool _hasAnyLegalMove(
    List<List<ChessPiece?>> board,
    PieceColor color,
    Map<PieceColor, bool> hasKingMoved,
    Map<PieceColor, Map<String, bool>> hasRookMoved,
    Map<PieceColor, Position?> lastPawnDoubleMoved, // Full map for both colors
    Map<PieceColor, int> lastPawnDoubleMovedNumber, // Full map
    int currentMoveNumber,
  ) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece != null && piece.color == color) {
          final opponentColor = color == PieceColor.white ? PieceColor.black : PieceColor.white;
          final moves = getValidMoves(
            board,
            Position(row: r, col: c),
            hasKingMoved: hasKingMoved,
            hasRookMoved: hasRookMoved,
            lastPawnDoubleMoved: lastPawnDoubleMoved[opponentColor], // Pass opponent's last double move
            lastPawnDoubleMovedNumber: lastPawnDoubleMovedNumber[opponentColor], // Pass opponent's number
            currentMoveNumber: currentMoveNumber,
          );
          if (moves.isNotEmpty) {
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
    if (!isInCheck(board, color)) return false;
    return !_hasAnyLegalMove(board, color, hasKingMoved, hasRookMoved, lastPawnDoubleMoved, lastPawnDoubleMovedNumber, currentMoveNumber);
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
    if (isInCheck(board, color)) return false;
    return !_hasAnyLegalMove(board, color, hasKingMoved, hasRookMoved, lastPawnDoubleMoved, lastPawnDoubleMovedNumber, currentMoveNumber);
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