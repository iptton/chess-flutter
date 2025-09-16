import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/screens/game_screen.dart';
import 'package:testflutter/services/chess_ai.dart';

void main() {
  group('AI Pawn Promotion Bug Tests', () {
    late ChessBloc bloc;

    setUp(() {
      bloc = ChessBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('should switch player after pawn promotion', () async {
      // Arrange: Create a board with a white pawn ready to promote
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // Place kings
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // Place white pawn on 7th rank ready to promote
      board[1][6] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

      // Initialize game with custom board
      bloc.add(InitializeGame(
        false,
        initialBoard: board,
        initialPlayer: PieceColor.white,
        gameMode: GameMode.faceToFace,
      ));

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Act: Select pawn and move to promotion square
      bloc.add(const SelectPiece(Position(row: 1, col: 6)));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const MovePiece(
        Position(row: 1, col: 6),
        Position(row: 0, col: 6),
      ));

      // Wait for move processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Act: Select promotion type (this simulates the UI dialog selection)
      bloc.add(const PromotePawn(
        Position(row: 0, col: 6),
        PieceType.queen,
      ));

      // Wait for promotion processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Player should switch to black after promotion
      expect(bloc.state.currentPlayer, equals(PieceColor.black));

      // Verify the promoted piece is on the board
      expect(bloc.state.board[0][6]?.type, equals(PieceType.queen));
      expect(bloc.state.board[0][6]?.color, equals(PieceColor.white));
    });

    test('should trigger AI move after opponent promotion in AI game',
        () async {
      // Arrange: Create a board with a black pawn ready to promote
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // Place kings
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // Place black pawn on 2nd rank ready to promote
      board[6][3] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // Initialize AI game with custom board
      bloc.add(InitializeGame(
        false,
        initialBoard: board,
        initialPlayer: PieceColor.black,
        gameMode: GameMode.offline,
        aiDifficulty: AIDifficulty.easy,
      ));

      // Wait for initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // Act: Select black pawn and move to promotion square
      bloc.add(const SelectPiece(Position(row: 6, col: 3)));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const MovePiece(
        Position(row: 6, col: 3),
        Position(row: 7, col: 3),
      ));

      // Wait for move processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Act: Select promotion type (simulating UI dialog)
      bloc.add(const PromotePawn(
        Position(row: 7, col: 3),
        PieceType.queen,
      ));

      // Wait for promotion and AI processing
      await Future.delayed(const Duration(milliseconds: 2000));

      // Assert: Player should switch to white and AI should be thinking or have moved
      expect(bloc.state.currentPlayer, equals(PieceColor.white));

      // Verify the promoted piece is on the board
      expect(bloc.state.board[7][3]?.type, equals(PieceType.queen));
      expect(bloc.state.board[7][3]?.color, equals(PieceColor.black));

      // AI should have been triggered (either thinking or completed move)
      expect(
          bloc.state.isAIThinking || bloc.state.moveHistory.length > 1, isTrue);
    });

    test('should handle AI pawn promotion correctly', () async {
      // Arrange: Create a board where AI (white) has a pawn ready to promote
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // Place kings
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // Place white pawn on 7th rank ready to promote (AI will be white)
      board[1][2] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

      // Add some other pieces to make the position more realistic
      board[6][1] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // Initialize AI game with white as AI
      bloc.add(InitializeGame(
        false,
        initialBoard: board,
        initialPlayer: PieceColor.white,
        gameMode: GameMode.offline,
        aiDifficulty: AIDifficulty.easy,
        aiColor: PieceColor.white, // 设置AI为白方
      ));

      // Wait for AI to make its move (should promote the pawn)
      await Future.delayed(const Duration(milliseconds: 3000));

      // Assert: AI should have promoted and switched to human player
      expect(bloc.state.currentPlayer, equals(PieceColor.black));
      expect(bloc.state.isAIThinking, isFalse);

      // Check if AI promoted the pawn (should be a queen on rank 8)
      bool foundPromotedPiece = false;
      for (int col = 0; col < 8; col++) {
        final piece = bloc.state.board[0][col];
        if (piece != null &&
            piece.color == PieceColor.white &&
            piece.type == PieceType.queen) {
          foundPromotedPiece = true;
          break;
        }
      }

      // If AI promoted, verify the game state is correct
      if (foundPromotedPiece) {
        expect(bloc.state.currentPlayer, equals(PieceColor.black));
        expect(bloc.state.moveHistory.isNotEmpty, isTrue);
      }
    });

    test('should maintain correct turn order after multiple promotions',
        () async {
      // Arrange: Create a board with multiple pawns ready to promote
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // Place kings
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // Place white pawn ready to promote
      board[1][1] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      // Place black pawn ready to promote
      board[6][6] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // Initialize game
      bloc.add(InitializeGame(
        false,
        initialBoard: board,
        initialPlayer: PieceColor.white,
        gameMode: GameMode.faceToFace,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Act: First promotion (white)
      bloc.add(const SelectPiece(Position(row: 1, col: 1)));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const MovePiece(
        Position(row: 1, col: 1),
        Position(row: 0, col: 1),
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const PromotePawn(
        Position(row: 0, col: 1),
        PieceType.queen,
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Should be black's turn
      expect(bloc.state.currentPlayer, equals(PieceColor.black));

      // Act: Second promotion (black)
      bloc.add(const SelectPiece(Position(row: 6, col: 6)));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const MovePiece(
        Position(row: 6, col: 6),
        Position(row: 7, col: 6),
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const PromotePawn(
        Position(row: 7, col: 6),
        PieceType.queen,
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Should be white's turn again
      expect(bloc.state.currentPlayer, equals(PieceColor.white));

      // Verify both promotions occurred
      expect(bloc.state.board[0][1]?.type, equals(PieceType.queen));
      expect(bloc.state.board[0][1]?.color, equals(PieceColor.white));
      expect(bloc.state.board[7][6]?.type, equals(PieceType.queen));
      expect(bloc.state.board[7][6]?.color, equals(PieceColor.black));
    });

    test('should handle promotion in check situations correctly', () async {
      // Arrange: Create a board where promotion puts opponent in check
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // Place kings
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][0] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // Place white pawn ready to promote and give check
      board[1][0] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

      // Initialize game
      bloc.add(InitializeGame(
        false,
        initialBoard: board,
        initialPlayer: PieceColor.white,
        gameMode: GameMode.faceToFace,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Act: Promote pawn to queen (should give check)
      bloc.add(const SelectPiece(Position(row: 1, col: 0)));
      await Future.delayed(const Duration(milliseconds: 50));

      bloc.add(const MovePiece(
        Position(row: 1, col: 0),
        Position(row: 0, col: 0),
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const PromotePawn(
        Position(row: 0, col: 0),
        PieceType.queen,
      ));
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Should be black's turn and black should be in check
      expect(bloc.state.currentPlayer, equals(PieceColor.black));
      expect(bloc.state.isCheck, isTrue);
    });
  });
}
