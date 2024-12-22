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
    on<ToggleHintMode>(_onToggleHintMode);
  }

  void _onInitializeGame(InitializeGame event, Emitter<GameState> emit) async {
    final initialState = await GameState.initialFromPrefs();
    emit(initialState);
  }

  void _onSelectPiece(SelectPiece event, Emitter<GameState> emit) {
    // 如果游戏已经结束（将死或和棋），不允许移动
    if (state.isCheckmate || state.isStalemate) {
      emit(state.copyWith(
        selectedPosition: null,
        validMoves: [],
      ));
      return;
    }

    final piece = state.board[event.position.row][event.position.col];

    if (piece != null && piece.color == state.currentPlayer) {
      final validMoves = ChessRules.getValidMoves(
        state.board,
        event.position,
        hasKingMoved: state.hasKingMoved,
        hasRookMoved: state.hasRookMoved,
        lastPawnDoubleMoved: state.lastPawnDoubleMoved[piece.color == PieceColor.white ? PieceColor.black : PieceColor.white],
        lastPawnDoubleMovedNumber: state.lastPawnDoubleMovedNumber[piece.color == PieceColor.white ? PieceColor.black : PieceColor.white],
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

    String message = '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}王从${_getPositionName(event.from)}进行${isKingside ? "王翼" : "后翼"}易位到${_getPositionName(event.to)}';

    // 检查对手是否被将军或将死
    final nextPlayer = state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck && ChessRules.isCheckmate(
      newBoard,
      nextPlayer,
      newHasKingMoved,
      state.hasRookMoved,
      state.lastPawnDoubleMoved,
      state.lastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );
    final isStalemate = !isCheck && ChessRules.isStalemate(
      newBoard,
      nextPlayer,
      newHasKingMoved,
      state.hasRookMoved,
      state.lastPawnDoubleMoved,
      state.lastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );

    // 添加将军或将死的提示
    if (isCheckmate) {
      message += ' 将死！${nextPlayer == PieceColor.white ? "白方" : "黑方"}获胜！';
    } else if (isCheck) {
      message += ' 将军！';
    } else if (isStalemate) {
      message += ' 和棋！';
    }

    // 保存当前状态到撤销列表
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state);

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      selectedPosition: null,
      validMoves: [],
      hasKingMoved: newHasKingMoved,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [...state.moveHistory, move],
      specialMoveMessage: message,
      lastMove: move,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      undoStates: newUndoStates,
      redoStates: [], // 清空重做列表
    ));
  }

  bool _isPawnDoubleMove(ChessPiece movingPiece, MovePiece event) {
    return movingPiece.type == PieceType.pawn &&
           (event.from.row - event.to.row).abs() == 2;
  }

  bool _isEnPassantMove(ChessPiece movingPiece, MovePiece event, ChessPiece? capturedPiece) {
    // 获取对手的双步兵记录
    final opponentColor = movingPiece.color == PieceColor.white ? PieceColor.black : PieceColor.white;
    final opponentLastPawnDoubleMoved = state.lastPawnDoubleMoved[opponentColor];
    final opponentLastMoveNumber = state.lastPawnDoubleMovedNumber[opponentColor];

    if (movingPiece.type != PieceType.pawn ||
        opponentLastPawnDoubleMoved == null ||
        event.from.col == event.to.col ||
        opponentLastMoveNumber != state.currentMoveNumber - 1) {
      return false;
    }

    // 检查是否是吃过路兵的位置
    if (movingPiece.color == PieceColor.white) {
      return event.from.row == 3 && // 白方兵在第5行
             opponentLastPawnDoubleMoved.row == 3 && // 黑方兵在第5行
             opponentLastPawnDoubleMoved.col == event.to.col && // 目标列与黑方兵相同
             (event.from.col - event.to.col).abs() == 1; // 斜向移动一格
    } else {
      return event.from.row == 4 && // 黑方兵在第4行
             opponentLastPawnDoubleMoved.row == 4 && // 白方兵在第4行
             opponentLastPawnDoubleMoved.col == event.to.col && // 目标列与白方兵相同
             (event.from.col - event.to.col).abs() == 1; // 斜向移动一格
    }
  }

  void _handleEnPassant(MovePiece event, ChessPiece movingPiece, List<List<ChessPiece?>> newBoard, Emitter<GameState> emit) {
    final opponentColor = movingPiece.color == PieceColor.white ? PieceColor.black : PieceColor.white;
    final opponentLastPawnDoubleMoved = state.lastPawnDoubleMoved[opponentColor]!;

    // 获取被吃的兵
    final capturedPawn = state.board[opponentLastPawnDoubleMoved.row][opponentLastPawnDoubleMoved.col]!;

    // 移除被吃的兵
    newBoard[opponentLastPawnDoubleMoved.row][opponentLastPawnDoubleMoved.col] = null;

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

    // 创建新的双步兵记录
    final newLastPawnDoubleMoved = Map<PieceColor, Position?>.from(state.lastPawnDoubleMoved);
    final newLastPawnDoubleMovedNumber = Map<PieceColor, int>.from(state.lastPawnDoubleMovedNumber);
    newLastPawnDoubleMoved[opponentColor] = null;
    newLastPawnDoubleMovedNumber[opponentColor] = -1;

    String message = '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}兵从${_getPositionName(event.from)}吃过路兵到${_getPositionName(event.to)}';

    // 检查对手是否被将军或将死
    final nextPlayer = state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck && ChessRules.isCheckmate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      state.hasRookMoved,
      newLastPawnDoubleMoved,
      newLastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );
    final isStalemate = !isCheck && ChessRules.isStalemate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      state.hasRookMoved,
      newLastPawnDoubleMoved,
      newLastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );

    // 添加将军或将死的提示
    if (isCheckmate) {
      message += ' 将死！${nextPlayer == PieceColor.white ? "白方" : "黑方"}获胜！';
    } else if (isCheck) {
      message += ' 将军！';
    } else if (isStalemate) {
      message += ' 和棋！';
    }

    // 保存当前状态到撤销列表
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state);

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      selectedPosition: null,
      validMoves: [],
      lastPawnDoubleMoved: newLastPawnDoubleMoved,
      lastPawnDoubleMovedNumber: newLastPawnDoubleMovedNumber,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [...state.moveHistory, move],
      specialMoveMessage: message,
      lastMove: move,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      undoStates: newUndoStates,
      redoStates: [], // 清空重做列表
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

    // 创建新的双步兵记录
    final newLastPawnDoubleMoved = Map<PieceColor, Position?>.from(state.lastPawnDoubleMoved);
    final newLastPawnDoubleMovedNumber = Map<PieceColor, int>.from(state.lastPawnDoubleMovedNumber);

    // 保存当前状态到撤销列表
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state);

    emit(state.copyWith(
      board: newBoard,
      selectedPosition: null,
      validMoves: [],
      lastPawnDoubleMoved: newLastPawnDoubleMoved,
      lastPawnDoubleMovedNumber: newLastPawnDoubleMovedNumber,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [...state.moveHistory, move],
      lastMove: move,
      undoStates: newUndoStates,
      redoStates: [], // 清空重做列表
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

    // 更新双步兵记录
    final newLastPawnDoubleMoved = Map<PieceColor, Position?>.from(state.lastPawnDoubleMoved);
    final newLastPawnDoubleMovedNumber = Map<PieceColor, int>.from(state.lastPawnDoubleMovedNumber);

    if (movingPiece.type == PieceType.pawn && (event.from.row - event.to.row).abs() == 2) {
      newLastPawnDoubleMoved[movingPiece.color] = event.to;
      newLastPawnDoubleMovedNumber[movingPiece.color] = state.currentMoveNumber;
    } else {
      // 如果不是双步移动，清除当前玩家的双步兵记录
      newLastPawnDoubleMoved[movingPiece.color] = null;
      newLastPawnDoubleMovedNumber[movingPiece.color] = -1;
    }

    final move = ChessMove(
      from: event.from,
      to: event.to,
      piece: movingPiece,
      capturedPiece: capturedPiece,
      isEnPassant: false,
    );

    // 生成移动提示信息
    String message;
    if (capturedPiece != null) {
      message = '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}${_getPieceTypeName(movingPiece.type)}(${_getPositionName(event.from)})吃掉${capturedPiece.color == PieceColor.white ? "白方" : "黑方"}${_getPieceTypeName(capturedPiece.type)}(${_getPositionName(event.to)})';
    } else {
      message = '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}${_getPieceTypeName(movingPiece.type)}从${_getPositionName(event.from)}移动到${_getPositionName(event.to)}';
    }

    // 检查对手是否被将军或将死
    final nextPlayer = state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck && ChessRules.isCheckmate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      newHasRookMoved ?? state.hasRookMoved,
      newLastPawnDoubleMoved,
      newLastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );
    final isStalemate = !isCheck && ChessRules.isStalemate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      newHasRookMoved ?? state.hasRookMoved,
      newLastPawnDoubleMoved,
      newLastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );

    // 添加将军或将死的提示
    if (isCheckmate) {
      message += ' 将死！${nextPlayer == PieceColor.white ? "白方" : "黑方"}获胜！';
    } else if (isCheck) {
      message += ' 将军！';
    } else if (isStalemate) {
      message += ' 和棋！';
    }

    // 保存当前状态到撤销列表
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state);

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      selectedPosition: null,
      validMoves: [],
      hasRookMoved: newHasRookMoved,
      lastPawnDoubleMoved: newLastPawnDoubleMoved,
      lastPawnDoubleMovedNumber: newLastPawnDoubleMovedNumber,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [...state.moveHistory, move],
      specialMoveMessage: message,
      lastMove: move,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      undoStates: newUndoStates,
      redoStates: [], // 清空重做列表
    ));
  }

  String _getPositionName(Position position) {
    final col = String.fromCharCode('A'.codeUnitAt(0) + position.col);
    final row = 8 - position.row;
    return '$col$row';
  }

  String _getPieceTypeName(PieceType type) {
    switch (type) {
      case PieceType.king:
        return "王";
      case PieceType.queen:
        return "后";
      case PieceType.bishop:
        return "象";
      case PieceType.knight:
        return "马";
      case PieceType.rook:
        return "车";
      case PieceType.pawn:
        return "兵";
    }
  }

  void _onPromotePawn(PromotePawn event, Emitter<GameState> emit) {
    final newBoard = List<List<ChessPiece?>>.from(
      state.board.map((row) => List<ChessPiece?>.from(row))
    );
    final pawn = newBoard[event.position.row][event.position.col]!;
    final promotedPiece = ChessPiece(
      type: event.promotionType,
      color: pawn.color,
    );

    newBoard[event.position.row][event.position.col] = promotedPiece;

    // 获取最后一步移动
    final lastMove = state.moveHistory.last.copyWith(
      isPromotion: true,
      promotionType: event.promotionType,
    );

    // 检查对手是否被将军或将死
    final nextPlayer = state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck && ChessRules.isCheckmate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      state.hasRookMoved,
      state.lastPawnDoubleMoved,
      state.lastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );
    final isStalemate = !isCheck && ChessRules.isStalemate(
      newBoard,
      nextPlayer,
      state.hasKingMoved,
      state.hasRookMoved,
      state.lastPawnDoubleMoved,
      state.lastPawnDoubleMovedNumber,
      state.currentMoveNumber + 1,
    );

    String message = '${pawn.color == PieceColor.white ? "白方" : "黑方"}兵从${_getPositionName(lastMove.from)}升变为${_getPieceTypeName(event.promotionType)}到${_getPositionName(lastMove.to)}';

    // 添加将军或将死的提示
    if (isCheckmate) {
      message += ' 将死！${nextPlayer == PieceColor.white ? "白方" : "黑方"}获胜！';
    } else if (isCheck) {
      message += ' 将军！';
    } else if (isStalemate) {
      message += ' 和棋！';
    }

    // 保存当前状态到撤销列表
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state);

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer,
      moveHistory: [
        ...state.moveHistory.sublist(0, state.moveHistory.length - 1),
        lastMove,
      ],
      specialMoveMessage: message,
      lastMove: lastMove,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      undoStates: newUndoStates,
      redoStates: [], // 清空重做列表
    ));
  }

  void _onUndoMove(UndoMove event, Emitter<GameState> emit) {
    if (state.undoStates.isEmpty) return;

    // 获取前一步的状态
    final previousState = state.undoStates.last;
    final newUndoStates = List<GameState>.from(state.undoStates)..removeLast();

    // 将当前状态添加到重做列表
    final newRedoStates = List<GameState>.from(state.redoStates)..add(state);

    emit(previousState.copyWith(
      undoStates: newUndoStates,
      redoStates: newRedoStates,
      selectedPosition: null,
      validMoves: [],
    ));
  }

  void _onRedoMove(RedoMove event, Emitter<GameState> emit) {
    if (state.redoStates.isEmpty) return;

    // 获取后一步的状态
    final nextState = state.redoStates.last;
    final newRedoStates = List<GameState>.from(state.redoStates)..removeLast();

    // 将当前状态添加到撤销列表
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state);

    emit(nextState.copyWith(
      undoStates: newUndoStates,
      redoStates: newRedoStates,
      selectedPosition: null,
      validMoves: [],
    ));
  }

  void _onSaveGame(SaveGame event, Emitter<GameState> emit) {
    // TODO: 实现保存游戏功能
  }

  void _onLoadGame(LoadGame event, Emitter<GameState> emit) {
    // TODO: 实现加载游戏功能
  }

  void _onToggleHintMode(ToggleHintMode event, Emitter<GameState> emit) {
    emit(state.copyWith(
      hintMode: !state.hintMode,
      selectedPosition: state.selectedPosition,
      validMoves: state.validMoves,
    ));
  }
}