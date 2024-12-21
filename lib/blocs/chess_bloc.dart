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
    if (_isCastlingMove(movingPiece, event)) {
      _handleCastling(event, movingPiece, newBoard, emit);
      return;
    }

    // 记录双步移动的兵
    Position? newLastPawnDoubleMoved;
    if (_isPawnDoubleMove(movingPiece, event)) {
      newLastPawnDoubleMoved = event.to;
    }

    // 处理吃过路兵
    if (_isEnPassantMove(movingPiece, event, capturedPiece)) {
      _handleEnPassant(event, movingPiece, newBoard, emit);
      return;
    }

    // 处理兵的升变
    if (_isPawnPromotion(movingPiece, event)) {
      _handlePawnPromotion(event, movingPiece, newBoard, emit);
      return;
    }

    // 执行常规移动
    _handleRegularMove(event, movingPiece, capturedPiece, newBoard, newLastPawnDoubleMoved, emit);
  }

  bool _isCastlingMove(ChessPiece movingPiece, MovePiece event) {
    return movingPiece.type == PieceType.king &&
           (event.from.col - event.to.col).abs() == 2;
  }

  void _handleCastling(MovePiece event, ChessPiece movingPiece, List<List<ChessPiece?>> newBoard, Emitter<GameState> emit) {
    final isKingside = event.to.col > event.from.col;
    final rookFromCol = isKingside ? 7 : 0;
    final rookToCol = isKingside ? 5 : 3;

    newBoard[event.to.row][event.to.col] = movingPiece;
    newBoard[event.from.row][event.from.col] = null;
    newBoard[event.from.row][rookToCol] = newBoard[event.from.row][rookFromCol];
    newBoard[event.from.row][rookFromCol] = null;

    final newHasKingMoved = Map<PieceColor, bool>.from(state.hasKingMoved);
    newHasKingMoved[movingPiece.color] = true;

    final move = ChessMove(
      from: event.from,
      to: event.to,
      piece: movingPiece,
      isCastling: true,
    );

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == PieceColor.white
          ? PieceColor.black
          : PieceColor.white,
      selectedPosition: null,
      validMoves: [],
      hasKingMoved: newHasKingMoved,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [...state.moveHistory, move],
      specialMoveMessage: '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}进行${isKingside ? "王翼" : "后翼"}易位',
      lastMove: move,
    ));
  }

  bool _isPawnDoubleMove(ChessPiece movingPiece, MovePiece event) {
    return movingPiece.type == PieceType.pawn &&
           (event.from.row - event.to.row).abs() == 2;
  }

  bool _isEnPassantMove(ChessPiece movingPiece, MovePiece event, ChessPiece? capturedPiece) {
    final lastPawnDoubleMoved = state.lastPawnDoubleMoved;
    if (movingPiece.type != PieceType.pawn ||
        lastPawnDoubleMoved == null ||
        event.from.col == event.to.col ||
        state.lastMoveNumber != state.currentMoveNumber - 1) {
      return false;
    }

    // 检查是否是吃过路兵的位置
    if (movingPiece.color == PieceColor.white) {
      return event.from.row == 3 && // 白方兵在第5行
             lastPawnDoubleMoved.row == 3 && // 黑方兵在第5行
             lastPawnDoubleMoved.col == event.to.col && // 目标列与黑方兵相同
             (event.from.col - event.to.col).abs() == 1; // 斜向移动一格
    } else {
      return event.from.row == 4 && // 黑方兵在第4行
             lastPawnDoubleMoved.row == 4 && // 白方兵在第4行
             lastPawnDoubleMoved.col == event.to.col && // 目标列与白方兵相同
             (event.from.col - event.to.col).abs() == 1; // 斜向移动一格
    }
  }

  void _handleEnPassant(MovePiece event, ChessPiece movingPiece, List<List<ChessPiece?>> newBoard, Emitter<GameState> emit) {
    // 获取被吃的兵
    final capturedPawn = state.board[state.lastPawnDoubleMoved!.row][state.lastPawnDoubleMoved!.col]!;

    // 移除被吃的兵
    newBoard[state.lastPawnDoubleMoved!.row][state.lastPawnDoubleMoved!.col] = null;

    // 移动吃子的兵
    newBoard[event.to.row][event.to.col] = movingPiece;
    newBoard[event.from.row][event.from.col] = null;

    final move = ChessMove(
      from: event.from,
      to: event.to,
      piece: movingPiece,
      capturedPiece: capturedPawn,
      isEnPassant: true,
    );

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == PieceColor.white
          ? PieceColor.black
          : PieceColor.white,
      selectedPosition: null,
      validMoves: [],
      lastPawnDoubleMoved: null,
      lastMoveNumber: state.currentMoveNumber,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [...state.moveHistory, move],
      specialMoveMessage: '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}吃过路兵',
      lastMove: move,
    ));
  }

  bool _isPawnPromotion(ChessPiece movingPiece, MovePiece event) {
    return movingPiece.type == PieceType.pawn &&
           (event.to.row == 0 || event.to.row == 7);
  }

  void _handlePawnPromotion(MovePiece event, ChessPiece movingPiece, List<List<ChessPiece?>> newBoard, Emitter<GameState> emit) {
    newBoard[event.to.row][event.to.col] = movingPiece;
    newBoard[event.from.row][event.from.col] = null;

    final move = ChessMove(
      from: event.from,
      to: event.to,
      piece: movingPiece,
      isPromotion: true,
    );

    emit(state.copyWith(
      board: newBoard,
      selectedPosition: null,
      validMoves: [],
      lastPawnDoubleMoved: null,
      lastMoveNumber: state.currentMoveNumber,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [...state.moveHistory, move],
      specialMoveMessage: '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}兵升变',
      lastMove: move,
    ));
  }

  void _handleRegularMove(MovePiece event, ChessPiece movingPiece, ChessPiece? capturedPiece, List<List<ChessPiece?>> newBoard, Position? newLastPawnDoubleMoved, Emitter<GameState> emit) {
    newBoard[event.to.row][event.to.col] = movingPiece;
    newBoard[event.from.row][event.from.col] = null;

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

    final move = ChessMove(
      from: event.from,
      to: event.to,
      piece: movingPiece,
      capturedPiece: capturedPiece,
      isEnPassant: false,
    );

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
      moveHistory: [...state.moveHistory, move],
      specialMoveMessage: capturedPiece != null
          ? '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}吃掉${capturedPiece.color == PieceColor.white ? "白方" : "黑方"}'
          : null,
      lastMove: move,
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