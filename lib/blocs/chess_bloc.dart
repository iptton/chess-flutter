import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chess_models.dart';
import '../screens/game_screen.dart';
// import '../utils/chess_rules.dart'; // ChessRules will be used via GameLogicService
import '../services/game_logic_service.dart';
import 'chess_event.dart';

class ChessBloc extends Bloc<ChessEvent, GameState> {
  final GameLogicService _gameLogicService;

  ChessBloc() 
      : _gameLogicService = GameLogicService(),
        super(GameState.initial()) {
    on<InitializeGame>(_onInitializeGame);
    on<SelectPiece>(_onSelectPiece);
    on<MovePiece>(_onMovePiece);
    on<PromotePawn>(_onPromotePawn);
    on<UndoMove>(_onUndoMove);
    on<RedoMove>(_onRedoMove);
    on<SaveGame>(_onSaveGame);
    on<LoadGame>(_onLoadGame);
    on<ToggleHintMode>(_onToggleHintMode);
    on<StartNewGameFromCurrentPosition>(_onStartNewGameFromCurrentPosition);
    on<SetBoardInteractivity>(_onSetBoardInteractivity);
    on<SetGameMode>(_onSetGameMode);
  }

  void _onInitializeGame(InitializeGame event, Emitter<GameState> emit) async {
    if (event.replayGame != null) {
      // Initialize replay state
      final initialState = await GameState.initialFromPrefs(
        hintMode: event.hintMode,
        isInteractive: event.isInteractive,
        allowedPlayer: event.allowedPlayer,
        gameMode: event.gameMode,
      );

      // Generate all intermediate states
      final states = <GameState>[initialState];
      var currentState = initialState;

      // Apply all moves to generate intermediate states using GameLogicService
      for (final move in event.replayGame!.moves) {
        // Assuming applyMove in GameLogicService updates necessary state like history for replay.
        // If applyMove is purely for board changes, this might need adjustment
        // or a dedicated replay-move-application method in GameLogicService.
        // For now, direct usage of applyMove as per current GameLogicService structure.
        currentState = _gameLogicService.applyMove(currentState, move);
        states.add(currentState);
      }

      // Normal replay mode
      emit(states[0].copyWith(
        moveHistory: event.replayGame!.moves,
        redoStates: states.sublist(1),
        undoStates: [],
        selectedPosition: null,
        validMoves: const [],
      ));
      return;
    }

    if (event.initialBoard != null) {
      // 从指定的棋盘状态开始
      var state = GameState(
        board: event.initialBoard!,
        currentPlayer: event.initialPlayer ?? PieceColor.white,
        hasKingMoved: const {
          PieceColor.white: false,
          PieceColor.black: false,
        },
        hasRookMoved: const {
          PieceColor.white: const {'kingside': false, 'queenside': false},
          PieceColor.black: const {'kingside': false, 'queenside': false},
        },
        lastPawnDoubleMoved: const {
          PieceColor.white: null,
          PieceColor.black: null,
        },
        lastPawnDoubleMovedNumber: const {
          PieceColor.white: -1,
          PieceColor.black: -1,
        },
        hintMode: event.hintMode,
        isInteractive: event.isInteractive,
        allowedPlayer: event.allowedPlayer,
        gameMode: event.gameMode,
      );

      // 如果有初始移动历史，应用这些移动
      if (event.initialMoves != null) {
        state = state.copyWith(
          moveHistory: event.initialMoves!,
          currentMoveNumber: event.initialMoves!.length,
        );
      }

      emit(state);
      return;
    }

    // 从初始状态开始
    final initialState = await GameState.initialFromPrefs(
      hintMode: event.hintMode,
      isInteractive: event.isInteractive,
      allowedPlayer: event.allowedPlayer,
      gameMode: event.gameMode,
    );
    emit(initialState);
  }

  void _onSelectPiece(SelectPiece event, Emitter<GameState> emit) {
    // 如果棋盘不可交互或游戏已结束，不允许选择棋子
    if (!state.isInteractive || state.isCheckmate || state.isStalemate) {
      emit(state.copyWith(
        selectedPosition: null,
        validMoves: [],
      ));
      return;
    }

    // 如果设置了允许操作的玩家方，检查当前是否允许操作
    if (state.allowedPlayer != null && state.currentPlayer != state.allowedPlayer) {
      emit(state.copyWith(
        selectedPosition: null,
        validMoves: [],
      ));
      return;
    }

    // The existing logic for checking interactivity, game over state, and player turn
    // is now part of _gameLogicService.getValidMovesForPiece.
    // We directly call the service method.
    final validMoves = _gameLogicService.getValidMovesForPiece(state, event.position);

    // Check if the piece at event.position belongs to the current player.
    // This check is also inside getValidMovesForPiece, which returns empty if not.
    // If validMoves is empty, it implies either no valid moves or selection was invalid.
    // The GameState's selectedPosition should only be updated if the selection was valid (i.e. a piece of current player was selected).
    final piece = state.board[event.position.row][event.position.col];
    if (piece != null && piece.color == state.currentPlayer) {
        emit(state.copyWith(
          selectedPosition: event.position, // Update selected position
          validMoves: validMoves,
        ));
    } else {
        // If piece is null or not current player's piece, treat as invalid selection.
        // Clear previous selection and valid moves.
        emit(state.copyWith(
          selectedPosition: null,
          validMoves: [],
        ));
    }
  }

