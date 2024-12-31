import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chess_models.dart';
import '../models/game_history.dart';
import '../screens/game_screen.dart';

// Events
abstract class ReplayEvent {}

class InitializeReplay extends ReplayEvent {
  final GameHistory gameHistory;
  InitializeReplay(this.gameHistory);
}

class NextMove extends ReplayEvent {}

class PreviousMove extends ReplayEvent {}

// State
class ReplayState extends GameState {
  final int currentMoveIndex;
  final GameHistory gameHistory;

  const ReplayState({
    required super.board,
    required super.currentPlayer,
    required this.currentMoveIndex,
    required this.gameHistory,
    super.selectedPosition,
    super.validMoves = const [],
    required super.hasKingMoved,
    required super.hasRookMoved,
    required super.lastPawnDoubleMoved,
    required super.lastPawnDoubleMovedNumber,
    super.currentMoveNumber = 0,
    super.moveHistory = const [],
    super.specialMoveMessage,
    super.lastMove,
    super.isCheck = false,
    super.isCheckmate = false,
    super.isStalemate = false,
    super.undoStates = const [],
    super.redoStates = const [],
    super.hintMode = false,
    super.isInteractive = false,
    super.allowedPlayer,
    required super.gameMode,
  });

  ReplayState copyWith({
    List<List<ChessPiece?>>? board,
    PieceColor? currentPlayer,
    int? currentMoveIndex,
    GameHistory? gameHistory,
    Position? selectedPosition,
    List<Position>? validMoves,
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Map<PieceColor, Position?>? lastPawnDoubleMoved,
    Map<PieceColor, int>? lastPawnDoubleMovedNumber,
    int? currentMoveNumber,
    List<ChessMove>? moveHistory,
    String? specialMoveMessage,
    ChessMove? lastMove,
    bool? isCheck,
    bool? isCheckmate,
    bool? isStalemate,
    List<GameState>? undoStates,
    List<GameState>? redoStates,
    bool? hintMode,
    bool? isInteractive,
    PieceColor? allowedPlayer,
    GameMode? gameMode,
  }) {
    return ReplayState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      currentMoveIndex: currentMoveIndex ?? this.currentMoveIndex,
      gameHistory: gameHistory ?? this.gameHistory,
      selectedPosition: selectedPosition,
      validMoves: validMoves ?? this.validMoves,
      hasKingMoved: hasKingMoved ?? this.hasKingMoved,
      hasRookMoved: hasRookMoved ?? this.hasRookMoved,
      lastPawnDoubleMoved: lastPawnDoubleMoved ?? this.lastPawnDoubleMoved,
      lastPawnDoubleMovedNumber: lastPawnDoubleMovedNumber ?? this.lastPawnDoubleMovedNumber,
      currentMoveNumber: currentMoveNumber ?? this.currentMoveNumber,
      moveHistory: moveHistory ?? this.moveHistory,
      specialMoveMessage: specialMoveMessage ?? this.specialMoveMessage,
      lastMove: lastMove ?? this.lastMove,
      isCheck: isCheck ?? this.isCheck,
      isCheckmate: isCheckmate ?? this.isCheckmate,
      isStalemate: isStalemate ?? this.isStalemate,
      undoStates: undoStates ?? this.undoStates,
      redoStates: redoStates ?? this.redoStates,
      hintMode: hintMode ?? this.hintMode,
      isInteractive: isInteractive ?? this.isInteractive,
      allowedPlayer: allowedPlayer ?? this.allowedPlayer,
      gameMode: gameMode ?? this.gameMode,
    );
  }
}

class ReplayBloc extends Bloc<ReplayEvent, ReplayState> {
  ReplayBloc() : super(ReplayState(
    board: List.generate(8, (i) => List.generate(8, (j) => null)),
    currentPlayer: PieceColor.white,
    currentMoveIndex: -1,
    gameHistory: GameHistory(
      id: '',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      moves: [],
      gameMode: GameMode.offline,
      isCompleted: false,
    ),
    hasKingMoved: const {
      PieceColor.white: false,
      PieceColor.black: false,
    },
    hasRookMoved: const {
      PieceColor.white: {'kingside': false, 'queenside': false},
      PieceColor.black: {'kingside': false, 'queenside': false},
    },
    lastPawnDoubleMoved: const {
      PieceColor.white: null,
      PieceColor.black: null,
    },
    lastPawnDoubleMovedNumber: const {
      PieceColor.white: -1,
      PieceColor.black: -1,
    },
    gameMode: GameMode.offline,
  )) {
    on<InitializeReplay>(_onInitializeReplay);
    on<NextMove>(_onNextMove);
    on<PreviousMove>(_onPreviousMove);
  }

