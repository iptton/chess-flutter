import 'package:flutter_test/flutter_test.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart'; // May not be needed directly, but good for context
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/services/game_logic_service.dart';
import 'package:testflutter/utils/chess_rules.dart'; // May be needed for some setups or direct rule checks

void main() {
  late GameLogicService gameLogicService;

  setUp(() {
    gameLogicService = GameLogicService();
  });

  group('GameLogicService Tests', () {
    // --- applyMove Tests ---
    group('applyMove', () {
      test('should correctly move a pawn one step forward', () {
        GameState initialState = GameState.initial();
        // Example: White pawn from e2 to e3 (assuming e2 is (6,4) and e3 is (5,4) in 0-indexed)
        final from = Position(row: 6, col: 4);
        final to = Position(row: 5, col: 4);
        final piece = initialState.board[from.row][from.col]!;
        
        final move = ChessMove(from: from, to: to, piece: piece);
        GameState newState = gameLogicService.applyMove(initialState, move);

        expect(newState.board[to.row][to.col], equals(piece));
        expect(newState.board[from.row][from.col], isNull);
        expect(newState.currentPlayer, PieceColor.black);
        expect(newState.moveHistory.last, equals(move));
      });

      test('should correctly move a pawn two steps forward initially', () {
        GameState initialState = GameState.initial();
        final from = Position(row: 6, col: 4); // e2
        final to = Position(row: 4, col: 4);   // e4
        final piece = initialState.board[from.row][from.col]!;
        
        final move = ChessMove(from: from, to: to, piece: piece);
        GameState newState = gameLogicService.applyMove(initialState, move);

        expect(newState.board[to.row][to.col], equals(piece));
        expect(newState.board[from.row][from.col], isNull);
        expect(newState.currentPlayer, PieceColor.black);
      });
      
      test('should correctly capture a piece', () {
        GameState initialState = GameState.initial();
        // White Knight g1 to f3 (capture hypothetical black pawn on f3)
        // Setup: Place a black pawn on f3 (row 5, col 5)
        List<List<ChessPiece?>> board = List.from(initialState.board.map((row) => List.from(row)));
        board[5][5] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
        initialState = initialState.copyWith(board: board);

        final from = Position(row: 7, col: 6); // g1
        final to = Position(row: 5, col: 5);   // f3
        final knight = initialState.board[from.row][from.col]!;
        final capturedPawn = initialState.board[to.row][to.col]!;
        
        final move = ChessMove(from: from, to: to, piece: knight, capturedPiece: capturedPawn);
        GameState newState = gameLogicService.applyMove(initialState, move);

        expect(newState.board[to.row][to.col]?.type, equals(PieceType.knight));
        expect(newState.board[to.row][to.col]?.color, equals(PieceColor.white));
        expect(newState.board[from.row][from.col], isNull);
        expect(newState.currentPlayer, PieceColor.black);
        expect(newState.moveHistory.last.capturedPiece, equals(capturedPawn));
      });

      test('applyMove should update board for kingside castling', () {
        GameState initialState = GameState.initial();
        // Simulate a state where white kingside castling is possible
        // Clear e1-g1 path: board[7][5] (f1), board[7][6] (g1) are null
        List<List<ChessPiece?>> board = List.from(initialState.board.map((row) => List.from(row)));
        board[7][5] = null; // Clear f1
        board[7][6] = null; // Clear g1
        initialState = initialState.copyWith(board: board);

        final king = initialState.board[7][4]!; // King at e1
        final move = ChessMove(
          from: Position(row: 7, col: 4), // e1
          to: Position(row: 7, col: 6),   // g1 (king's destination)
          piece: king,
          isCastling: true,
        );
        GameState newState = gameLogicService.applyMove(initialState, move);

        expect(newState.board[7][6]?.type, PieceType.king); // King at g1
        expect(newState.board[7][5]?.type, PieceType.rook); // Rook at f1
        expect(newState.board[7][4], isNull); // e1 empty
        expect(newState.board[7][7], isNull); // h1 empty (original rook pos)
      });

      test('applyMove should update board for queenside castling', () {
        GameState initialState = GameState.initial();
        // Simulate a state where white queenside castling is possible
        List<List<ChessPiece?>> board = List.from(initialState.board.map((row) => List.from(row)));
        board[7][1] = null; // Clear b1
        board[7][2] = null; // Clear c1
        board[7][3] = null; // Clear d1
        initialState = initialState.copyWith(board: board);
        
        final king = initialState.board[7][4]!; // King at e1
        final move = ChessMove(
          from: Position(row: 7, col: 4), // e1
          to: Position(row: 7, col: 2),   // c1 (king's destination)
          piece: king,
          isCastling: true,
        );
        GameState newState = gameLogicService.applyMove(initialState, move);

        expect(newState.board[7][2]?.type, PieceType.king); // King at c1
        expect(newState.board[7][3]?.type, PieceType.rook); // Rook at d1
        expect(newState.board[7][4], isNull); // e1 empty
        expect(newState.board[7][0], isNull); // a1 empty (original rook pos)
      });
      
      test('applyMove should handle en passant capture board update', () {
        // Setup: White pawn at e5, Black pawn at d5 (just moved from d7)
        // White to capture d5 en passant by moving e5 to d6
        List<List<ChessPiece?>> board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        final whitePawn = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        final blackPawn = ChessPiece(type: PieceType.pawn, color: PieceColor.black);
        board[3][4] = whitePawn; // White pawn at e5 (row 3, col 4)
        board[3][3] = blackPawn; // Black pawn at d5 (row 3, col 3) - this is the one to be captured

        GameState initialState = GameState.initial().copyWith(
          board: board,
          currentPlayer: PieceColor.white,
          lastPawnDoubleMoved: {PieceColor.black: Position(row:3, col:3)}, // Black pawn at d5 just double moved
          lastPawnDoubleMovedNumber: {PieceColor.black: 0}, // Assuming this was move 0 for black
          currentMoveNumber: 1 // White's current move number
        );
        
        final move = ChessMove(
          from: Position(row: 3, col: 4), // e5
          to: Position(row: 2, col: 3),   // d6 (target square for white pawn)
          piece: whitePawn,
          capturedPiece: blackPawn, // The pawn at d5 is captured
          isEnPassant: true,
        );
        GameState newState = gameLogicService.applyMove(initialState, move);

        expect(newState.board[2][3], equals(whitePawn)); // White pawn at d6
        expect(newState.board[3][4], isNull);             // e5 is empty
        expect(newState.board[3][3], isNull);             // d5 (captured black pawn) is empty
      });

      test('applyMove should update board for pawn promotion', () {
        // White pawn at e7, moving to e8, promoting to Queen
        List<List<ChessPiece?>> board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        final whitePawn = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        board[1][4] = whitePawn; // White pawn at e7 (row 1, col 4)
        GameState initialState = GameState.initial().copyWith(board: board, currentPlayer: PieceColor.white);

        final move = ChessMove(
          from: Position(row: 1, col: 4), // e7
          to: Position(row: 0, col: 4),   // e8
          piece: whitePawn,
          isPromotion: true,
          promotionType: PieceType.queen,
        );
        GameState newState = gameLogicService.applyMove(initialState, move);
        
        expect(newState.board[0][4]?.type, PieceType.queen);
        expect(newState.board[0][4]?.color, PieceColor.white);
        expect(newState.board[1][4], isNull);
      });

    });

    // --- getValidMovesForPiece Tests ---
    group('getValidMovesForPiece', () {
      test('should return empty list for a piece with no valid moves (e.g., blocked pawn)', () {
        // rnbqkbnr/pppppppp/8/8/8/P7/1PPPPPPP/RNBQKBNR w KQkq - 0 1 (a3 blocks a2 pawn)
        List<List<ChessPiece?>> board = boardFromFEN('rnbqkbnr/pppppppp/8/8/8/P7/1PPPPPPP/RNBQKBNR w KQkq - 0 1');
        // Manually place a white pawn at a2, and another white pawn at a3, blocking it.
        board[6][0] = ChessPiece(type: PieceType.pawn, color: PieceColor.white); // a2
        board[5][0] = ChessPiece(type: PieceType.pawn, color: PieceColor.white); // a3
        
        GameState state = GameState.initial().copyWith(board: board, currentPlayer: PieceColor.white);
        final moves = gameLogicService.getValidMovesForPiece(state, Position(row: 6, col: 0));
        expect(moves, isEmpty);
      });

      test('should return correct initial moves for a pawn', () {
        GameState state = GameState.initial(); // Standard starting board
        final moves = gameLogicService.getValidMovesForPiece(state, Position(row: 6, col: 4)); // e2 pawn
        expect(moves, containsAll([Position(row: 5, col: 4), Position(row: 4, col: 4)])); // e3, e4
        expect(moves.length, 2);
      });

      test('should return empty list if not player\'s turn', () {
        GameState state = GameState.initial().copyWith(currentPlayer: PieceColor.black); // Black's turn
        final moves = gameLogicService.getValidMovesForPiece(state, Position(row: 6, col: 4)); // White e2 pawn
        expect(moves, isEmpty);
      });

      test('should return empty list if game is over (checkmate)', () {
        GameState state = GameState.initial().copyWith(isCheckmate: true);
        final moves = gameLogicService.getValidMovesForPiece(state, Position(row: 6, col: 4));
        expect(moves, isEmpty);
      });
      
      test('should return correct moves for a knight', () {
        GameState state = GameState.initial();
        final moves = gameLogicService.getValidMovesForPiece(state, Position(row: 7, col: 6)); // Knight at g1
        expect(moves, containsAll([Position(row: 5, col: 5), Position(row: 5, col: 7)])); // f3, h3
        expect(moves.length, 2);
      });

      test('should include castling moves for king if available', () {
        // Setup board for castling: clear pieces between king and rook
        List<List<ChessPiece?>> board = boardFromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1');
        board[7][5] = null; // f1
        board[7][6] = null; // g1
        board[7][1] = null; // b1
        board[7][2] = null; // c1
        board[7][3] = null; // d1

        GameState state = GameState.initial().copyWith(
          board: board,
          currentPlayer: PieceColor.white,
          hasKingMoved: {PieceColor.white: false, PieceColor.black: false},
          hasRookMoved: {
            PieceColor.white: {'kingside': false, 'queenside': false},
            PieceColor.black: {'kingside': false, 'queenside': false}
          }
        );
        final moves = gameLogicService.getValidMovesForPiece(state, Position(row: 7, col: 4)); // King at e1
        
        // Standard king moves: d1, d2, e2, f2, f1 (if not attacked)
        // Castling moves: c1 (col 2), g1 (col 6)
        // Depending on ChessRules implementation, it might return only direct king moves or also castling pseudo-moves
        // Assuming ChessRules.getValidMoves includes castling destinations for the king
        expect(moves, anyOf(
          contains(Position(row: 7, col: 6)), // Kingside castle to g1
          contains(Position(row: 7, col: 2))  // Queenside castle to c1
        ));
      });
      
      test('should include en passant capture if available for a pawn', () {
        // Setup: White pawn at e5, Black pawn at d5 (just moved from d7)
        List<List<ChessPiece?>> board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        board[3][4] = ChessPiece(type: PieceType.pawn, color: PieceColor.white); // White pawn at e5
        board[3][3] = ChessPiece(type: PieceType.pawn, color: PieceColor.black); // Black pawn at d5
        
        GameState state = GameState.initial().copyWith(
          board: board,
          currentPlayer: PieceColor.white,
          lastPawnDoubleMoved: {PieceColor.black: Position(row:3, col:3)},
          lastPawnDoubleMovedNumber: {PieceColor.black: 0}, // Black's last move number
          currentMoveNumber: 1 // White's current move number (black just moved)
        );

        final moves = gameLogicService.getValidMovesForPiece(state, Position(row: 3, col: 4)); // White pawn at e5
        // Valid moves should include:
        // - e6 (forward)
        // - d6 (en passant capture)
        expect(moves, contains(Position(row: 2, col: 4))); // e6
        expect(moves, contains(Position(row: 2, col: 3))); // d6 (en passant)
      });

    });

    // --- handleMove Tests ---
    group('handleMove', () {
      test('handleMove for a regular pawn move', () {
        GameState initialState = GameState.initial();
        // Select e2 pawn, then move to e4
        initialState = initialState.copyWith(
          selectedPosition: Position(row: 6, col: 4),
          validMoves: [Position(row: 5, col: 4), Position(row: 4, col: 4)] // Assume these are pre-calculated
        );
        
        GameState newState = gameLogicService.handleMove(initialState, Position(row: 6, col: 4), Position(row: 4, col: 4));

        expect(newState.board[4][4]?.type, PieceType.pawn);
        expect(newState.board[6][4], isNull);
        expect(newState.currentPlayer, PieceColor.black);
        expect(newState.lastMove?.from, Position(row: 6, col: 4));
        expect(newState.lastMove?.to, Position(row: 4, col: 4));
        expect(newState.lastPawnDoubleMoved[PieceColor.white], Position(row: 4, col: 4));
      });

      test('handleMove for a knight capture', () {
        List<List<ChessPiece?>> board = boardFromFEN('rnbqkb1r/pppppppp/5n2/8/8/5N2/PPPPPPPP/RNBQKB1R w KQkq - 2 2'); // Knight on f3, f6
        // Place a black pawn on g5 for white knight on f3 to capture
        board[3][6] = ChessPiece(type: PieceType.pawn, color: PieceColor.black); // Black pawn at g5
        
        GameState initialState = GameState.initial().copyWith(
          board: board, 
          currentPlayer: PieceColor.white,
          selectedPosition: Position(row: 5, col: 5), // White Knight at f3 (assuming FEN maps f3 to 5,5)
                                                        // Correcting FEN interpretation to 0-indexed:
                                                        // f3 is (7-3=4, 5) or (5,5) if board is visually [0..7] top to bottom
                                                        // Standard array: row 5, col 5 for f3 (assuming RNBQKB1R is row 7)
                                                        // Let's use standard initial board and place knight and target
        );
        
        // Re-setup for clarity: White Knight on e4, Black pawn on d6
        board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        final whiteKnight = ChessPiece(type: PieceType.knight, color: PieceColor.white);
        final blackPawn = ChessPiece(type: PieceType.pawn, color: PieceColor.black);
        board[4][4] = whiteKnight; // White knight at e4
        board[2][3] = blackPawn;   // Black pawn at d6

        initialState = GameState.initial().copyWith(
            board: board,
            currentPlayer: PieceColor.white,
            selectedPosition: Position(row: 4, col: 4), // White knight at e4
            validMoves: [Position(row:2, col:3)] // Assume d6 is a valid move
        );

        GameState newState = gameLogicService.handleMove(initialState, Position(row: 4, col: 4), Position(row: 2, col: 3));
        
        expect(newState.board[2][3]?.type, PieceType.knight);
        expect(newState.board[2][3]?.color, PieceColor.white);
        expect(newState.board[4][4], isNull);
        expect(newState.lastMove?.capturedPiece, equals(blackPawn));
      });

      test('handleMove for valid kingside castling', () {
        List<List<ChessPiece?>> board = boardFromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1');
        board[7][5] = null; // f1
        board[7][6] = null; // g1
        GameState initialState = GameState.initial().copyWith(
            board: board,
            currentPlayer: PieceColor.white,
            hasKingMoved: {PieceColor.white: false, PieceColor.black: false},
            hasRookMoved: {PieceColor.white: {'kingside': false, 'queenside': false}, PieceColor.black: {'kingside': false, 'queenside': false}},
            selectedPosition: Position(row: 7, col: 4), // King at e1
            validMoves: [Position(row: 7, col: 6)] // Assume g1 is a valid castling move
        );

        GameState newState = gameLogicService.handleMove(initialState, Position(row: 7, col: 4), Position(row: 7, col: 6));

        expect(newState.board[7][6]?.type, PieceType.king);
        expect(newState.board[7][5]?.type, PieceType.rook);
        expect(newState.hasKingMoved[PieceColor.white], isTrue);
        expect(newState.hasRookMoved[PieceColor.white]?['kingside'], isTrue);
        expect(newState.lastMove?.isCastling, isTrue);
      });
      
      test('handleMove should set isPendingPromotion for pawn reaching promotion rank', () {
        // White pawn at e7, to move to e8
        List<List<ChessPiece?>> board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        final whitePawn = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        board[1][4] = whitePawn; // White pawn at e7 (row 1, col 4)
        
        GameState initialState = GameState.initial().copyWith(
            board: board, 
            currentPlayer: PieceColor.white,
            selectedPosition: Position(row: 1, col: 4),
            validMoves: [Position(row: 0, col: 4)] // e8 is valid
        );

        GameState newState = gameLogicService.handleMove(initialState, Position(row: 1, col: 4), Position(row: 0, col: 4));

        expect(newState.isPendingPromotion, isTrue);
        expect(newState.promotionPosition, Position(row: 0, col: 4));
        expect(newState.board[0][4]?.type, PieceType.pawn); // Still a pawn until promotion is chosen
        expect(newState.currentPlayer, PieceColor.white); // Current player doesn't change yet
      });

      test('handleMove should not allow castling if king has moved', () {
        List<List<ChessPiece?>> board = boardFromFEN('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w KQkq - 0 1');
        board[7][5] = null; board[7][6] = null; // Clear path for kingside
        GameState initialState = GameState.initial().copyWith(
            board: board,
            currentPlayer: PieceColor.white,
            hasKingMoved: {PieceColor.white: true, PieceColor.black: false}, // King has moved
            hasRookMoved: {PieceColor.white: {'kingside': false, 'queenside': false}, PieceColor.black: {'kingside': false, 'queenside': false}},
            selectedPosition: Position(row: 7, col: 4),
            // getValidMovesForPiece would return no castling move here.
            // We simulate that handleMove is called with a castling attempt anyway to test its internal checks.
            // However, handleMove relies on getValidMovesForPiece for primary validation.
            // For a pure unit test of handleMove's own logic for castling, it assumes the move is "valid" per validMoves.
            // If ChessRules.getValidMoves correctly filters this, this test is more about the conditions handleMove itself checks.
            // The _isCastlingMove in GameLogicService doesn't check hasKingMoved flag directly, it's checked by ChessRules.
            // So, for handleMove to deny this, the validMoves list fed to it should not contain the castling move.
            // Let's assume validMoves is correctly empty for castling.
            validMoves: [Position(row:7, col:5)] // only a non-castling move
        );
        
        // Try to make a castling move that shouldn't be in validMoves.
        GameState newState = gameLogicService.handleMove(initialState, Position(row: 7, col: 4), Position(row: 7, col: 6));
        // Expect the state to not change to a castled state, or an error/specific message.
        // Given current handleMove structure, if (row:7, col:6) is not in validMoves, it returns early.
        expect(newState.board[7][6]?.type, isNot(PieceType.king)); // King should not be at g1
        expect(newState.lastMove?.isCastling, isNot(true));
        // More robust: check if board is unchanged or if a regular move to f1 (if valid) was made.
        // If (7,6) was not in validMoves, specialMoveMessage "Invalid move selected."
        expect(newState.specialMoveMessage, equals("Invalid move selected."));
      });
      
      test('handleMove for valid en passant', () {
        List<List<ChessPiece?>> board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        final whitePawn = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        final blackPawn = ChessPiece(type: PieceType.pawn, color: PieceColor.black);
        board[3][4] = whitePawn; // White pawn at e5
        board[3][3] = blackPawn; // Black pawn at d5 (this is the one that just moved from d7)

        GameState initialState = GameState.initial().copyWith(
          board: board,
          currentPlayer: PieceColor.white,
          selectedPosition: Position(row: 3, col: 4), // White pawn at e5
          lastPawnDoubleMoved: {PieceColor.white: null, PieceColor.black: Position(row: 3, col: 3)},
          lastPawnDoubleMovedNumber: {PieceColor.white: -1, PieceColor.black: 0}, // Black's move was #0
          currentMoveNumber: 1, // White is making move #1
          // ChessRules.getValidMoves should provide (2,3) as a valid en passant move
          validMoves: [Position(row:2, col:4), Position(row:2, col:3)] 
        );

        GameState newState = gameLogicService.handleMove(initialState, Position(row: 3, col: 4), Position(row: 2, col: 3)); // e5xd6 e.p.

        expect(newState.board[2][3], whitePawn); // White pawn moved to d6
        expect(newState.board[3][3], isNull);    // Black pawn at d5 captured
        expect(newState.board[3][4], isNull);    // Original white pawn square e5 is empty
        expect(newState.lastMove?.isEnPassant, isTrue);
        expect(newState.lastMove?.capturedPiece, blackPawn);
        expect(newState.currentPlayer, PieceColor.black);
      });

      test('handleMove should not perform en passant if conditions not met (e.g., not immediately after double step)', () {
        List<List<ChessPiece?>> board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        final whitePawn = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        board[3][4] = whitePawn; // White pawn at e5
        board[3][3] = ChessPiece(type: PieceType.pawn, color: PieceColor.black); // Black pawn at d5
        
        GameState initialState = GameState.initial().copyWith(
          board: board,
          currentPlayer: PieceColor.white,
          selectedPosition: Position(row: 3, col: 4),
          lastPawnDoubleMoved: {PieceColor.white: null, PieceColor.black: Position(row:3, col:3)},
          lastPawnDoubleMovedNumber: {PieceColor.white: -1, PieceColor.black: 0}, // Black's double step was move 0
          currentMoveNumber: 3, // More than 1 move has passed since black's double step
          validMoves: [Position(row:2, col:4)] // Only e6 is valid, not d6 en passant
        );

        // Attempt en passant even if not in validMoves (to test internal _isEnPassantMove if it were called directly)
        // However, handleMove will first check validMoves. If d6 is not there, it won't proceed.
        GameState newState = gameLogicService.handleMove(initialState, Position(row: 3, col: 4), Position(row: 2, col: 3));
        
        // Expect that en passant did not happen. Instead, "Invalid move selected." or regular move if d6 was somehow valid.
        // Based on validMoves provided, d6 is not valid.
        expect(newState.specialMoveMessage, equals("Invalid move selected."));
        expect(newState.board[2][3], isNull); // d6 should be empty
        expect(newState.board[3][3]?.type, PieceType.pawn); // Black pawn still at d5
      });

    });

    // --- completePawnPromotion Tests ---
    group('completePawnPromotion', () {
      late GameState pendingPromotionState;

      setUp(() {
        // Setup a state where white pawn is at e8 pending promotion
        List<List<ChessPiece?>> board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        final whitePawn = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        board[0][4] = whitePawn; // White pawn at e8 (after moving from e7)
        
        pendingPromotionState = GameState.initial().copyWith(
          board: board,
          currentPlayer: PieceColor.white, // Player hasn't switched yet in pending state
          isPendingPromotion: true,
          promotionPosition: Position(row: 0, col: 4),
          lastMove: ChessMove( // The move that led to promotion
            from: Position(row: 1, col: 4), 
            to: Position(row: 0, col: 4), 
            piece: whitePawn, // piece is the pawn before promotion
            isPromotion: true
          ),
          currentMoveNumber: 5 // Example move number
        );
      });

      test('should promote pawn to Queen and update state correctly', () {
        GameState newState = gameLogicService.completePawnPromotion(pendingPromotionState, PieceType.queen);

        expect(newState.board[0][4]?.type, PieceType.queen);
        expect(newState.board[0][4]?.color, PieceColor.white);
        expect(newState.isPendingPromotion, isFalse);
        expect(newState.promotionPosition, isNull);
        expect(newState.currentPlayer, PieceColor.black); // Player should switch
        expect(newState.lastMove?.promotionType, PieceType.queen);
        expect(newState.lastMove?.piece.type, PieceType.queen); // lastMove.piece should be the promoted piece
        expect(newState.moveHistory.last.promotionType, PieceType.queen);
        expect(newState.currentMoveNumber, equals(pendingPromotionState.currentMoveNumber + 1));
      });

      test('should promote pawn to Rook', () {
        GameState newState = gameLogicService.completePawnPromotion(pendingPromotionState, PieceType.rook);
        expect(newState.board[0][4]?.type, PieceType.rook);
        expect(newState.lastMove?.promotionType, PieceType.rook);
      });

      test('should promote pawn to Bishop', () {
        GameState newState = gameLogicService.completePawnPromotion(pendingPromotionState, PieceType.bishop);
        expect(newState.board[0][4]?.type, PieceType.bishop);
        expect(newState.lastMove?.promotionType, PieceType.bishop);
      });

      test('should promote pawn to Knight', () {
        GameState newState = gameLogicService.completePawnPromotion(pendingPromotionState, PieceType.knight);
        expect(newState.board[0][4]?.type, PieceType.knight);
        expect(newState.lastMove?.promotionType, PieceType.knight);
      });

      test('should clear isPendingPromotion and promotionPosition after promotion', () {
        GameState newState = gameLogicService.completePawnPromotion(pendingPromotionState, PieceType.queen);
        expect(newState.isPendingPromotion, isFalse);
        expect(newState.promotionPosition, isNull);
      });
      
      test('should add the completed promotion move to history', () {
        final initialHistoryLength = pendingPromotionState.moveHistory.length;
        GameState newState = gameLogicService.completePawnPromotion(pendingPromotionState, PieceType.queen);
        expect(newState.moveHistory.length, initialHistoryLength + 1);
        expect(newState.moveHistory.last.isPromotion, isTrue);
        expect(newState.moveHistory.last.promotionType, PieceType.queen);
      });
    });

    // --- Check/Checkmate/Stalemate Tests (via handleMove) ---
    group('Game End Conditions (via handleMove)', () {
      test('should set isCheck to true when a move results in check', () {
        // Setup: White Queen to deliver check to Black King.
        // Example: White Queen at d5, Black King at e8. Move Qd5-e6+
        // Simplified: Board with Q on d1, K on e8. Move Q to d8+.
        List<List<ChessPiece?>> board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        board[7][3] = ChessPiece(type: PieceType.queen, color: PieceColor.white); // White Queen at d1
        board[0][4] = ChessPiece(type: PieceType.king, color: PieceColor.black);  // Black King at e8
        board[7][4] = ChessPiece(type: PieceType.king, color: PieceColor.white);  // White King at e1 (to make it valid state)


        GameState initialState = GameState.initial().copyWith(
            board: board, 
            currentPlayer: PieceColor.white,
            selectedPosition: Position(row: 7, col: 3), // Qd1
            validMoves: [Position(row:0, col:3)] // Qd8 is a valid move
        );

        GameState newState = gameLogicService.handleMove(initialState, Position(row: 7, col: 3), Position(row: 0, col: 3)); // Qd1-d8+
        
        expect(newState.isCheck, isTrue);
        expect(newState.board[0][3]?.type, PieceType.queen);
        expect(newState.currentPlayer, PieceColor.black); // Turn switches to black
      });

      test('should set isCheckmate to true for a simple checkmate (Fool\'s Mate like)', () {
        // Simplified Fool's Mate:
        // 1. f3 e5
        // 2. g4 Qh4#
        // Board after 1. f3 e5; 2. g4 ??
        // White: Pawn f3, g4. King e1.
        // Black: Pawn e5. Queen d8. King e8.
        // Black to move Qh4#
        List<List<ChessPiece?>> board = boardFromFEN("rnb1kbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2");
        // FEN after 1.f3 e6 2.g4. Black to play Qh4#
        // rnb1kbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2
        // Actually, let's manually set it up for Qh4#
        // White: Ke1, Pf2, Pg2
        // Black: Ke8, Qd8
        // Scenario: White plays f2-f3, then g2-g4. Black plays e7-e5. Black Queen to h4 is mate.
        // Board state before Qh4#:
        // White: Ke1, Pf3, Pg4
        // Black: Ke8, Pe5, Qd8
        // RNBQKBNR/PPPP1PPP/8/4P3/6p1/5p2/P1PPP2P/1B1Q1BNR b KQkq - 0 2 (Incorrect FEN)
        
        // Manual board setup for Black Qh4#
        // White pieces: King e1, Pawn f3, Pawn g4
        // Black pieces: King e8, Queen d8, Pawn e7 (to make e5 later)
        board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        board[7][4] = ChessPiece(type: PieceType.king, color: PieceColor.white); // Ke1
        board[5][5] = ChessPiece(type: PieceType.pawn, color: PieceColor.white); // Pf3 (row 5, col 5)
        board[4][6] = ChessPiece(type: PieceType.pawn, color: PieceColor.white); // Pg4 (row 4, col 6)
        
        board[0][4] = ChessPiece(type: PieceType.king, color: PieceColor.black); // Ke8
        board[0][3] = ChessPiece(type: PieceType.queen, color: PieceColor.black); // Qd8
        board[1][4] = ChessPiece(type: PieceType.pawn, color: PieceColor.black); // Pe7
        
        GameState initialState = GameState.initial().copyWith(
          board: board,
          currentPlayer: PieceColor.black,
          selectedPosition: Position(row: 0, col: 3), // Black Queen at d8
          // Valid moves for Queen d8 should include h4 (row 4, col 7)
          // This requires that ChessRules.getValidMoves is working correctly for this state.
          // For simplicity, assume it's a valid move.
          validMoves: [Position(row:4, col:7)] 
        );
        
        // Black plays Qh4#
        GameState newState = gameLogicService.handleMove(initialState, Position(row: 0, col: 3), Position(row: 4, col: 7));
        
        expect(newState.isCheckmate, isTrue);
        expect(newState.isCheck, isTrue); // Checkmate implies check
        expect(newState.board[4][7]?.type, PieceType.queen); // Queen at h4
      });

      test('should set isStalemate to true for a simple stalemate', () {
        // King in corner, blocked by own pieces, not in check. Attacker controls escape squares.
        // White: Ka1, Pa2, Pb2. Black: Qc2. White to move.
        List<List<ChessPiece?>> board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        board[7][0] = ChessPiece(type: PieceType.king, color: PieceColor.white);   // Ka1
        board[6][0] = ChessPiece(type: PieceType.pawn, color: PieceColor.white);   // Pa2
        board[6][1] = ChessPiece(type: PieceType.pawn, color: PieceColor.white);   // Pb2
        board[5][2] = ChessPiece(type: PieceType.queen, color: PieceColor.black); // Black Qc2 (controls b1, a3)
        // Need a black king somewhere
        board[0][7] = ChessPiece(type: PieceType.king, color: PieceColor.black);   // Kh8


        GameState initialState = GameState.initial().copyWith(
          board: board,
          currentPlayer: PieceColor.white, // White to move
          selectedPosition: Position(row:7, col:0), // King at a1 selected
          // Assuming ChessRules will determine no valid moves for Ka1
          validMoves: [] 
        );
        
        // Simulate an attempt to move, or simply check state if no moves are possible.
        // If we try to move a piece that has no valid moves, handleMove might return current state or specific message.
        // The stalemate flag is set based on the *next* player having no legal moves *and* not being in check.
        // So, this setup is for when it's White's turn, White has no moves, and White is not in check.
        // GameLogicService's handleMove will update the state, and the check/stalemate conditions are evaluated for the *next* player.
        // This test might be better framed as: after black's move to Qc2, it's white's turn, and white is stalemated.
        // Let's adjust: Black just moved to Qc2. It's White's turn.
        // The state passed to handleMove would be *before* black's move to Qc2.
        // The test should be: GameState where current player (White) has no legal moves and is not in check.
        // This is typically determined by ChessRules.isStalemate called by GameLogicService.
        
        // For this test, we'll construct a state that IS a stalemate for White.
        // GameLogicService.handleMove is called when Black makes a move that *results* in this stalemate for White.
        // So, let's assume Black just moved their Queen to c2.
        // The state *before* Black's move:
        List<List<ChessPiece?>> boardBeforeBlackMove = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
        boardBeforeBlackMove[7][0] = ChessPiece(type: PieceType.king, color: PieceColor.white);   // Ka1
        boardBeforeBlackMove[6][0] = ChessPiece(type: PieceType.pawn, color: PieceColor.white);   // Pa2
        boardBeforeBlackMove[6][1] = ChessPiece(type: PieceType.pawn, color: PieceColor.white);   // Pb2
        boardBeforeBlackMove[0][7] = ChessPiece(type: PieceType.king, color: PieceColor.black);   // Kh8
        boardBeforeBlackMove[0][2] = ChessPiece(type: PieceType.queen, color: PieceColor.black); // Black Qc7 (example)

        GameState stateBeforeBlackMakesStalematingMove = GameState.initial().copyWith(
            board: boardBeforeBlackMove,
            currentPlayer: PieceColor.black, // Black to move to c2
            selectedPosition: Position(row:0, col:2), // Qc7
            validMoves: [Position(row:5, col:2)] // Qc2 is valid
        );
        
        GameState newStateAfterBlackMoves = gameLogicService.handleMove(stateBeforeBlackMakesStalematingMove, Position(row:0, col:2), Position(row:5, col:2));

        // Now, newStateAfterBlackMoves is the state where it's White's turn.
        // We expect isStalemate to be true because White (king at a1) has no legal moves and is not in check.
        expect(newStateAfterBlackMoves.isStalemate, isTrue);
        expect(newStateAfterBlackMoves.isCheck, isFalse); // Important for stalemate
        expect(newStateAfterBlackMoves.currentPlayer, PieceColor.white); // It's white's turn
      });
    });
  });
}