  void _onMovePiece(MovePiece event, Emitter<GameState> emit) {
    // selectedPosition should be event.from.
    // The GameLogicService.handleMove now takes 'from' and 'to' positions.
    // It also handles the validation of the move against the current valid moves.
    if (state.selectedPosition == null || state.selectedPosition != event.from) {
        // This case should ideally not happen if UI is driven by selectedPosition and validMoves.
        // Or, it means a move was attempted without prior selection.
        // For robustness, we can choose to ignore or handle as an error.
        return; 
    }
    
    final newState = _gameLogicService.handleMove(state, event.from, event.to);
    emit(newState);
  }

  void _onPromotePawn(PromotePawn event, Emitter<GameState> emit) {
    // Ensure that a promotion is actually pending and the position matches.
    if (!state.isPendingPromotion || state.promotionPosition != event.position) {
      // This event should only occur when state.isPendingPromotion is true
      // and event.position matches state.promotionPosition.
      // If not, it's an unexpected event, so we might ignore it or log an error.
      return;
    }
    final newState = _gameLogicService.completePawnPromotion(state, event.promotionType);
    emit(newState);
  }

  void _onUndoMove(UndoMove event, Emitter<GameState> emit) {
    if (state.undoStates.isEmpty) return;

    final previousState = state.undoStates.last;
    final newUndoStates = List<GameState>.from(state.undoStates)..removeLast();

    final newRedoStates = List<GameState>.from(state.redoStates)
      ..insert(0, state.copyWith( // current state before undoing
        undoStates: newUndoStates, // this will be the undoStates of the *next* state if we redo
        redoStates: [], // redoStates are cleared when a new move is made or state changes not via redo
        // Ensure other relevant fields are part of this copy if they could change
        // but for undo/redo, we are primarily restoring a past state.
      ));

    // When emitting the previousState, we also need to provide it with the updated redoStates list.
    emit(previousState.copyWith(
      // moveHistory is part of the state snapshot, so it's restored.
      undoStates: newUndoStates,
      redoStates: newRedoStates, // crucial for enabling redo
      selectedPosition: null, // Clear selection when undoing
      validMoves: [], // Clear valid moves
    ));
  }

  void _onRedoMove(RedoMove event, Emitter<GameState> emit) {
    if (state.redoStates.isEmpty) return;

    final nextState = state.redoStates.first; // Get the state to redo
    final newRedoStates = List<GameState>.from(state.redoStates)..removeAt(0);

    // Current state before redoing is added to undoStates
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state.copyWith(
      // Ensure this copy is what we want on the undo stack.
      // Typically, it's the state just before this redo operation.
      undoStates: state.undoStates, // This will be the undo stack of the current state
      redoStates: newRedoStates, // This will be the redo stack of the current state
    ));

    // Emit the nextState (the one we are redoing to)
    // It should already have its own correct undo/redo stacks from when it was previously current.
    // However, the standard practice is to manage undo/redo stacks centrally.
    // So, we update the emitted state's undo/redo lists.
    emit(nextState.copyWith(
      undoStates: newUndoStates,
      redoStates: newRedoStates,
      selectedPosition: null, // Clear selection when redoing
      validMoves: [], // Clear valid moves
    ));
  }

  void _onSaveGame(SaveGame event, Emitter<GameState> emit) {
    // TODO: Implement save game functionality
  }

  void _onLoadGame(LoadGame event, Emitter<GameState> emit) {
    // TODO: Implement load game functionality
  }

  void _onToggleHintMode(ToggleHintMode event, Emitter<GameState> emit) {
    emit(state.copyWith(
      hintMode: !state.hintMode,
      // selectedPosition and validMoves should persist through hint mode toggle
      // If a piece is selected, its valid moves should still be shown or hidden based on new hintMode.
      selectedPosition: state.selectedPosition, 
      validMoves: state.validMoves,
    ));
  }

  void _onStartNewGameFromCurrentPosition(
    StartNewGameFromCurrentPosition event,
    Emitter<GameState> emit,
  ) {
    // Create new game state from current board
    final newState = state.copyWith(
      // Keep current board state
      currentPlayer: state.currentPlayer, // Or allow specifying starting player
      // Clear history and status
      moveHistory: [],
      undoStates: [],
      redoStates: [],
      selectedPosition: null,
      validMoves: [],
      specialMoveMessage: null,
      lastMove: null,
      // Set new game mode and interactivity
      gameMode: event.gameMode,
      isInteractive: event.isInteractive,
      allowedPlayer: event.allowedPlayer,
      // Reset check/game over states
      isCheck: false,
      isCheckmate: false,
      isStalemate: false,
      isPendingPromotion: false,
      promotionPosition: null,
      // Reset move count
      currentMoveNumber: 0, // A new game starts from move 0
    );

    emit(newState);
  }

  void _onSetBoardInteractivity(
    SetBoardInteractivity event,
    Emitter<GameState> emit,
  ) {
    emit(state.copyWith(
      isInteractive: event.isInteractive,
      allowedPlayer: event.allowedPlayer,
      // If board becomes non-interactive, clear selection and valid moves
      selectedPosition: event.isInteractive ? state.selectedPosition : null,
      validMoves: event.isInteractive ? state.validMoves : [],
    ));
  }

  void _onSetGameMode(
    SetGameMode event,
    Emitter<GameState> emit,
  ) {
    emit(state.copyWith(
      gameMode: event.gameMode,
    ));
  }
}