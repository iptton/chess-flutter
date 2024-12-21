import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chess_models.dart';
import '../utils/chess_rules.dart';
import 'chess_event.dart';

class ChessBloc extends Bloc<ChessEvent, GameState> {
  ChessBloc() : super(GameState.initial()) {
    on<InitializeGame>(_onInitializeGame);
    on<SelectPiece>(_onSelectPiece);
    on<MovePiece>(_onMovePiece);
    on<PromotePawn>(_onPromotePawn);
    on<UndoMove>(_onUndoMove);
    on<RedoMove>(_onRedoMove);
    on<SaveGame>(_onSaveGame);
    on<LoadGame>(_onLoadGame);
  }

  void _onInitializeGame(InitializeGame event, Emitter<GameState> emit) {
    emit(GameState.initial());
  }

  void _onSelectPiece(SelectPiece event, Emitter<GameState> emit) {
    final piece = state.board[event.position.row][event.position.col];
    
    if (piece != null && piece.color == state.currentPlayer) {
      final validMoves = ChessRules.getValidMoves(
        state.board,
        event.position,
        hasKingMoved: state.hasKingMoved,
        hasRookMoved: state.hasRookMoved,
        lastPawnDoubleMoved: state.lastPawnDoubleMoved,
        lastMoveNumber: state.lastMoveNumber,
        currentMoveNumber: state.currentMoveNumber,
      );

      emit(state.copyWith(
        selectedPosition: event.position,
        validMoves: validMoves,
      ));
    } else {
      emit(state.copyWith(
        selectedPosition: null,
        validMoves: [],
      ));
    }
  }

  void _onMovePiece(MovePiece event, Emitter<GameState> emit) {
    if (state.selectedPosition == null) return;

    final isValidMove = state.validMoves.any(
      (pos) => pos.row == event.to.row && pos.col == event.to.col
    );
    if (!isValidMove) return;

    final movingPiece = state.board[event.from.row][event.from.col]!;
    final capturedPiece = state.board[event.to.row][event.to.col];
    final newBoard = List<List<ChessPiece?>>.from(
      state.board.map((row) => List<ChessPiece?>.from(row))
    );

    // 处理王车易位
    if (movingPiece.type == PieceType.king && 
        (event.from.col - event.to.col).abs() == 2) {
      final isKingside = event.to.col > event.from.col;
      final rookFromCol = isKingside ? 7 : 0;
      final rookToCol = isKingside ? 5 : 3;
      
      newBoard[event.to.row][event.to.col] = movingPiece;
      newBoard[event.from.row][event.from.col] = null;
      newBoard[event.from.row][rookToCol] = newBoard[event.from.row][rookFromCol];
      newBoard[event.from.row][rookFromCol] = null;

      final newHasKingMoved = Map<PieceColor, bool>.from(state.hasKingMoved);
      newHasKingMoved[movingPiece.color] = true;

      emit(state.copyWith(
        board: newBoard,
        currentPlayer: state.currentPlayer == PieceColor.white 
            ? PieceColor.black 
            : PieceColor.white,
        selectedPosition: null,
        validMoves: [],
        hasKingMoved: newHasKingMoved,
        currentMoveNumber: state.currentMoveNumber + 1,
        moveHistory: [
          ...state.moveHistory,
          ChessMove(
            from: event.from,
            to: event.to,
            piece: movingPiece,
            isCastling: true,
          ),
        ],
      ));
      return;
    }

    // 处理吃过路兵
    if (movingPiece.type == PieceType.pawn && 
        state.lastPawnDoubleMoved != null &&
        event.from.col != event.to.col && 
        capturedPiece == null) {
      newBoard[state.lastPawnDoubleMoved!.row][state.lastPawnDoubleMoved!.col] = null;
    }

    // 记录双步移动的兵
    Position? newLastPawnDoubleMoved;
    if (movingPiece.type == PieceType.pawn && 
        (event.from.row - event.to.row).abs() == 2) {
      newLastPawnDoubleMoved = event.to;
    }

    // 处理兵的升变
    if (movingPiece.type == PieceType.pawn && 
        (event.to.row == 0 || event.to.row == 7)) {
      newBoard[event.to.row][event.to.col] = movingPiece;
      newBoard[event.from.row][event.from.col] = null;
      emit(state.copyWith(
        board: newBoard,
        selectedPosition: null,
        validMoves: [],
        moveHistory: [
          ...state.moveHistory,
          ChessMove(
            from: event.from,
            to: event.to,
            piece: movingPiece,
            isPromotion: true,
          ),
        ],
      ));
      return;
    }

    // 执行常规移动
    newBoard[event.to.row][event.to.col] = movingPiece;
    newBoard[event.from.row][event.from.col] = null;

    // 更新车的移动状态
    Map<PieceColor, Map<String, bool>>? newHasRookMoved;
    if (movingPiece.type == PieceType.rook) {
      newHasRookMoved = Map<PieceColor, Map<String, bool>>.from(
        state.hasRookMoved.map(
          (color, value) => MapEntry(
            color,
            Map<String, bool>.from(value),
          ),
        ),
      );
      if (event.from.col == 0) {
        newHasRookMoved[movingPiece.color]!['queenside'] = true;
      } else if (event.from.col == 7) {
        newHasRookMoved[movingPiece.color]!['kingside'] = true;
      }
    }

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == PieceColor.white 
          ? PieceColor.black 
          : PieceColor.white,
      selectedPosition: null,
      validMoves: [],
      hasRookMoved: newHasRookMoved,
      lastPawnDoubleMoved: newLastPawnDoubleMoved,
      lastMoveNumber: newLastPawnDoubleMoved != null 
          ? state.currentMoveNumber 
          : state.lastMoveNumber,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [
        ...state.moveHistory,
        ChessMove(
          from: event.from,
          to: event.to,
          piece: movingPiece,
          capturedPiece: capturedPiece,
          isEnPassant: capturedPiece == null && 
              movingPiece.type == PieceType.pawn && 
              event.from.col != event.to.col,
        ),
      ],
    ));
  }

  void _onPromotePawn(PromotePawn event, Emitter<GameState> emit) {
    final newBoard = List<List<ChessPiece?>>.from(
      state.board.map((row) => List<ChessPiece?>.from(row))
    );
    final pawn = newBoard[event.position.row][event.position.col]!;

    newBoard[event.position.row][event.position.col] = ChessPiece(
      type: event.promotionType,
      color: pawn.color,
    );

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == PieceColor.white 
          ? PieceColor.black 
          : PieceColor.white,
      moveHistory: [
        ...state.moveHistory,
        if (state.moveHistory.isNotEmpty)
          state.moveHistory.last.copyWith(
            isPromotion: true,
            promotionType: event.promotionType,
          ),
      ],
    ));
  }

  void _onUndoMove(UndoMove event, Emitter<GameState> emit) {
    // TODO: 实现悔棋功能
  }

  void _onRedoMove(RedoMove event, Emitter<GameState> emit) {
    // TODO: 实现重做功能
  }

  void _onSaveGame(SaveGame event, Emitter<GameState> emit) {
    // TODO: 实现保存游戏功能
  }

  void _onLoadGame(LoadGame event, Emitter<GameState> emit) {
    // TODO: 实现加载游戏功能
  }
} 