  void _onInitializeReplay(InitializeReplay event, Emitter<ReplayState> emit) {
    final initialBoard = List<List<ChessPiece?>>.generate(8, (row) {
      return List<ChessPiece?>.generate(8, (col) {
        if (row == 1) {
          return const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
        } else if (row == 6) {
          return const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        } else if (row == 0 || row == 7) {
          final color = row == 0 ? PieceColor.black : PieceColor.white;
          if (col == 0 || col == 7) {
            return ChessPiece(type: PieceType.rook, color: color);
          } else if (col == 1 || col == 6) {
            return ChessPiece(type: PieceType.knight, color: color);
          } else if (col == 2 || col == 5) {
            return ChessPiece(type: PieceType.bishop, color: color);
          } else if (col == 3) {
            return ChessPiece(type: PieceType.queen, color: color);
          } else if (col == 4) {
            return ChessPiece(type: PieceType.king, color: color);
          }
        }
        return null;
      });
    });

    emit(state.copyWith(
      board: initialBoard,
      currentPlayer: PieceColor.white,
      currentMoveIndex: -1,
      gameHistory: event.gameHistory,
      moveHistory: [],
      specialMoveMessage: null,
      lastMove: null,
      isCheck: false,
      isCheckmate: false,
      isStalemate: false,
      gameMode: event.gameHistory.gameMode,
    ));
  }

  void _onNextMove(NextMove event, Emitter<ReplayState> emit) {
    if (state.currentMoveIndex >= state.gameHistory.moves.length - 1) return;

    final nextMoveIndex = state.currentMoveIndex + 1;
    final move = state.gameHistory.moves[nextMoveIndex];
    final newBoard = List<List<ChessPiece?>>.from(
      state.board.map((row) => List<ChessPiece?>.from(row))
    );

    // 执行移动
    newBoard[move.to.row][move.to.col] = move.piece;
    newBoard[move.from.row][move.from.col] = null;

    // 如果是升变
    if (move.isPromotion && move.promotionType != null) {
      newBoard[move.to.row][move.to.col] = ChessPiece(
        type: move.promotionType!,
        color: move.piece.color,
      );
    }

    // 如果是吃过路兵
    if (move.isEnPassant) {
      final capturedPawnRow = move.from.row;
      newBoard[capturedPawnRow][move.to.col] = null;
    }

    // 如果是王车易位
    if (move.isCastling) {
      final isKingside = move.to.col > move.from.col;
      final rookFromCol = isKingside ? 7 : 0;
      final rookToCol = isKingside ? 5 : 3;
      newBoard[move.from.row][rookToCol] = newBoard[move.from.row][rookFromCol];
      newBoard[move.from.row][rookFromCol] = null;
    }

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white,
      currentMoveIndex: nextMoveIndex,
      moveHistory: state.gameHistory.moves.sublist(0, nextMoveIndex + 1),
      lastMove: move,
    ));
  }

  void _onPreviousMove(PreviousMove event, Emitter<ReplayState> emit) {
    if (state.currentMoveIndex < 0) return;

    final previousMoveIndex = state.currentMoveIndex - 1;
    final initialBoard = List<List<ChessPiece?>>.generate(8, (row) {
      return List<ChessPiece?>.generate(8, (col) {
        if (row == 1) {
          return const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
        } else if (row == 6) {
          return const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        } else if (row == 0 || row == 7) {
          final color = row == 0 ? PieceColor.black : PieceColor.white;
          if (col == 0 || col == 7) {
            return ChessPiece(type: PieceType.rook, color: color);
          } else if (col == 1 || col == 6) {
            return ChessPiece(type: PieceType.knight, color: color);
          } else if (col == 2 || col == 5) {
            return ChessPiece(type: PieceType.bishop, color: color);
          } else if (col == 3) {
            return ChessPiece(type: PieceType.queen, color: color);
          } else if (col == 4) {
            return ChessPiece(type: PieceType.king, color: color);
          }
        }
        return null;
      });
    });

    // 重新执行到前一步的所有移动
    var currentBoard = initialBoard;
    for (var i = 0; i <= previousMoveIndex; i++) {
      final move = state.gameHistory.moves[i];
      currentBoard = List<List<ChessPiece?>>.from(
        currentBoard.map((row) => List<ChessPiece?>.from(row))
      );

      currentBoard[move.to.row][move.to.col] = move.piece;
      currentBoard[move.from.row][move.from.col] = null;

      if (move.isPromotion && move.promotionType != null) {
        currentBoard[move.to.row][move.to.col] = ChessPiece(
          type: move.promotionType!,
          color: move.piece.color,
        );
      }

      if (move.isEnPassant) {
        final capturedPawnRow = move.from.row;
        currentBoard[capturedPawnRow][move.to.col] = null;
      }

      if (move.isCastling) {
        final isKingside = move.to.col > move.from.col;
        final rookFromCol = isKingside ? 7 : 0;
        final rookToCol = isKingside ? 5 : 3;
        currentBoard[move.from.row][rookToCol] = currentBoard[move.from.row][rookFromCol];
        currentBoard[move.from.row][rookFromCol] = null;
      }
    }

    emit(state.copyWith(
      board: currentBoard,
      currentPlayer: previousMoveIndex % 2 == 0 ? PieceColor.black : PieceColor.white,
      currentMoveIndex: previousMoveIndex,
      moveHistory: state.gameHistory.moves.sublist(0, previousMoveIndex + 1),
      lastMove: previousMoveIndex >= 0 ? state.gameHistory.moves[previousMoveIndex] : null,
    ));
  }
}