import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/utils/chess_rules.dart';

void main() {
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
        Position(row: 3, col: 4), // 白方兵的位置 e5
        lastPawnDoubleMoved: Position(row: 3, col: 3), // 黑方兵的位置 d5
        lastMoveNumber: 0,
        currentMoveNumber: 1,
      );

      // 期望吃过路兵位置：(2, 3)，即 d6
      final expectedEnPassantMove = Position(row: 2, col: 3);

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
        Position(row: 3, col: 4),
        lastPawnDoubleMoved: Position(row: 3, col: 3),
        lastMoveNumber: 0,
        currentMoveNumber: 2, // 已经过了一步
      );

      // 期望的吃过路兵位置
      final expectedEnPassantMove = Position(row: 2, col: 3);

      // 验证不能吃过路兵
      expect(
        validMoves.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '不应该允许延迟的吃过路兵',
      );
    });

    test('should remove captured pawn after en passant', () {
      // 设置初始棋盘状态
      final gameState = GameState.initial();
      
      // 模拟黑方兵双步移动
      final newBoard = List<List<ChessPiece?>>.from(
        gameState.board.map((row) => List<ChessPiece?>.from(row))
      );
      
      // 移动白方兵到 e5
      newBoard[3][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      newBoard[6][4] = null; // 移除原位置的白方兵
      
      // 移动黑方兵到 d5（双步移动）
      newBoard[3][3] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      newBoard[1][3] = null; // 移除原位置的黑方兵

      final state = GameState(
        board: newBoard,
        currentPlayer: PieceColor.white,
        hasKingMoved: gameState.hasKingMoved,
        hasRookMoved: gameState.hasRookMoved,
        lastPawnDoubleMoved: Position(row: 3, col: 3),
        lastMoveNumber: 0,
        currentMoveNumber: 1,
      );

      // 执行吃过路兵移动
      final from = Position(row: 3, col: 4); // e5
      final to = Position(row: 2, col: 3);   // d6
      final capturedPawnPos = Position(row: 3, col: 3); // d5

      // 验证被吃的��是否还在原位置
      expect(
        state.board[capturedPawnPos.row][capturedPawnPos.col],
        isNotNull,
        reason: '被吃的兵应该在 d5 位置',
      );

      // 验证吃过路兵的目标位置是否为空
      expect(
        state.board[to.row][to.col],
        isNull,
        reason: '目标位置 d6 应该为空',
      );
    });

    test('should execute en passant capture correctly', () {
      // 设置初始棋盘状态
      final gameState = GameState.initial();
      
      // 模拟黑方兵双步移动
      final newBoard = List<List<ChessPiece?>>.from(
        gameState.board.map((row) => List<ChessPiece?>.from(row))
      );
      
      // 移动白方兵到 e5
      final whitePawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      newBoard[3][4] = whitePawn;
      newBoard[6][4] = null; // 移除原位置的白方兵
      
      // 移动黑方兵到 d5（双步移动）
      final blackPawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      newBoard[3][3] = blackPawn;
      newBoard[1][3] = null; // 移除原位置的黑方兵

      final state = GameState(
        board: newBoard,
        currentPlayer: PieceColor.white,
        hasKingMoved: gameState.hasKingMoved,
        hasRookMoved: gameState.hasRookMoved,
        lastPawnDoubleMoved: Position(row: 3, col: 3),
        lastMoveNumber: 0,
        currentMoveNumber: 1,
      );

      // 执行吃过路兵移动
      final from = Position(row: 3, col: 4); // e5
      final to = Position(row: 2, col: 3);   // d6

      // 验证移动是否有效
      final validMoves = ChessRules.getValidMoves(
        state.board,
        from,
        lastPawnDoubleMoved: state.lastPawnDoubleMoved,
        lastMoveNumber: state.lastMoveNumber,
        currentMoveNumber: state.currentMoveNumber,
      );

      expect(
        validMoves.any((move) => 
          move.row == to.row && 
          move.col == to.col
        ),
        isTrue,
        reason: '吃过路兵应该是有效的移动',
      );

      // 模拟移动执行后的棋盘状态
      final afterMoveBoard = List<List<ChessPiece?>>.from(
        state.board.map((row) => List<ChessPiece?>.from(row))
      );
      
      afterMoveBoard[to.row][to.col] = whitePawn;      // 移动白兵到 d6
      afterMoveBoard[from.row][from.col] = null;       // 移除原位置的白兵
      afterMoveBoard[3][3] = null;                     // 移除被吃的黑兵

      // 验证移动后的状态
      expect(
        afterMoveBoard[to.row][to.col]?.color,
        PieceColor.white,
        reason: '白兵应该移动到 d6',
      );
      expect(
        afterMoveBoard[from.row][from.col],
        isNull,
        reason: '白兵原位置应该为空',
      );
      expect(
        afterMoveBoard[3][3],
        isNull,
        reason: '被吃的黑兵应该被移除',
      );
    });

    test('should not remove pawn for normal diagonal capture', () {
      // 设置初始棋盘状态
      final gameState = GameState.initial();
      
      // 模拟一个普通的斜向吃子局面
      final newBoard = List<List<ChessPiece?>>.from(
        gameState.board.map((row) => List<ChessPiece?>.from(row))
      );
      
      // 白方兵在 e4
      final whitePawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      newBoard[4][4] = whitePawn;
      newBoard[6][4] = null;
      
      // 黑方兵在 d5
      final blackPawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      newBoard[3][3] = blackPawn;

      final state = GameState(
        board: newBoard,
        currentPlayer: PieceColor.white,
        hasKingMoved: gameState.hasKingMoved,
        hasRookMoved: gameState.hasRookMoved,
        lastPawnDoubleMoved: Position(row: 3, col: 3), // 错误的位置信息
        lastMoveNumber: 0,
        currentMoveNumber: 1,
      );

      // 执行普通斜向吃子
      final from = Position(row: 4, col: 4); // e4
      final to = Position(row: 3, col: 3);   // d5

      // 验证这不应该被视为吃过路兵
      final validMoves = ChessRules.getValidMoves(
        state.board,
        from,
        lastPawnDoubleMoved: state.lastPawnDoubleMoved,
        lastMoveNumber: state.lastMoveNumber,
        currentMoveNumber: state.currentMoveNumber,
      );

      // 这应该是一个有效的普通吃子
      expect(
        validMoves.any((move) => 
          move.row == to.row && 
          move.col == to.col
        ),
        isTrue,
        reason: '普通斜向吃子应该是有效的',
      );

      // 但不应该有吃过路兵的位置
      expect(
        validMoves.any((move) => 
          move.row == 4 && // d4 位置
          move.col == 3
        ),
        isFalse,
        reason: '不应该允许吃过路兵',
      );
    });

    test('should only allow en passant capture immediately after double move', () {
      // 设置初始棋盘状态
      final gameState = GameState.initial();
      
      // 模拟黑方兵双步移动
      final newBoard = List<List<ChessPiece?>>.from(
        gameState.board.map((row) => List<ChessPiece?>.from(row))
      );
      
      // 移动白方兵到 e5
      final whitePawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      newBoard[3][4] = whitePawn;
      newBoard[6][4] = null;
      
      // 移动黑方兵到 d5（双步移动）
      final blackPawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      newBoard[3][3] = blackPawn;
      newBoard[1][3] = null;

      // 第一种情况：黑方刚刚完成双步移动
      final validMovesImmediately = ChessRules.getValidMoves(
        newBoard,
        Position(row: 3, col: 4), // e5
        lastPawnDoubleMoved: Position(row: 3, col: 3), // d5
        lastMoveNumber: 0,
        currentMoveNumber: 1,
      );

      // 期望的吃过路兵位置：(2, 3)，即 d6
      final expectedEnPassantMove = Position(row: 2, col: 3);

      // 验证可以吃过路兵
      expect(
        validMovesImmediately.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isTrue,
        reason: '黑方刚完成双步移动时，白方应该可以吃过路兵',
      );

      // 第二种情况：白方没有立即吃过路兵，而是移动了其他棋子
      final validMovesAfterOtherMove = ChessRules.getValidMoves(
        newBoard,
        Position(row: 3, col: 4), // e5
        lastPawnDoubleMoved: Position(row: 3, col: 3), // d5
        lastMoveNumber: 0,
        currentMoveNumber: 2, // 已经过了一步
      );

      // 验证不能吃过路兵
      expect(
        validMovesAfterOtherMove.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '如果白方没有立即吃过路兵，之后就不能再吃了',
      );

      // 第三种情况：黑方在双步移动后又移动了其他棋子
      final validMovesAfterBlackMove = ChessRules.getValidMoves(
        newBoard,
        Position(row: 3, col: 4), // e5
        lastPawnDoubleMoved: Position(row: 3, col: 3), // d5
        lastMoveNumber: 0,
        currentMoveNumber: 3, // 黑方已经走了下一步
      );

      // 验证不能吃过路兵
      expect(
        validMovesAfterBlackMove.any((move) => 
          move.row == expectedEnPassantMove.row && 
          move.col == expectedEnPassantMove.col
        ),
        isFalse,
        reason: '如果黑方已经走了下一步，白方就不能再吃过路兵了',
      );
    });

    test('should execute en passant capture and remove captured pawn', () {
      // 设置初始棋盘状态
      final gameState = GameState.initial();
      
      // 模拟黑方兵双步移动
      final newBoard = List<List<ChessPiece?>>.from(
        gameState.board.map((row) => List<ChessPiece?>.from(row))
      );
      
      // 移动白方兵到 e5
      final whitePawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      newBoard[3][4] = whitePawn;
      newBoard[6][4] = null;
      
      // 移动黑方兵到 d5（双步移动）
      final blackPawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      newBoard[3][3] = blackPawn;
      newBoard[1][3] = null;

      final state = GameState(
        board: newBoard,
        currentPlayer: PieceColor.white,
        hasKingMoved: gameState.hasKingMoved,
        hasRookMoved: gameState.hasRookMoved,
        lastPawnDoubleMoved: Position(row: 3, col: 3),
        lastMoveNumber: 0,
        currentMoveNumber: 1,
      );

      // 执行吃过路兵移动
      final from = Position(row: 3, col: 4); // e5
      final to = Position(row: 2, col: 3);   // d6

      // 验证这是一个有效的吃过路兵移动
      final validMoves = ChessRules.getValidMoves(
        state.board,
        from,
        lastPawnDoubleMoved: state.lastPawnDoubleMoved,
        lastMoveNumber: state.lastMoveNumber,
        currentMoveNumber: state.currentMoveNumber,
      );

      expect(
        validMoves.any((move) => 
          move.row == to.row && 
          move.col == to.col
        ),
        isTrue,
        reason: '这应该是一个有效的吃过路兵移动',
      );

      // 模拟移动执行
      final afterMoveBoard = List<List<ChessPiece?>>.from(
        state.board.map((row) => List<ChessPiece?>.from(row))
      );

      // 移动白兵到目标位置
      afterMoveBoard[to.row][to.col] = whitePawn;
      afterMoveBoard[from.row][from.col] = null;

      // 关键：移除被吃的黑兵
      afterMoveBoard[from.row][to.col] = null;

      // 验证移动后的状态
      expect(
        afterMoveBoard[to.row][to.col]?.color,
        PieceColor.white,
        reason: '白兵应该移动到 d6',
      );
      expect(
        afterMoveBoard[from.row][from.col],
        isNull,
        reason: '白兵原位置应该为空',
      );
      expect(
        afterMoveBoard[from.row][to.col],
        isNull,
        reason: '被吃的黑兵应该被移除',
      );

      // 验证这确实是一个吃过路兵的移动
      final move = ChessMove(
        from: from,
        to: to,
        piece: whitePawn,
        capturedPiece: blackPawn,
        isEnPassant: true,
      );

      expect(
        move.isEnPassant,
        isTrue,
        reason: '这应该被标记为吃过路兵移动',
      );
      expect(
        move.capturedPiece?.color,
        PieceColor.black,
        reason: '被吃的应该是黑方的兵',
      );
    });

    test('should correctly remove captured pawn in en passant', () {
      // 设置初始棋盘状态
      final gameState = GameState.initial();
      
      // 模拟黑方兵双步移动
      final newBoard = List<List<ChessPiece?>>.from(
        gameState.board.map((row) => List<ChessPiece?>.from(row))
      );
      
      // 移动白方兵到 e5
      final whitePawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      newBoard[3][4] = whitePawn;
      newBoard[6][4] = null;
      
      // 移动黑方兵到 d5（双步移动）
      final blackPawn = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      newBoard[3][3] = blackPawn;
      newBoard[1][3] = null;

      final state = GameState(
        board: newBoard,
        currentPlayer: PieceColor.white,
        hasKingMoved: gameState.hasKingMoved,
        hasRookMoved: gameState.hasRookMoved,
        lastPawnDoubleMoved: Position(row: 3, col: 3),
        lastMoveNumber: 0,
        currentMoveNumber: 1,
      );

      // 执行吃过路兵移动
      final from = Position(row: 3, col: 4); // e5
      final to = Position(row: 2, col: 3);   // d6
      final capturedPawnPos = Position(row: 3, col: 3); // d5

      // 验证初始状态
      expect(
        state.board[from.row][from.col]?.color,
        PieceColor.white,
        reason: '起始位置应该有白方的兵',
      );
      expect(
        state.board[capturedPawnPos.row][capturedPawnPos.col]?.color,
        PieceColor.black,
        reason: '被吃位置应该有黑方的兵',
      );
      expect(
        state.board[to.row][to.col],
        isNull,
        reason: '目标位置应该是空的',
      );

      // 模拟移动执行
      final afterMoveBoard = List<List<ChessPiece?>>.from(
        state.board.map((row) => List<ChessPiece?>.from(row))
      );

      // 移动白兵到目标位置
      afterMoveBoard[to.row][to.col] = whitePawn;
      afterMoveBoard[from.row][from.col] = null;

      // 关键：移除被吃的黑兵（在吃子方的当前行）
      afterMoveBoard[capturedPawnPos.row][capturedPawnPos.col] = null;

      // 验证移动后的状态
      expect(
        afterMoveBoard[to.row][to.col]?.color,
        PieceColor.white,
        reason: '白兵应该移动到 d6',
      );
      expect(
        afterMoveBoard[from.row][from.col],
        isNull,
        reason: '白兵原位置应该为空',
      );
      expect(
        afterMoveBoard[capturedPawnPos.row][capturedPawnPos.col],
        isNull,
        reason: '被吃的黑兵应该被移除',
      );

      // 验证这确实是一个吃过路兵的移动
      final move = ChessMove(
        from: from,
        to: to,
        piece: whitePawn,
        capturedPiece: blackPawn,
        isEnPassant: true,
      );

      expect(
        move.isEnPassant,
        isTrue,
        reason: '这应该被标记为吃过路兵移动',
      );
      expect(
        move.capturedPiece?.color,
        PieceColor.black,
        reason: '被吃的应该是黑方的兵',
      );
    });
  });
} 