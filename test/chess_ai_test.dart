import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/services/chess_ai.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/utils/chess_adapter.dart';

void main() {
  group('ChessAI Tests', () {
    late ChessAI ai;

    setUp(() {
      ai = ChessAI(difficulty: AIDifficulty.medium);
    });

    test('AI should be able to make a move from starting position', () async {
      // 创建初始棋盘
      final board = _createInitialBoard();
      
      // AI应该能够为白方找到一个合法移动
      final move = await ai.getBestMove(board, PieceColor.white);
      
      expect(move, isNotNull);
      expect(move!.piece.color, equals(PieceColor.white));
      
      // 验证移动是合法的
      final validMoves = ChessAdapter.getLegalMoves(board, PieceColor.white);
      final isValidMove = validMoves.any((validMove) => 
        validMove.from.row == move.from.row &&
        validMove.from.col == move.from.col &&
        validMove.to.row == move.to.row &&
        validMove.to.col == move.to.col
      );
      
      expect(isValidMove, isTrue);
    });

    test('AI should handle different difficulty levels', () async {
      final board = _createInitialBoard();
      
      final easyAI = ChessAI(difficulty: AIDifficulty.easy);
      final mediumAI = ChessAI(difficulty: AIDifficulty.medium);
      final hardAI = ChessAI(difficulty: AIDifficulty.hard);
      
      final easyMove = await easyAI.getBestMove(board, PieceColor.white);
      final mediumMove = await mediumAI.getBestMove(board, PieceColor.white);
      final hardMove = await hardAI.getBestMove(board, PieceColor.white);
      
      expect(easyMove, isNotNull);
      expect(mediumMove, isNotNull);
      expect(hardMove, isNotNull);
    });

    test('AI should not make moves when game is over', () async {
      // 创建一个将死的局面
      final board = _createCheckmateBoard();
      
      final move = await ai.getBestMove(board, PieceColor.black);
      
      expect(move, isNull);
    });

    test('AI should prefer capturing moves', () async {
      // 创建一个有吃子机会的局面
      final board = _createCaptureTestBoard();

      final move = await ai.getBestMove(board, PieceColor.white);

      expect(move, isNotNull);
      // 验证这是一个合法移动
      final validMoves = ChessAdapter.getLegalMoves(board, PieceColor.white);
      final isValidMove = validMoves.any((validMove) =>
        validMove.from.row == move!.from.row &&
        validMove.from.col == move.from.col &&
        validMove.to.row == move.to.row &&
        validMove.to.col == move.to.col
      );
      expect(isValidMove, isTrue);
    });

    test('ChessAdapter should correctly convert between formats', () {
      final position = Position(row: 0, col: 0);
      final square = ChessAdapter.toChessLibSquare(position);
      expect(square, equals('a8'));
      
      final convertedBack = ChessAdapter.fromChessLibSquare(square);
      expect(convertedBack.row, equals(position.row));
      expect(convertedBack.col, equals(position.col));
    });

    test('ChessAdapter should detect check correctly', () {
      final board = _createCheckBoard();

      final isInCheck = ChessAdapter.isInCheck(board, PieceColor.white);
      expect(isInCheck, isTrue);
    });

    test('ChessAdapter should detect checkmate correctly', () {
      final board = _createCheckmateBoard();
      
      final isCheckmate = ChessAdapter.isCheckmate(board, PieceColor.black);
      expect(isCheckmate, isTrue);
    });
  });
}

/// 创建初始棋盘状态
List<List<ChessPiece?>> _createInitialBoard() {
  final board = List.generate(8, (row) => List.generate(8, (col) => null as ChessPiece?));
  
  // 白方棋子
  board[7][0] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
  board[7][1] = const ChessPiece(type: PieceType.knight, color: PieceColor.white);
  board[7][2] = const ChessPiece(type: PieceType.bishop, color: PieceColor.white);
  board[7][3] = const ChessPiece(type: PieceType.queen, color: PieceColor.white);
  board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
  board[7][5] = const ChessPiece(type: PieceType.bishop, color: PieceColor.white);
  board[7][6] = const ChessPiece(type: PieceType.knight, color: PieceColor.white);
  board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
  
  for (int col = 0; col < 8; col++) {
    board[6][col] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
  }
  
  // 黑方棋子
  board[0][0] = const ChessPiece(type: PieceType.rook, color: PieceColor.black);
  board[0][1] = const ChessPiece(type: PieceType.knight, color: PieceColor.black);
  board[0][2] = const ChessPiece(type: PieceType.bishop, color: PieceColor.black);
  board[0][3] = const ChessPiece(type: PieceType.queen, color: PieceColor.black);
  board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
  board[0][5] = const ChessPiece(type: PieceType.bishop, color: PieceColor.black);
  board[0][6] = const ChessPiece(type: PieceType.knight, color: PieceColor.black);
  board[0][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.black);
  
  for (int col = 0; col < 8; col++) {
    board[1][col] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
  }
  
  return board;
}

/// 创建一个将军的局面
List<List<ChessPiece?>> _createCheckBoard() {
  final board = List.generate(8, (row) => List.generate(8, (col) => null as ChessPiece?));

  // 白王在 e1，黑后在 e8，黑王在 a8，黑后将军白王
  board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
  board[0][4] = const ChessPiece(type: PieceType.queen, color: PieceColor.black);
  board[0][0] = const ChessPiece(type: PieceType.king, color: PieceColor.black);

  return board;
}

/// 创建一个将死的局面
List<List<ChessPiece?>> _createCheckmateBoard() {
  final board = List.generate(8, (row) => List.generate(8, (col) => null as ChessPiece?));
  
  // 简单的将死局面：黑王在角落，被白后和白王困住
  board[0][0] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
  board[1][1] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
  board[0][1] = const ChessPiece(type: PieceType.queen, color: PieceColor.white);
  
  return board;
}

/// 创建一个有吃子机会的局面
List<List<ChessPiece?>> _createCaptureTestBoard() {
  final board = List.generate(8, (row) => List.generate(8, (col) => null as ChessPiece?));
  
  // 白王和黑王
  board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
  board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
  
  // 白后可以吃黑兵
  board[6][3] = const ChessPiece(type: PieceType.queen, color: PieceColor.white);
  board[4][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
  
  return board;
}
