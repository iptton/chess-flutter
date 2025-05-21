import '../models/chess_models.dart';
import '../utils/chess_rules.dart';

class GameLogicService {
  // Method to apply a move to the board
  GameState applyMove(GameState state, ChessMove move) {
    // Create a new board state
    final newBoard = List<List<ChessPiece?>>.from(
      state.board.map((row) => List<ChessPiece?>.from(row)),
    );

    // Move the piece
    newBoard[move.to.row][move.to.col] = move.piece;
    newBoard[move.from.row][move.from.col] = null;

    // Handle en passant capture
    if (move.isEnPassant) {
      // The pawn captured via en passant is at the 'to' square's row and the 'from' square's column.
      // This logic seems to be handled in _handleEnPassant in ChessBloc by removing the captured pawn directly.
      // For applyMove, we'd expect the captured pawn's original square to be cleared.
      // In an en passant move, the 'to' square is empty before the move, and the captured pawn is adjacent.
      // The move object itself should ideally carry enough info.
      // If 'move.capturedPiece' is the en passant captured pawn, its original position is what needs to be cleared.
      // Assuming the en passant capture implies the captured pawn is at move.from.row, move.to.col
      newBoard[move.from.row][move.to.col] = null;
    }

    // Handle castling
    if (move.isCastling) {
      final rookFromCol = move.to.col > move.from.col ? 7 : 0; // King moves two squares, rook is on that side
      final rookToCol = move.to.col > move.from.col ? move.to.col - 1 : move.to.col + 1; // Rook moves next to king
      
      // Move the rook
      final rook = newBoard[move.from.row][rookFromCol];
      newBoard[move.from.row][rookToCol] = rook;
      newBoard[move.from.row][rookFromCol] = null;
    }

    // Handle pawn promotion
    if (move.isPromotion && move.promotionType != null) {
      newBoard[move.to.row][move.to.col] = ChessPiece(
        type: move.promotionType!,
        color: move.piece.color,
      );
    }

    // Update and return the new game state
    // Note: Switching currentPlayer, updating move history, etc., are typically handled
    // by the calling Bloc/service after this pure board manipulation.
    // For now, this method focuses on applying the move to the board.
    // The original _applyMove in ChessBloc also updated currentPlayer and moveHistory.
    // We will replicate that behavior here for consistency during refactoring.
    return state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white,
      selectedPosition: null, // Clear selection after move
      validMoves: const [], // Clear valid moves
      moveHistory: List.from(state.moveHistory)..add(move),
      lastMove: move,
      // Other state updates like hasKingMoved, hasRookMoved, lastPawnDoubleMoved
      // will be handled by more specific methods that call applyMove or by the Bloc.
      // For now, this is a direct translation of the board manipulation part.
    );
  }

  // Method to select a piece and determine valid moves
  // This was the original stub_out, we are replacing it with getValidMovesForPiece
  // List<Move> selectPiece(GameState gameState, Piece piece) { 
  //   // Implementation will be added later
  //   return [];
  // }

  List<Position> getValidMovesForPiece(GameState gameState, Position selectedPosition) {
    // If the board is not interactive or the game is over, no moves are valid.
    if (!gameState.isInteractive || gameState.isCheckmate || gameState.isStalemate) {
      return [];
    }

    // If a specific player's turn is enforced and it's not the current player, no moves.
    if (gameState.allowedPlayer != null && gameState.currentPlayer != gameState.allowedPlayer) {
      return [];
    }

    final piece = gameState.board[selectedPosition.row][selectedPosition.col];

    // If there's no piece at the selected position or it's not the current player's piece.
    if (piece == null || piece.color != gameState.currentPlayer) {
      return [];
    }

    // Determine the opponent's color for en passant check.
    final opponentColor = piece.color == PieceColor.white ? PieceColor.black : PieceColor.white;

    // Get valid moves from ChessRules.
    final validMoves = ChessRules.getValidMoves(
      gameState.board,
      selectedPosition,
      hasKingMoved: gameState.hasKingMoved,
      hasRookMoved: gameState.hasRookMoved,
      lastPawnDoubleMoved: gameState.lastPawnDoubleMoved[opponentColor],
      lastPawnDoubleMovedNumber: gameState.lastPawnDoubleMovedNumber[opponentColor],
      currentMoveNumber: gameState.currentMoveNumber,
    );

    return validMoves;
  }

  // Method to handle pawn promotion
  GameState handlePawnPromotion(GameState gameState, Piece promotedPiece) {
    // Implementation will be added later
    return gameState;
  }

  // Method to handle castling
  GameState handleCastling(GameState gameState, Move move) {
    // Implementation will be added later
    return gameState;
  }

  // Method to handle en passant
  GameState handleEnPassant(GameState gameState, ChessMove move) {
    // Implementation will be added later
    return gameState;
  }

  // Helper methods moved from ChessBloc
  static String _getPositionName(Position position) {
    final col = String.fromCharCode('A'.codeUnitAt(0) + position.col);
    final row = 8 - position.row;
    return '$col$row';
  }

  static String _getPieceTypeName(PieceType type) {
    switch (type) {
      case PieceType.king:
        return "王";
      case PieceType.queen:
        return "后";
      case PieceType.bishop:
        return "象";
      case PieceType.knight:
        return "马";
      case PieceType.rook:
        return "车";
      case PieceType.pawn:
        return "兵";
    }
  }

  bool _isCastlingMove(ChessPiece movingPiece, Position from, Position to) {
    return movingPiece.type == PieceType.king &&
           (from.col - to.col).abs() == 2;
  }

  bool _isPawnDoubleMove(ChessPiece movingPiece, Position from, Position to) {
    return movingPiece.type == PieceType.pawn &&
           (from.row - to.row).abs() == 2;
  }

  bool _isEnPassantMove(GameState state, ChessPiece movingPiece, Position from, Position to, ChessPiece? capturedPiece) {
    final opponentColor = movingPiece.color == PieceColor.white ? PieceColor.black : PieceColor.white;
    final opponentLastPawnDoubleMoved = state.lastPawnDoubleMoved[opponentColor];
    final opponentLastMoveNumber = state.lastPawnDoubleMovedNumber[opponentColor];

    if (movingPiece.type != PieceType.pawn ||
        opponentLastPawnDoubleMoved == null ||
        from.col == to.col || // Must be a diagonal move for pawn capture
        opponentLastMoveNumber != state.currentMoveNumber -1) { // En passant only on the very next turn
      return false;
    }
    
    // Check if the 'to' position is the correct en passant square
    if (movingPiece.color == PieceColor.white) {
      return from.row == 3 && // White pawn on 5th rank (row 3)
             to.row == 2 && // Moves to 6th rank (row 2)
             opponentLastPawnDoubleMoved.row == 3 && // Opponent pawn was on 5th rank
             opponentLastPawnDoubleMoved.col == to.col; // Opponent pawn is in the same column as 'to'
    } else { // Black pawn
      return from.row == 4 && // Black pawn on 4th rank (row 4)
             to.row == 5 && // Moves to 3rd rank (row 5)
             opponentLastPawnDoubleMoved.row == 4 && // Opponent pawn was on 4th rank
             opponentLastPawnDoubleMoved.col == to.col; // Opponent pawn is in the same column as 'to'
    }
  }

  bool _isPawnPromotion(ChessPiece movingPiece, Position to) {
    return movingPiece.type == PieceType.pawn &&
           (to.row == 0 || to.row == 7);
  }

  GameState _handleRegularMoveLogic(
    GameState state,
    ChessPiece movingPiece,
    ChessPiece? capturedPiece,
    Position from,
    Position to,
    List<List<ChessPiece?>> newBoard,
  ) {
    newBoard[to.row][to.col] = movingPiece;
    newBoard[from.row][from.col] = null;

    Map<PieceColor, Map<String, bool>> newHasRookMoved = Map.from(state.hasRookMoved.map(
      (key, value) => MapEntry(key, Map.from(value)),
    ));
    if (movingPiece.type == PieceType.rook) {
      if (from.col == 0 && from.row == (movingPiece.color == PieceColor.white ? 7 : 0)) {
        newHasRookMoved[movingPiece.color]!['queenside'] = true;
      } else if (from.col == 7 && from.row == (movingPiece.color == PieceColor.white ? 7 : 0)) {
        newHasRookMoved[movingPiece.color]!['kingside'] = true;
      }
    }

    Map<PieceColor, bool> newHasKingMoved = Map.from(state.hasKingMoved);
    if (movingPiece.type == PieceType.king) {
      newHasKingMoved[movingPiece.color] = true;
    }

    final newLastPawnDoubleMoved = Map<PieceColor, Position?>.from(state.lastPawnDoubleMoved);
    final newLastPawnDoubleMovedNumber = Map<PieceColor, int>.from(state.lastPawnDoubleMovedNumber);

    if (movingPiece.type == PieceType.pawn && (from.row - to.row).abs() == 2) {
      newLastPawnDoubleMoved[movingPiece.color] = to;
      newLastPawnDoubleMovedNumber[movingPiece.color] = state.currentMoveNumber;
    } else {
      // Clear previous double move for the current player if this wasn't a double move
       if (newLastPawnDoubleMoved[movingPiece.color] != null) {
          newLastPawnDoubleMoved[movingPiece.color] = null;
          newLastPawnDoubleMovedNumber[movingPiece.color] = -1;
       }
    }
    // Clear opponent's en passant if it wasn't taken this turn
    final opponentColor = movingPiece.color == PieceColor.white ? PieceColor.black : PieceColor.white;
    if (newLastPawnDoubleMoved[opponentColor] != null && newLastPawnDoubleMovedNumber[opponentColor] != state.currentMoveNumber -1 ) {
        newLastPawnDoubleMoved[opponentColor] = null;
        newLastPawnDoubleMovedNumber[opponentColor] = -1;
    }


    final move = ChessMove(
      from: from,
      to: to,
      piece: movingPiece,
      capturedPiece: capturedPiece,
    );

    String message;
    if (capturedPiece != null) {
      message = '${movingPiece.color == PieceColor.white ? "White" : "Black"} ${_getPieceTypeName(movingPiece.type)} from ${_getPositionName(from)} captures ${capturedPiece.color == PieceColor.white ? "White" : "Black"} ${_getPieceTypeName(capturedPiece.type)} at ${_getPositionName(to)}';
    } else {
      message = '${movingPiece.color == PieceColor.white ? "White" : "Black"} ${_getPieceTypeName(movingPiece.type)} moves from ${_getPositionName(from)} to ${_getPositionName(to)}';
    }

    final nextPlayer = state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck && ChessRules.isCheckmate(
      newBoard,
      nextPlayer,
      newHasKingMoved,
      newHasRookMoved,
      newLastPawnDoubleMoved,
      newLastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );
    final isStalemate = !isCheck && ChessRules.isStalemate(
      newBoard,
      nextPlayer,
      newHasKingMoved,
      newHasRookMoved,
      newLastPawnDoubleMoved,
      newLastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );

    if (isCheckmate) {
      message += '. Checkmate! ${state.currentPlayer == PieceColor.white ? "White" : "Black"} wins!';
    } else if (isStalemate) {
      message += '. Stalemate! The game is a draw.';
    } else if (isCheck) {
      message += '. Check!';
    }
    
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state.copyWith(selectedPosition: null, validMoves: []));


    return state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      selectedPosition: null,
      validMoves: [],
      hasKingMoved: newHasKingMoved,
      hasRookMoved: newHasRookMoved,
      lastPawnDoubleMoved: newLastPawnDoubleMoved,
      lastPawnDoubleMovedNumber: newLastPawnDoubleMovedNumber,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: List.from(state.moveHistory)..add(move),
      specialMoveMessage: message,
      lastMove: move,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      undoStates: newUndoStates,
      redoStates: [],
    );
  }

  GameState _handleCastlingLogic(
    GameState state,
    ChessPiece movingPiece,
    Position from,
    Position to,
    List<List<ChessPiece?>> newBoard,
  ) {
    final isKingside = to.col > from.col;
    final rookFromCol = isKingside ? 7 : 0;
    final rookToCol = isKingside ? 5 : 3;

    newBoard[to.row][to.col] = movingPiece;
    newBoard[from.row][from.col] = null;
    newBoard[from.row][rookToCol] = state.board[from.row][rookFromCol];
    newBoard[from.row][rookFromCol] = null;

    final newHasKingMoved = Map<PieceColor, bool>.from(state.hasKingMoved);
    newHasKingMoved[movingPiece.color] = true;

    // Mark rooks as moved too for the castled side
    final newHasRookMoved = Map<PieceColor, Map<String, bool>>.from(state.hasRookMoved.map(
      (key, value) => MapEntry(key, Map.from(value)),
    ));
    newHasRookMoved[movingPiece.color]![isKingside ? 'kingside' : 'queenside'] = true;


    final move = ChessMove(
      from: from,
      to: to,
      piece: movingPiece,
      isCastling: true,
    );

    String message = '${movingPiece.color == PieceColor.white ? "White" : "Black"} castles ${isKingside ? "kingside" : "queenside"} from ${_getPositionName(from)} to ${_getPositionName(to)}';

    final nextPlayer = state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck && ChessRules.isCheckmate(
      newBoard,
      nextPlayer,
      newHasKingMoved,
      newHasRookMoved,
      state.lastPawnDoubleMoved,
      state.lastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );
    final isStalemate = !isCheck && ChessRules.isStalemate(
      newBoard,
      nextPlayer,
      newHasKingMoved,
      newHasRookMoved,
      state.lastPawnDoubleMoved,
      state.lastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );

    if (isCheckmate) {
      message += '. Checkmate! ${state.currentPlayer == PieceColor.white ? "White" : "Black"} wins!';
    } else if (isStalemate) {
      message += '. Stalemate! The game is a draw.';
    } else if (isCheck) {
      message += '. Check!';
    }
    
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state.copyWith(selectedPosition: null, validMoves: []));

    return state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      selectedPosition: null,
      validMoves: [],
      hasKingMoved: newHasKingMoved,
      hasRookMoved: newHasRookMoved,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: List.from(state.moveHistory)..add(move),
      specialMoveMessage: message,
      lastMove: move,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      undoStates: newUndoStates,
      redoStates: [],
    );
  }

  GameState _handleEnPassantLogic(
    GameState state,
    ChessPiece movingPiece,
    Position from,
    Position to,
    List<List<ChessPiece?>> newBoard,
  ) {
    final opponentColor = movingPiece.color == PieceColor.white ? PieceColor.black : PieceColor.white;
    final capturedPawnPosition = Position(from.row, to.col); // Captured pawn is on the same rank as 'from', and same col as 'to'
    final capturedPawn = state.board[capturedPawnPosition.row][capturedPawnPosition.col]!;

    newBoard[to.row][to.col] = movingPiece;
    newBoard[from.row][from.col] = null;
    newBoard[capturedPawnPosition.row][capturedPawnPosition.col] = null; // Remove captured pawn

    final move = ChessMove(
      from: from,
      to: to,
      piece: movingPiece,
      capturedPiece: capturedPawn,
      isEnPassant: true,
    );

    final newLastPawnDoubleMoved = Map<PieceColor, Position?>.from(state.lastPawnDoubleMoved);
    final newLastPawnDoubleMovedNumber = Map<PieceColor, int>.from(state.lastPawnDoubleMovedNumber);
    newLastPawnDoubleMoved[opponentColor] = null; // Clear the en passant flag for the captured pawn
    newLastPawnDoubleMovedNumber[opponentColor] = -1;

    String message = '${movingPiece.color == PieceColor.white ? "White" : "Black"} pawn from ${_getPositionName(from)} captures en passant at ${_getPositionName(to)}';

    final nextPlayer = state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck && ChessRules.isCheckmate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      state.hasRookMoved,
      newLastPawnDoubleMoved,
      newLastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );
    final isStalemate = !isCheck && ChessRules.isStalemate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      state.hasRookMoved,
      newLastPawnDoubleMoved,
      newLastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );

    if (isCheckmate) {
      message += '. Checkmate! ${state.currentPlayer == PieceColor.white ? "White" : "Black"} wins!';
    } else if (isStalemate) {
      message += '. Stalemate! The game is a draw.';
    } else if (isCheck) {
      message += '. Check!';
    }

    final newUndoStates = List<GameState>.from(state.undoStates)..add(state.copyWith(selectedPosition: null, validMoves: []));

    return state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      selectedPosition: null,
      validMoves: [],
      lastPawnDoubleMoved: newLastPawnDoubleMoved,
      lastPawnDoubleMovedNumber: newLastPawnDoubleMovedNumber,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: List.from(state.moveHistory)..add(move),
      specialMoveMessage: message,
      lastMove: move,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      undoStates: newUndoStates,
      redoStates: [],
    );
  }

  GameState _handlePawnPromotionLogic(
    GameState state,
    ChessPiece movingPiece,
    Position from,
    Position to,
    List<List<ChessPiece?>> newBoard,
  ) {
    newBoard[to.row][to.col] = movingPiece; // Temporarily place the pawn
    newBoard[from.row][from.col] = null;

    final move = ChessMove(
      from: from,
      to: to,
      piece: movingPiece,
      isPromotion: true, // Mark as promotion
      // promotionType will be set by completePawnPromotion
    );
    
    // Clear opponent's en passant if it wasn't taken this turn
    final opponentColor = movingPiece.color == PieceColor.white ? PieceColor.black : PieceColor.white;
    final newLastPawnDoubleMoved = Map<PieceColor, Position?>.from(state.lastPawnDoubleMoved);
    final newLastPawnDoubleMovedNumber = Map<PieceColor, int>.from(state.lastPawnDoubleMovedNumber);
    if (newLastPawnDoubleMoved[opponentColor] != null && newLastPawnDoubleMovedNumber[opponentColor] != state.currentMoveNumber -1 ) {
        newLastPawnDoubleMoved[opponentColor] = null;
        newLastPawnDoubleMovedNumber[opponentColor] = -1;
    }


    // The game state is now pending promotion. Current player does not change yet.
    // Undo states should store the state *before* this pending promotion.
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state.copyWith(selectedPosition: null, validMoves: []));


    return state.copyWith(
      board: newBoard, // Board shows pawn at the promotion square
      selectedPosition: null,
      validMoves: [],
      lastPawnDoubleMoved: newLastPawnDoubleMoved, // En passant state might have changed
      lastPawnDoubleMovedNumber: newLastPawnDoubleMovedNumber,
      // currentMoveNumber and currentPlayer do not change yet
      // moveHistory will be updated by completePawnPromotion
      // specialMoveMessage will be set by completePawnPromotion
      lastMove: move, // Store the pending promotion move
      isPendingPromotion: true, // Signal UI to ask for promotion choice
      promotionPosition: to, // Store where promotion is happening
      undoStates: newUndoStates,
      redoStates: [],
    );
  }

  GameState completePawnPromotion(
    GameState state,
    PieceType promotionType,
  ) {
    if (!state.isPendingPromotion || state.promotionPosition == null || state.lastMove == null) {
      // Should not happen if called correctly
      return state;
    }

    final newBoard = List<List<ChessPiece?>>.from(
      state.board.map((row) => List<ChessPiece?>.from(row)),
    );
    final pawn = newBoard[state.promotionPosition!.row][state.promotionPosition!.col]!;
    final promotedPiece = ChessPiece(
      type: promotionType,
      color: pawn.color,
    );

    newBoard[state.promotionPosition!.row][state.promotionPosition!.col] = promotedPiece;

    final lastMove = state.lastMove!.copyWith(
      promotionType: promotionType, // Now set the actual promotion type
      piece: promotedPiece, // The move is now considered to be by the promoted piece
    );

    String message = '${pawn.color == PieceColor.white ? "White" : "Black"} pawn promotes to ${_getPieceTypeName(promotionType)} at ${_getPositionName(state.promotionPosition!)}';

    final nextPlayer = state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck && ChessRules.isCheckmate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      state.hasRookMoved,
      state.lastPawnDoubleMoved,
      state.lastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1, // Promotion completes the move
    );
    final isStalemate = !isCheck && ChessRules.isStalemate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      state.hasRookMoved,
      state.lastPawnDoubleMoved,
      state.lastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );

    if (isCheckmate) {
      message += '. Checkmate! ${state.currentPlayer == PieceColor.white ? "White" : "Black"} wins!';
    } else if (isStalemate) {
      message += '. Stalemate! The game is a draw.';
    } else if (isCheck) {
      message += '. Check!';
    }
    
    // The undo state added by _handlePawnPromotionLogic was for the state *before* this promotion choice.
    // That is correct.

    return state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer, // Now switch player
      moveHistory: List.from(state.moveHistory)..add(lastMove),
      specialMoveMessage: message,
      lastMove: lastMove,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      isPendingPromotion: false, // Promotion is complete
      promotionPosition: null,
      currentMoveNumber: state.currentMoveNumber + 1, // Increment move number
      selectedPosition: null,
      validMoves: [],
      // undoStates and redoStates are already handled by _handlePawnPromotionLogic
    );
  }

  GameState handleMove(GameState state, Position from, Position to) {
    // This check is similar to ChessBloc._onMovePiece
    // It assumes validMoves have been pre-calculated and set in the state if needed by UI,
    // or that the move is programmatically determined to be valid.
    // For direct calls, the caller is responsible for ensuring 'to' is a valid target.
    // Here we re-fetch valid moves for safety if not already present for the selected piece.
    
    final List<Position> currentValidMoves = (state.selectedPosition == from)
        ? state.validMoves
        : getValidMovesForPiece(state, from);

    final isValidMove = currentValidMoves.any(
      (pos) => pos.row == to.row && pos.col == to.col
    );

    if (!isValidMove) {
      // Optionally, return state with an error message or just the unchanged state
      return state.copyWith(specialMoveMessage: "Invalid move selected.");
    }

    final movingPiece = state.board[from.row][from.col]!;
    final capturedPiece = state.board[to.row][to.col]; // Might be null
    
    // Create a mutable copy of the board
    final newBoard = List<List<ChessPiece?>>.from(
      state.board.map((row) => List<ChessPiece?>.from(row)),
    );

    if (_isCastlingMove(movingPiece, from, to)) {
      return _handleCastlingLogic(state, movingPiece, from, to, newBoard);
    }

    if (_isEnPassantMove(state, movingPiece, from, to, capturedPiece)) {
      return _handleEnPassantLogic(state, movingPiece, from, to, newBoard);
    }

    if (_isPawnPromotion(movingPiece, to)) {
      return _handlePawnPromotionLogic(state, movingPiece, from, to, newBoard);
    }

    return _handleRegularMoveLogic(state, movingPiece, capturedPiece, from, to, newBoard);
  }
}
