import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/utils/chess_rules.dart';

void main() {
  group('Pawn Moves Tests', () {
    late List<List<ChessPiece?>> board;

    setUp(() {
      board = List.generate(8, (i) => List.generate(8, (j) => null));
    });

    test('initial pawn move should allow one or two steps forward', () {
      // White pawn at e2
      board[6][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      final moves = ChessRules.getValidMoves(board, const Position(row: 6, col: 4));
      expect(moves, containsAll([
        const Position(row: 5, col: 4), // e3
        const Position(row: 4, col: 4), // e4
      ]));
      expect(moves.length, 2);

      // Black pawn at d7
      board[1][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      final blackMoves = ChessRules.getValidMoves(board, const Position(row: 1, col: 3));
      expect(blackMoves, containsAll([
        const Position(row: 2, col: 3), // d6
        const Position(row: 3, col: 3), // d5
      ]));
      expect(blackMoves.length, 2);
    });

    test('pawn forward move should be blocked by another piece', () {
      // White pawn at e2, white piece at e3
      board[6][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[5][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white); // Blocker
      final moves = ChessRules.getValidMoves(board, const Position(row: 6, col: 4));
      expect(moves, isEmpty);
    });
    
    test('pawn capture moves diagonally', () {
      // White pawn at e4, black pawns at d5 and f5
      board[4][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black); // d5
      board[3][5] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black); // f5
      
      final moves = ChessRules.getValidMoves(board, const Position(row: 4, col: 4));
      expect(moves, containsAll([
        const Position(row: 3, col: 3), // Capture d5
        const Position(row: 3, col: 5), // Capture f5
      ]));
      // Should also contain forward move if e5 is empty
      expect(moves, contains(const Position(row: 3, col: 4))); // e5
      expect(moves.length, 3);
    });

    test('pawn should not capture own color piece', () {
      board[4][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white); // Own piece at d5
      final moves = ChessRules.getValidMoves(board, const Position(row: 4, col: 4));
      expect(moves.any((m) => m.row == 3 && m.col == 3), isFalse); // Cannot capture d5
      expect(moves, contains(const Position(row: 3, col: 4))); // Can still move to e5
    });

  });

  group('En Passant Tests', () {
    late List<List<ChessPiece?>> board;

    setUp(() {
      // 创建一个空棋盘
      board = List.generate(
        8,
        (i) => List.generate(8, (j) => null),
      );
    });

    test('should allow en passant capture after pawn double move', () {
      // 设置初始位置：
      // 白方兵在 (3, 4)，即 e5
      // 黑方兵在起始位置 (1, 3)，即 d7
      board[3][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      
      // 模拟黑方兵双步移动到 d5
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      
      // 获取白方兵的有效移动
      final validMoves = ChessRules.getValidMoves(
        board,
        const Position(row: 3, col: 4), // 白方兵的位置 e5
        lastPawnDoubleMoved: const Position(row: 3, col: 3), // 黑方兵的位置 d5
        lastPawnDoubleMovedNumber: 0,
        currentMoveNumber: 1,
      );

      // 期望吃过路兵位置：(2, 3)，即 d6
      final expectedEnPassantMove = const Position(row: 2, col: 3);

      // 验证可以吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isTrue,
        reason: '白方兵应该可以吃过路兵',
      );
    });

    test('should not allow en passant capture after other moves', () {
      // 设置相同的初始位置
      board[3][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 获取白方兵的有效移动，但不是在黑方兵刚移动两步后
      final validMoves = ChessRules.getValidMoves(
        board,
        const Position(row: 3, col: 4),
        lastPawnDoubleMoved: const Position(row: 3, col: 3),
        lastPawnDoubleMovedNumber: 0,
        currentMoveNumber: 2, // 已经过了一步
      );

      // 期望的吃过路兵位置
      final expectedEnPassantMove = const Position(row: 2, col: 3);

      // 验证不能吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '不应���允许延迟的吃过路兵',
      );
    });

    test('should not allow en passant capture if pawn has not just moved', () {
      // 设置初始位置
      board[3][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 获取白方兵的有效移动，但没有最近的双步移动记录
      final validMoves = ChessRules.getValidMoves(
        board,
        const Position(row: 3, col: 4),
        lastPawnDoubleMoved: null,
        lastPawnDoubleMovedNumber: -1,
        currentMoveNumber: 1,
      );

      // 期望的吃过路兵位置
      final expectedEnPassantMove = const Position(row: 2, col: 3);

      // 验证不能吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '没有最近的双步移动记录时不应该允许吃过路兵',
      );
    });

    test('should only allow en passant capture by pawns', () {
      // 设置初始位置，但使用车而不是兵
      board[3][4] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 获取白方车的有效移动
      final validMoves = ChessRules.getValidMoves(
        board,
        const Position(row: 3, col: 4),
        lastPawnDoubleMoved: const Position(row: 3, col: 3),
        lastPawnDoubleMovedNumber: 0,
        currentMoveNumber: 1,
      );

      // 期望的吃过路兵位置
      final expectedEnPassantMove = const Position(row: 2, col: 3);

      // 验证不能吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '非兵不应该能够吃过路兵',
      );
    });

    test('should only allow en passant capture immediately after double move', () {
      // 设置初始位置
      board[3][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 获取白方兵的有效移动，但在双步移动后等待了一步
      final validMoves = ChessRules.getValidMoves(
        board,
        const Position(row: 3, col: 4),
        lastPawnDoubleMoved: const Position(row: 3, col: 3),
        lastPawnDoubleMovedNumber: 0,
        currentMoveNumber: 3, // 已经过了两步
      );

      // 期望的吃过路兵位置
      final expectedEnPassantMove = const Position(row: 2, col: 3);

      // 验证不能吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '不应该允许在双步移动后的第二步吃过路兵',
      );
    });
  });

  group('King Moves Tests', () {
    late List<List<ChessPiece?>> board;

    setUp(() {
      board = List.generate(8, (i) => List.generate(8, (j) => null));
    });

    test('standard king moves', () {
      board[3][3] = const ChessPiece(type: PieceType.king, color: PieceColor.white); // King at d4
      final moves = ChessRules.getValidMoves(board, const Position(row: 3, col: 3));
      expect(moves, containsAll([
        const Position(row: 2, col: 2), const Position(row: 2, col: 3), const Position(row: 2, col: 4),
        const Position(row: 3, col: 2),                             const Position(row: 3, col: 4),
        const Position(row: 4, col: 2), const Position(row: 4, col: 3), const Position(row: 4, col: 4),
      ]));
      expect(moves.length, 8);
    });

    test('king moves blocked by own pieces', () {
      board[3][3] = const ChessPiece(type: PieceType.king, color: PieceColor.white); // King at d4
      board[2][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white); // Own pawn at d3 (blocks forward)
      final moves = ChessRules.getValidMoves(board, const Position(row: 3, col: 3));
      expect(moves.length, 7); // Should not contain (2,3)
      expect(moves.any((m) => m.row == 2 && m.col == 3), isFalse);
    });

    test('king captures opponent pieces', () {
      board[3][3] = const ChessPiece(type: PieceType.king, color: PieceColor.white); // King at d4
      board[2][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black); // Opponent pawn at d3
      final moves = ChessRules.getValidMoves(board, const Position(row: 3, col: 3));
      expect(moves, contains(const Position(row: 2, col: 3))); // Can capture d3
      expect(moves.length, 8);
    });

    group('Castling', () {
      Map<PieceColor, bool> hasKingMoved = {PieceColor.white: false, PieceColor.black: false};
      Map<PieceColor, Map<String, bool>> hasRookMoved = {
        PieceColor.white: {'kingside': false, 'queenside': false},
        PieceColor.black: {'kingside': false, 'queenside': false},
      };

      setUp((){
        // Reset castling flags for each test
        hasKingMoved = {PieceColor.white: false, PieceColor.black: false};
        hasRookMoved = {
          PieceColor.white: {'kingside': false, 'queenside': false},
          PieceColor.black: {'kingside': false, 'queenside': false},
        };
      });
      
      test('should allow kingside castling if conditions met', () {
        board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white); // Ke1
        board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white); // Rh1
        // Path e1-h1 is clear (f1, g1 are null)
        final moves = ChessRules.getValidMoves(
          board, const Position(row: 7, col: 4), 
          hasKingMoved: hasKingMoved, hasRookMoved: hasRookMoved
        );
        expect(moves, contains(const Position(row: 7, col: 6))); // Kg1
      });

      test('should allow queenside castling if conditions met', () {
        board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white); // Ke1
        board[7][0] = const ChessPiece(type: PieceType.rook, color: PieceColor.white); // Ra1
        // Path e1-a1 is clear (b1, c1, d1 are null)
        final moves = ChessRules.getValidMoves(
          board, const Position(row: 7, col: 4),
          hasKingMoved: hasKingMoved, hasRookMoved: hasRookMoved
        );
        expect(moves, contains(const Position(row: 7, col: 2))); // Kc1
      });

      test('should not allow castling if king has moved', () {
        hasKingMoved[PieceColor.white] = true;
        board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
        board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
        final moves = ChessRules.getValidMoves(
          board, const Position(row: 7, col: 4),
          hasKingMoved: hasKingMoved, hasRookMoved: hasRookMoved
        );
        expect(moves.any((m) => m.col == 6 || m.col == 2), isFalse);
      });

      test('should not allow kingside castling if kingside rook has moved', () {
        hasRookMoved[PieceColor.white]?['kingside'] = true;
        board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
        board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
        final moves = ChessRules.getValidMoves(
          board, const Position(row: 7, col: 4),
          hasKingMoved: hasKingMoved, hasRookMoved: hasRookMoved
        );
        expect(moves.any((m) => m.row == 7 && m.col == 6), isFalse);
      });
      
      test('should not allow castling if path is blocked', () {
        board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
        board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
        board[7][5] = const ChessPiece(type: PieceType.bishop, color: PieceColor.white); // Bishop on f1
        final moves = ChessRules.getValidMoves(
          board, const Position(row: 7, col: 4),
          hasKingMoved: hasKingMoved, hasRookMoved: hasRookMoved
        );
        expect(moves.any((m) => m.row == 7 && m.col == 6), isFalse);
      });

      test('should not allow castling if king is in check', () {
        board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white); // Ke1
        board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white); // Rh1
        board[0][4] = const ChessPiece(type: PieceType.rook, color: PieceColor.black); // Black rook on e8, checking Ke1
        
        final moves = ChessRules.getValidMoves(
          board, const Position(row: 7, col: 4),
          hasKingMoved: hasKingMoved, hasRookMoved: hasRookMoved
        );
        // King must move out of check, castling not allowed.
        expect(moves.any((m) => (m.row == 7 && m.col == 6) || (m.row == 7 && m.col ==2)), isFalse);
      });
      
      test('should not allow castling if king passes through an attacked square', () {
        board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white); // Ke1
        board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white); // Rh1
        board[0][5] = const ChessPiece(type: PieceType.rook, color: PieceColor.black); // Black rook on f8, attacking f1 (square king passes)

        final moves = ChessRules.getValidMoves(
          board, const Position(row: 7, col: 4),
          hasKingMoved: hasKingMoved, hasRookMoved: hasRookMoved
        );
        expect(moves.any((m) => m.row == 7 && m.col == 6), isFalse); // Kingside castling should be invalid
      });
    });
  });

  group('Check, Checkmate, and Stalemate Tests', () {
    late List<List<ChessPiece?>> board;
    Map<PieceColor, bool> hasKingMoved = {PieceColor.white: false, PieceColor.black: false};
    Map<PieceColor, Map<String, bool>> hasRookMoved = {
      PieceColor.white: {'kingside': false, 'queenside': false},
      PieceColor.black: {'kingside': false, 'queenside': false},
    };
    Map<PieceColor, Position?> lastPawnDoubleMoved = {PieceColor.white: null, PieceColor.black: null};
    Map<PieceColor, int> lastPawnDoubleMovedNumber = {PieceColor.white: -1, PieceColor.black: -1};
    int currentMoveNumber = 1;


    setUp(() {
      board = List.generate(8, (i) => List.generate(8, (j) => null));
      // Reset castling and en passant flags for each test, though not all tests use them explicitly.
      hasKingMoved = {PieceColor.white: false, PieceColor.black: false};
      hasRookMoved = {
        PieceColor.white: {'kingside': false, 'queenside': false},
        PieceColor.black: {'kingside': false, 'queenside': false},
      };
      lastPawnDoubleMoved = {PieceColor.white: null, PieceColor.black: null};
      lastPawnDoubleMovedNumber = {PieceColor.white: -1, PieceColor.black: -1};
      currentMoveNumber = 1;
    });

    test('isInCheck - by Queen', () {
      board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black); // Ke8
      board[0][3] = const ChessPiece(type: PieceType.queen, color: PieceColor.white); // Qd8 check
      expect(ChessRules.isInCheck(board, PieceColor.black), isTrue);
    });

    test('isInCheck - by Rook', () {
      board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black); // Ke8
      board[0][0] = const ChessPiece(type: PieceType.rook, color: PieceColor.white); // Ra8 check
      expect(ChessRules.isInCheck(board, PieceColor.black), isTrue);
    });
    
    test('isInCheck - by Knight', () {
      board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black); // Ke8
      board[2][5] = const ChessPiece(type: PieceType.knight, color: PieceColor.white); // Nf6 check
      expect(ChessRules.isInCheck(board, PieceColor.black), isTrue);
    });

    test('isNotInCheck - safe king', () {
      board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black); // Ke8
      board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white); // Ke1
      expect(ChessRules.isInCheck(board, PieceColor.black), isFalse);
      expect(ChessRules.isInCheck(board, PieceColor.white), isFalse);
    });

    test('isCheckmate - Fool\'s Mate like scenario', () {
      //   k . . . . . . . (row 0)
      //   . . . . p . . . (row 1) p at e7
      //   . . . . . . . . (row 2)
      //   . . . . . . . . (row 3)
      //   . . . . . . Q . (row 4) White Q at h4
      //   . . . . . P . . (row 5) White P at f3
      //   . . . . . . P . (row 6) White P at g2 -> this should be g4 for mate
      //   . . . . K . . . (row 7)
      // Corrected Fool's Mate setup (Black King mated by White Queen)
      // White: Ke1, Qf3 (to h5), Pg2, Ph2
      // Black: Ke8, Pf7, Pg7
      // 1. g4 e5 2. f3?? Qh4#
      board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white); // Ke1
      board[6][5] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white); // f2 -> f3 (after black e5)
      board[4][6] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white); // g2 -> g4
      
      board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black); // Ke8
      // board[1][4] = ChessPiece(type: PieceType.pawn, color: PieceColor.black); // Pe7 -> e5
      board[4][7] = const ChessPiece(type: PieceType.queen, color: PieceColor.white); // Qh4 (White Queen delivering mate)
      
      // Set current player to Black, who is checkmated
      expect(ChessRules.isCheckmate(board, PieceColor.black, hasKingMoved, hasRookMoved, lastPawnDoubleMoved, lastPawnDoubleMovedNumber, currentMoveNumber), isTrue);
    });
    
    test('isCheckmate - Back Rank Mate', () {
      // White King g1, Pawns f2,g2,h2. Black Rook d1. Black King h8.
      board[7][6] = const ChessPiece(type: PieceType.king, color: PieceColor.white);   // Kg1
      board[6][5] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);   // Pf2
      board[6][6] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);   // Pg2
      board[6][7] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);   // Ph2
      board[0][3] = const ChessPiece(type: PieceType.rook, color: PieceColor.black);   // Black Rook at d8 (moves to d1)
      board[0][7] = const ChessPiece(type: PieceType.king, color: PieceColor.black);   // Kh8

      // Simulate rook moving to d1 to deliver mate
      board[7][3] = board[0][3]; // Rook moves to d1
      board[0][3] = null;

      expect(ChessRules.isCheckmate(board, PieceColor.white, hasKingMoved, hasRookMoved, lastPawnDoubleMoved, lastPawnDoubleMovedNumber, currentMoveNumber), isTrue);
    });

    test('isNotCheckmate - check but can escape', () {
      board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black); // Ke8
      board[0][3] = const ChessPiece(type: PieceType.queen, color: PieceColor.white); // Qd8 check
      // Black king can move to f8 (0,5) or d7 (1,3) if e7 is not blocked
      expect(ChessRules.isCheckmate(board, PieceColor.black, hasKingMoved, hasRookMoved, lastPawnDoubleMoved, lastPawnDoubleMovedNumber, currentMoveNumber), isFalse);
    });

    test('isStalemate - King trapped, no check, no legal moves', () {
      // White King at a1, White Pawns at a2, b2. Black Queen at c2.
      board[7][0] = const ChessPiece(type: PieceType.king, color: PieceColor.white);   // Ka1
      board[6][0] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);   // Pa2
      board[6][1] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);   // Pb2
      board[5][2] = const ChessPiece(type: PieceType.queen, color: PieceColor.black); // Black Qc2
      board[0][7] = const ChessPiece(type: PieceType.king, color: PieceColor.black);   // Kh8 (opponent king)

      // It's White's turn, White is not in check, but has no legal moves.
      expect(ChessRules.isStalemate(board, PieceColor.white, hasKingMoved, hasRookMoved, lastPawnDoubleMoved, lastPawnDoubleMovedNumber, currentMoveNumber), isTrue);
    });
    
    test('isNotStalemate - legal moves exist', () {
      board[7][0] = const ChessPiece(type: PieceType.king, color: PieceColor.white);   // Ka1
      // Queen not trapping, e.g. at h2
      board[6][7] = const ChessPiece(type: PieceType.queen, color: PieceColor.black); // Qh2
      board[0][7] = const ChessPiece(type: PieceType.king, color: PieceColor.black);   // Kh8
      // White king can move to b1
      expect(ChessRules.isStalemate(board, PieceColor.white, hasKingMoved, hasRookMoved, lastPawnDoubleMoved, lastPawnDoubleMovedNumber, currentMoveNumber), isFalse);
    });
  });
} 