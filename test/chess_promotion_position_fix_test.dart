import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/utils/chess_formatters.dart';
import 'package:testflutter/screens/game_screen.dart'; // For GameMode
import 'package:testflutter/services/chess_ai.dart'; // For AIDifficulty

void main() {
  group('Chess Promotion Position Display Fix', () {
    late ChessBloc bloc;

    setUp(() {
      bloc = ChessBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('测试升变过程中位置显示不出现负索引错误', () async {
      // 设置一个接近升变的局面：白兵在第6行，即将升变到第0行
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // 放置一个白兵在第6行，准备升变
      board[6][4] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      // 放置白王和黑王
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // 创建初始状态，包含valid moves以通过验证
      final initialState = GameState(
        board: board,
        currentPlayer: PieceColor.white,
        gameMode: GameMode.faceToFace,
        moveHistory: [],
        undoStates: [],
        redoStates: [],
        lastMove: null,
        specialMoveMessage: null,
        selectedPosition: const Position(row: 6, col: 4),
        validMoves: [const Position(row: 0, col: 4)], // 添加有效移动
        hasKingMoved: {
          PieceColor.white: false,
          PieceColor.black: false,
        },
        hasRookMoved: {
          PieceColor.white: {'queenside': false, 'kingside': false},
          PieceColor.black: {'queenside': false, 'kingside': false},
        },
        lastPawnDoubleMoved: {
          PieceColor.white: null,
          PieceColor.black: null,
        },
        lastPawnDoubleMovedNumber: {
          PieceColor.white: -1,
          PieceColor.black: -1,
        },
        currentMoveNumber: 1,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false,
        hintMode: false,
        isInteractive: true,
        allowedPlayer: null,
        aiColor: null,
        aiDifficulty: AIDifficulty.medium,
        isAIThinking: false,
      );

      // 手动设置状态
      bloc.emit(initialState);

      // 执行升变移动：从第6行移动到第0行
      bloc.add(MovePiece(
          const Position(row: 6, col: 4), const Position(row: 0, col: 4)));

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));

      // 获取当前状态
      final afterMoveState = bloc.state;

      // 验证升变移动已经被记录
      expect(afterMoveState.moveHistory.isNotEmpty, true);
      final move = afterMoveState.moveHistory.last;
      expect(move.isPromotion, true);
      expect(move.from.row, 6);
      expect(move.from.col, 4);
      expect(move.to.row, 0);
      expect(move.to.col, 4);

      // 测试位置名称不会产生负索引错误
      final fromPositionName = ChessFormatters.getPositionName(move.from);
      final toPositionName = ChessFormatters.getPositionName(move.to);

      expect(fromPositionName, 'E2'); // 第6行第4列对应E2
      expect(toPositionName, 'E8'); // 第0行第4列对应E8

      // 执行升变选择：升变为后
      bloc.add(PromotePawn(const Position(row: 0, col: 4), PieceType.queen));

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));

      final finalState = bloc.state;

      // 验证升变完成
      expect(finalState.board[0][4]?.type, PieceType.queen);
      expect(finalState.board[0][4]?.color, PieceColor.white);

      // 验证移动历史正确记录了升变类型
      expect(finalState.moveHistory.last.promotionType, PieceType.queen);

      // 验证升变消息中的位置显示正确
      final promotionMove = finalState.moveHistory.last;
      final promotionFromName =
          ChessFormatters.getPositionName(promotionMove.from);
      final promotionToName = ChessFormatters.getPositionName(promotionMove.to);

      expect(promotionFromName, 'E2');
      expect(promotionToName, 'E8');

      // 验证特殊消息中包含正确的位置信息
      expect(finalState.specialMoveMessage, contains('E2'));
      expect(finalState.specialMoveMessage, contains('E8'));
      expect(finalState.specialMoveMessage, contains('后'));
    });

    test('测试黑方升变过程中位置显示不出现负索引错误', () async {
      // 设置一个黑兵升变的局面：黑兵在第1行，即将升变到第7行
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // 放置一个黑兵在第1行，准备升变
      board[1][3] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      // 放置白王和黑王
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // 创建初始状态，包含valid moves以通过验证
      final initialState = GameState(
        board: board,
        currentPlayer: PieceColor.black,
        gameMode: GameMode.faceToFace,
        moveHistory: [],
        undoStates: [],
        redoStates: [],
        lastMove: null,
        specialMoveMessage: null,
        selectedPosition: const Position(row: 1, col: 3),
        validMoves: [const Position(row: 7, col: 3)], // 添加有效移动
        hasKingMoved: {
          PieceColor.white: false,
          PieceColor.black: false,
        },
        hasRookMoved: {
          PieceColor.white: {'queenside': false, 'kingside': false},
          PieceColor.black: {'queenside': false, 'kingside': false},
        },
        lastPawnDoubleMoved: {
          PieceColor.white: null,
          PieceColor.black: null,
        },
        lastPawnDoubleMovedNumber: {
          PieceColor.white: -1,
          PieceColor.black: -1,
        },
        currentMoveNumber: 1,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false,
        hintMode: false,
        isInteractive: true,
        allowedPlayer: null,
        aiColor: null,
        aiDifficulty: AIDifficulty.medium,
        isAIThinking: false,
      );

      // 手动设置状态
      bloc.emit(initialState);

      // 执行升变移动：从第1行移动到第7行
      bloc.add(MovePiece(
          const Position(row: 1, col: 3), const Position(row: 7, col: 3)));

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));

      // 获取当前状态
      final afterMoveState = bloc.state;

      // 验证升变移动已经被记录
      expect(afterMoveState.moveHistory.isNotEmpty, true);
      final move = afterMoveState.moveHistory.last;
      expect(move.isPromotion, true);
      expect(move.from.row, 1);
      expect(move.from.col, 3);
      expect(move.to.row, 7);
      expect(move.to.col, 3);

      // 测试位置名称不会产生负索引错误
      final fromPositionName = ChessFormatters.getPositionName(move.from);
      final toPositionName = ChessFormatters.getPositionName(move.to);

      expect(fromPositionName, 'D7'); // 第1行第3列对应D7
      expect(toPositionName, 'D1'); // 第7行第3列对应D1

      // 执行升变选择：升变为马
      bloc.add(PromotePawn(const Position(row: 7, col: 3), PieceType.knight));

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));

      final finalState = bloc.state;

      // 验证升变完成
      expect(finalState.board[7][3]?.type, PieceType.knight);
      expect(finalState.board[7][3]?.color, PieceColor.black);

      // 验证移动历史正确记录了升变类型
      expect(finalState.moveHistory.last.promotionType, PieceType.knight);

      // 验证升变消息中的位置显示正确
      final promotionMove = finalState.moveHistory.last;
      final promotionFromName =
          ChessFormatters.getPositionName(promotionMove.from);
      final promotionToName = ChessFormatters.getPositionName(promotionMove.to);

      expect(promotionFromName, 'D7');
      expect(promotionToName, 'D1');

      // 验证特殊消息中包含正确的位置信息
      expect(finalState.specialMoveMessage, contains('D7'));
      expect(finalState.specialMoveMessage, contains('D1'));
      expect(finalState.specialMoveMessage, contains('马'));
    });

    test('测试极端边界情况：无历史记录时的升变', () async {
      // 创建一个没有历史记录的状态，但已经有兵在升变位置
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // 直接在升变位置放置一个兵（模拟某种异常状态）
      board[0][7] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      final initialState = GameState(
        board: board,
        currentPlayer: PieceColor.white,
        gameMode: GameMode.faceToFace,
        moveHistory: [], // 明确没有历史记录
        undoStates: [],
        redoStates: [],
        lastMove: null,
        specialMoveMessage: null,
        selectedPosition: null,
        validMoves: [],
        hasKingMoved: {
          PieceColor.white: false,
          PieceColor.black: false,
        },
        hasRookMoved: {
          PieceColor.white: {'queenside': false, 'kingside': false},
          PieceColor.black: {'queenside': false, 'kingside': false},
        },
        lastPawnDoubleMoved: {
          PieceColor.white: null,
          PieceColor.black: null,
        },
        lastPawnDoubleMovedNumber: {
          PieceColor.white: -1,
          PieceColor.black: -1,
        },
        currentMoveNumber: 1,
        isCheck: false,
        isCheckmate: false,
        isStalemate: false,
        hintMode: false,
        isInteractive: true,
        allowedPlayer: null,
        aiColor: null,
        aiDifficulty: AIDifficulty.medium,
        isAIThinking: false,
      );

      bloc.emit(initialState);

      // 直接执行升变选择（没有移动历史）
      bloc.add(PromotePawn(const Position(row: 0, col: 7), PieceType.rook));

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));

      final finalState = bloc.state;

      // 验证升变完成
      expect(finalState.board[0][7]?.type, PieceType.rook);
      expect(finalState.board[0][7]?.color, PieceColor.white);

      // 验证创建了合理的移动历史
      expect(finalState.moveHistory.isNotEmpty, true);
      final move = finalState.moveHistory.last;
      expect(move.isPromotion, true);
      expect(move.promotionType, PieceType.rook);

      // 关键测试：验证生成的起始位置坐标是合理的（不为负）
      expect(move.from.row >= 0, true);
      expect(move.from.row < 8, true);
      expect(move.from.col >= 0, true);
      expect(move.from.col < 8, true);

      // 验证位置名称不包含负索引错误的迹象
      final fromPositionName = ChessFormatters.getPositionName(move.from);
      final toPositionName = ChessFormatters.getPositionName(move.to);

      expect(fromPositionName.startsWith('无效位置'), false);
      expect(toPositionName.startsWith('无效位置'), false);

      // 对于白兵升变，起始位置应该是第6行
      expect(move.from.row, 6);
      expect(move.from.col, 7);
      expect(fromPositionName, 'H2'); // 第6行第7列对应H2
      expect(toPositionName, 'H8'); // 第0行第7列对应H8
    });
  });
}
