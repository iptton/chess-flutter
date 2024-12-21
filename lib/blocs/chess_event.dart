import 'package:equatable/equatable.dart';
import '../models/chess_models.dart';

abstract class ChessEvent extends Equatable {
  const ChessEvent();

  @override
  List<Object?> get props => [];
}

class InitializeGame extends ChessEvent {
  const InitializeGame();
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