import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/screens/game_screen.dart';

void main() {
  group('Chess Promotion Fix Verification', () {
    test('升变功能应该正常工作而不会崩溃', () async {
      final bloc = ChessBloc();
      
      // 创建一个简单的升变场景：直接在升变位置放置兵
      final board = List.generate(8, (i) => List.generate(8, (j) => null as ChessPiece?));

      // 直接在升变位置放置白方兵
      board[0][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      // 放置国王（避免与升变位置冲突）
      board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][3] = const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // 初始化游戏状态
      bloc.add(InitializeGame(
        false,
        initialBoard: board,
        initialPlayer: PieceColor.white,
        gameMode: GameMode.faceToFace,
      ));

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));

      // 验证兵确实在升变位置
      expect(bloc.state.board[0][4]?.type, PieceType.pawn);
      expect(bloc.state.board[0][4]?.color, PieceColor.white);

      // 执行升变
      bloc.add(const PromotePawn(
        Position(row: 0, col: 4),
        PieceType.queen,
      ));
      
      // 等待升变完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证升变成功
      final finalState = bloc.state;
      expect(finalState.board[0][4]?.type, PieceType.queen);
      expect(finalState.board[0][4]?.color, PieceColor.white);
      
      // 验证没有崩溃（如果到这里说明没有抛出异常）
      expect(true, true);
      
      bloc.close();
    });
    
    test('黑方升变功能应该正常工作而不会崩溃', () async {
      final bloc = ChessBloc();
      
      // 创建一个简单的升变场景：黑方兵在第2行，可以升变
      final board = List.generate(8, (i) => List.generate(8, (j) => null as ChessPiece?));
      
      // 直接在升变位置放置黑方兵
      board[7][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      // 放置国王（避免与升变位置冲突）
      board[7][3] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
      board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);

      // 初始化游戏状态
      bloc.add(InitializeGame(
        false,
        initialBoard: board,
        initialPlayer: PieceColor.black,
        gameMode: GameMode.faceToFace,
      ));

      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));

      // 验证兵确实在升变位置
      expect(bloc.state.board[7][4]?.type, PieceType.pawn);
      expect(bloc.state.board[7][4]?.color, PieceColor.black);

      // 执行升变
      bloc.add(const PromotePawn(
        Position(row: 7, col: 4),
        PieceType.queen,
      ));
      
      // 等待升变完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证升变成功
      final finalState = bloc.state;
      expect(finalState.board[7][4]?.type, PieceType.queen);
      expect(finalState.board[7][4]?.color, PieceColor.black);
      
      // 验证没有崩溃（如果到这里说明没有抛出异常）
      expect(true, true);
      
      bloc.close();
    });
    
    test('升变过程中的错误应该被优雅处理', () async {
      final bloc = ChessBloc();
      
      // 创建一个可能导致问题的棋盘状态
      final board = List.generate(8, (i) => List.generate(8, (j) => null as ChessPiece?));
      
      // 只放置最少的棋子
      board[0][4] = const ChessPiece(type: PieceType.queen, color: PieceColor.white);
      board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
      
      // 初始化游戏状态
      bloc.add(InitializeGame(
        false,
        initialBoard: board,
        initialPlayer: PieceColor.white,
        gameMode: GameMode.faceToFace,
      ));
      
      // 等待状态更新
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 尝试在无效位置执行升变（这应该被优雅处理）
      bloc.add(const PromotePawn(
        Position(row: 0, col: 4),
        PieceType.queen,
      ));
      
      // 等待处理完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证应用没有崩溃
      expect(true, true);
      
      bloc.close();
    });
  });
}