// Helper to create a board from a string representation (optional, but useful)
// Example: 
// rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
// For simplicity, we might manually construct boards in tests or use GameState.initial()
// and apply a series of moves.
List<List<ChessPiece?>> boardFromFEN(String fen) {
  // Basic FEN parsing for board state - can be expanded
  final parts = fen.split(' ');
  final boardRows = parts[0].split('/');
  final newBoard = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));

  for (int r = 0; r < 8; r++) {
    int c = 0;
    for (int i = 0; i < boardRows[r].length; i++) {
      final char = boardRows[r][i];
      if (int.tryParse(char) != null) {
        c += int.parse(char);
      } else {
        newBoard[r][c] = _pieceFromChar(char);
        c++;
      }
    }
  }
  return newBoard;
}

ChessPiece? _pieceFromChar(String char) {
  PieceColor color = char.toUpperCase() == char ? PieceColor.white : PieceColor.black;
  switch (char.toLowerCase()) {
    case 'p': return ChessPiece(type: PieceType.pawn, color: color);
    case 'r': return ChessPiece(type: PieceType.rook, color: color);
    case 'n': return ChessPiece(type: PieceType.knight, color: color);
    case 'b': return ChessPiece(type: PieceType.bishop, color: color);
    case 'q': return ChessPiece(type: PieceType.queen, color: color);
    case 'k': return ChessPiece(type: PieceType.king, color: color);
    default: return null;
  }
}
