import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/services/chess_ai.dart';
import 'package:testflutter/screens/game_screen.dart';

void main() {
  group('RED: AI 升变调试测试', () {
    late ChessBloc bloc;

    setUp(() {
      bloc = ChessBloc();
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('RED: 调试 AI 升变流程', (tester) async {
      // 创建一个简单的升变场景
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

      print('=== 初始化游戏 ===');
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

      print('=== 初始状态 ===');
      print('当前玩家: ${bloc.state.currentPlayer}');
      print('AI颜色: ${bloc.state.aiColor}');
      print('游戏模式: ${bloc.state.gameMode}');
      print('AI思考中: ${bloc.state.isAIThinking}');
      print('AI初始化中: ${bloc.state.isAIInitializing}');

      // 验证初始状态
      expect(bloc.state.currentPlayer, PieceColor.white);
      expect(bloc.state.aiColor, PieceColor.white);
      expect(bloc.state.gameMode, GameMode.offline);

      print('=== 手动触发AI移动 ===');
      // 手动触发AI移动（模拟升变）
      bloc.add(MovePiece(
        const Position(row: 1, col: 3), // 从第7行
        const Position(row: 0, col: 3), // 到第8行（升变）
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      print('=== 升变移动后状态 ===');
      print('当前玩家: ${bloc.state.currentPlayer}');
      print('最后移动: ${bloc.state.lastMove}');
      print('是否升变: ${bloc.state.lastMove?.isPromotion}');
      print('升变类型: ${bloc.state.lastMove?.promotionType}');

      final pieceAtDestination = bloc.state.board[0][3];
      print('目标位置棋子: $pieceAtDestination');

      // 验证AI已经自动完成升变
      expect(pieceAtDestination, isNotNull);
      expect(pieceAtDestination!.type, PieceType.queen,
          reason: 'AI 应该自动将兵升变为皇后');
      expect(pieceAtDestination.color, PieceColor.white);

      // 验证最后一步移动被标记为升变
      expect(bloc.state.lastMove, isNotNull);
      expect(bloc.state.lastMove!.isPromotion, isTrue);

      print('=== 等待AI自动升变 ===');
      // 等待AI自动升变
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // 等待所有微任务完成
      await tester.pump();
      await tester.pump();

      print('=== 升变完成后状态 ===');
      print('当前玩家: ${bloc.state.currentPlayer}');
      print('AI思考中: ${bloc.state.isAIThinking}');

      final promotedPiece = bloc.state.board[0][3];
      print('升变后棋子: $promotedPiece');
      print('移动历史长度: ${bloc.state.moveHistory.length}');
      if (bloc.state.moveHistory.isNotEmpty) {
        final lastHistoryMove = bloc.state.moveHistory.last;
        print('历史中最后移动: $lastHistoryMove');
        print('历史中升变类型: ${lastHistoryMove.promotionType}');
      }

      // 验证升变是否自动完成
      expect(promotedPiece, isNotNull);

      // AI 应该自动升变为皇后
      expect(promotedPiece!.type, PieceType.queen, reason: 'AI 应该自动将兵升变为皇后');
      expect(promotedPiece.color, PieceColor.white);

      // 验证游戏状态正常，轮到黑方移动
      expect(bloc.state.currentPlayer, PieceColor.black,
          reason: 'AI 升变完成后应该轮到黑方移动');

      // 验证AI不再处于思考状态
      expect(bloc.state.isAIThinking, isFalse, reason: 'AI 升变完成后不应该还在思考状态');
    });

    testWidgets('RED: 测试人类玩家升变后AI响应', (tester) async {
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

      print('=== 初始化游戏（AI为白方）===');
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

      print('=== 人类升变移动 ===');
      // 人类进行升变移动
      bloc.add(const SelectPiece(Position(row: 6, col: 3)));
      await tester.pump(const Duration(milliseconds: 50));

      bloc.add(const MovePiece(
        Position(row: 6, col: 3),
        Position(row: 7, col: 3),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      print('=== 人类选择升变类型 ===');
      // 人类选择升变类型
      bloc.add(const PromotePawn(
        Position(row: 7, col: 3),
        PieceType.queen,
      ));
      await tester.pump(const Duration(milliseconds: 100));

      print('=== 升变完成后状态 ===');
      print('当前玩家: ${bloc.state.currentPlayer}');
      print('AI思考中: ${bloc.state.isAIThinking}');
      print('AI初始化中: ${bloc.state.isAIInitializing}');

      // 验证升变完成
      final promotedPiece = bloc.state.board[7][3];
      expect(promotedPiece?.type, PieceType.queen);
      expect(promotedPiece?.color, PieceColor.black);

      // 验证轮到AI
      expect(bloc.state.currentPlayer, PieceColor.white,
          reason: '人类升变完成后应该轮到AI（白方）移动');

      print('=== 等待AI响应 ===');
      // 等待AI响应
      await tester.pump(const Duration(milliseconds: 2000));

      print('=== AI响应后状态 ===');
      print('当前玩家: ${bloc.state.currentPlayer}');
      print('AI思考中: ${bloc.state.isAIThinking}');
      print('移动历史长度: ${bloc.state.moveHistory.length}');

      // AI应该已经移动或正在思考
      expect(
          bloc.state.isAIThinking ||
              bloc.state.currentPlayer == PieceColor.black,
          isTrue,
          reason: 'AI应该已经移动或正在思考');
    });
  });
}
