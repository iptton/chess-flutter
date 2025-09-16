import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/services/chess_ai.dart';
import 'package:testflutter/screens/game_screen.dart';

void main() {
  group('GREEN: AI 兵升变修复验证', () {
    late ChessBloc bloc;

    setUp(() {
      bloc = ChessBloc();
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('GREEN: AI 兵升变应该自动完成并切换玩家', (tester) async {
      // 创建一个即将升变的棋盘状态
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // 设置基本棋子
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // 白方兵在第7行，即将升变到第8行
      board[1][3] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

      // 初始化游戏，设置AI为白方
      bloc.add(InitializeGame(
        false,
        gameMode: GameMode.offline,
        aiDifficulty: AIDifficulty.easy,
        aiColor: PieceColor.white,
        initialBoard: board,
        initialPlayer: PieceColor.white, // 白方（AI）先手
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证初始状态
      expect(bloc.state.currentPlayer, PieceColor.white);
      expect(bloc.state.aiColor, PieceColor.white);
      expect(bloc.state.gameMode, GameMode.offline);

      // 模拟AI进行升变移动
      bloc.add(const MovePiece(
        Position(row: 1, col: 3), // 从第7行
        Position(row: 0, col: 3), // 到第8行（升变）
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // 验证升变自动完成
      final promotedPiece = bloc.state.board[0][3];
      expect(promotedPiece, isNotNull);
      expect(promotedPiece!.type, PieceType.queen, reason: 'AI 应该自动将兵升变为皇后');
      expect(promotedPiece.color, PieceColor.white);

      // 验证游戏状态正常，轮到黑方移动
      expect(bloc.state.currentPlayer, PieceColor.black,
          reason: 'AI 升变完成后应该轮到黑方移动');

      // 验证AI不再处于思考状态
      expect(bloc.state.isAIThinking, isFalse, reason: 'AI 升变完成后不应该还在思考状态');

      // 验证移动历史正确
      expect(bloc.state.moveHistory.isNotEmpty, isTrue);
      final lastMove = bloc.state.moveHistory.last;
      expect(lastMove.isPromotion, isTrue);
      expect(lastMove.promotionType, PieceType.queen);
    });

    testWidgets('GREEN: AI 应该使用 Stockfish 建议的升变类型', (tester) async {
      // 创建一个即将升变的棋盘状态
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // 设置基本棋子
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // 白方兵在第7行，即将升变到第8行
      board[1][3] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

      // 初始化游戏，设置AI为白方
      bloc.add(InitializeGame(
        false,
        gameMode: GameMode.offline,
        aiDifficulty: AIDifficulty.easy,
        aiColor: PieceColor.white,
        initialBoard: board,
        initialPlayer: PieceColor.white, // 白方（AI）先手
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 模拟AI选择升变为马（欠升变）
      bloc.add(const MovePieceWithPromotion(
        Position(row: 1, col: 3), // 从第7行
        Position(row: 0, col: 3), // 到第8行（升变）
        PieceType.knight, // Stockfish 建议升变为马
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // 验证升变为马
      final promotedPiece = bloc.state.board[0][3];
      expect(promotedPiece, isNotNull);
      expect(promotedPiece!.type, PieceType.knight,
          reason: 'AI 应该使用 Stockfish 建议的升变类型（马）');
      expect(promotedPiece.color, PieceColor.white);

      // 验证游戏状态正常，轮到黑方移动
      expect(bloc.state.currentPlayer, PieceColor.black,
          reason: 'AI 升变完成后应该轮到黑方移动');

      // 验证移动历史正确
      expect(bloc.state.moveHistory.isNotEmpty, isTrue);
      final lastMove = bloc.state.moveHistory.last;
      expect(lastMove.isPromotion, isTrue);
      expect(lastMove.promotionType, PieceType.knight);
    });

    testWidgets('GREEN: 人类升变后AI应该能正常响应', (tester) async {
      // 创建一个场景：人类升变后，AI应该响应
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // 设置基本棋子
      board[7][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] =
          const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // 黑方兵在第2行，即将升变
      board[6][3] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 初始化游戏，设置AI为白方，人类为黑方
      bloc.add(InitializeGame(
        false,
        gameMode: GameMode.offline,
        aiDifficulty: AIDifficulty.easy,
        aiColor: PieceColor.white,
        initialBoard: board,
        initialPlayer: PieceColor.black, // 黑方（人类）先手
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 人类进行升变移动
      bloc.add(const SelectPiece(Position(row: 6, col: 3)));
      await tester.pump(const Duration(milliseconds: 50));

      bloc.add(const MovePiece(
        Position(row: 6, col: 3),
        Position(row: 7, col: 3),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // 人类选择升变类型
      bloc.add(const PromotePawn(
        Position(row: 7, col: 3),
        PieceType.queen,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      // 验证升变完成
      final promotedPiece = bloc.state.board[7][3];
      expect(promotedPiece?.type, PieceType.queen);
      expect(promotedPiece?.color, PieceColor.black);

      // 验证轮到AI
      expect(bloc.state.currentPlayer, PieceColor.white,
          reason: '人类升变完成后应该轮到AI（白方）移动');

      // 验证AI能正常响应（不会卡住）
      expect(bloc.state.isAIThinking, isFalse, reason: 'AI应该能正常响应，不会卡在升变状态');
    });
  });
}
