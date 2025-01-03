import 'package:equatable/equatable.dart';
import '../models/chess_models.dart';
import '../models/game_history.dart';
import '../screens/game_screen.dart';

abstract class ChessEvent extends Equatable {
  const ChessEvent();

  @override
  List<Object?> get props => [];
}

class InitializeGame extends ChessEvent {
  final bool hintMode;
  final bool isInteractive;
  final PieceColor? allowedPlayer;
  final GameMode gameMode;
  final GameHistory? replayGame;
  final List<List<ChessPiece?>>? initialBoard;
  final PieceColor? initialPlayer;
  final List<ChessMove>? initialMoves;

  const InitializeGame(
    this.hintMode, {
    this.isInteractive = true,
    this.allowedPlayer,
    this.gameMode = GameMode.offline,
    this.replayGame,
    this.initialBoard,
    this.initialPlayer,
    this.initialMoves,
  });

  @override
  List<Object?> get props => [hintMode, isInteractive, allowedPlayer, gameMode, replayGame, initialBoard, initialPlayer, initialMoves];
}

class SelectPiece extends ChessEvent {
  final Position position;

  const SelectPiece(this.position);

  @override
  List<Object?> get props => [position];
}

class MovePiece extends ChessEvent {
  final Position from;
  final Position to;

  const MovePiece(this.from, this.to);

  @override
  List<Object?> get props => [from, to];
}

class PromotePawn extends ChessEvent {
  final Position position;
  final PieceType promotionType;

  const PromotePawn(this.position, this.promotionType);

  @override
  List<Object?> get props => [position, promotionType];
}

class UndoMove extends ChessEvent {
  const UndoMove();
}

class RedoMove extends ChessEvent {
  const RedoMove();
}

class SaveGame extends ChessEvent {
  const SaveGame();
}

class LoadGame extends ChessEvent {
  final String gameId;

  const LoadGame(this.gameId);

  @override
  List<Object?> get props => [gameId];
}

class ToggleHintMode extends ChessEvent {
  const ToggleHintMode();
}

// 新增：从当前棋局开始新的对局
class StartNewGameFromCurrentPosition extends ChessEvent {
  final GameMode gameMode;
  final bool isInteractive;
  final PieceColor? allowedPlayer;

  const StartNewGameFromCurrentPosition({
    required this.gameMode,
    this.isInteractive = true,
    this.allowedPlayer,
  });
}

// 新增：设置棋盘交互状态
class SetBoardInteractivity extends ChessEvent {
  final bool isInteractive;
  final PieceColor? allowedPlayer;

  const SetBoardInteractivity({
    required this.isInteractive,
    this.allowedPlayer,
  });
}

// 新增：设置游戏模式
class SetGameMode extends ChessEvent {
  final GameMode gameMode;

  const SetGameMode(this.gameMode);
}