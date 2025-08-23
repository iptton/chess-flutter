import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/chess_models.dart';
import '../screens/game_screen.dart';
import '../utils/chess_rules.dart';
import '../services/chess_ai.dart';
import 'chess_event.dart';

class ChessBloc extends Bloc<ChessEvent, GameState> {
  ChessAI? _chessAI;

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
    on<StartNewGameFromCurrentPosition>(_onStartNewGameFromCurrentPosition);
    on<SetBoardInteractivity>(_onSetBoardInteractivity);
    on<SetGameMode>(_onSetGameMode);
    on<MakeAIMove>(_onMakeAIMove);
    on<SetAIDifficulty>(_onSetAIDifficulty);
  }

  void _onInitializeGame(InitializeGame event, Emitter<GameState> emit) async {
    if (event.replayGame != null) {
      // 初始化复盘状态
      final initialState = await GameState.initialFromPrefs(
        hintMode: event.hintMode,
        isInteractive: event.isInteractive,
        allowedPlayer: event.allowedPlayer,
        gameMode: event.gameMode,
        aiDifficulty: event.aiDifficulty,
        aiColor: event.aiColor,
      );

      // 生成所有中间状态
      final states = <GameState>[initialState];
      var currentState = initialState;

      // 应用所有移动来生成中间状态
      for (final move in event.replayGame!.moves) {
        currentState = await _applyMove(currentState, move);
        states.add(currentState);
      }

      // 正常复盘模式
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
        aiDifficulty: event.aiDifficulty,
        aiColor: event.aiColor,
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
      aiDifficulty: event.aiDifficulty,
      aiColor: event.aiColor,
    );

    // 初始化AI（如果需要）
    if (event.gameMode == GameMode.offline && event.aiDifficulty != null) {
      _chessAI = ChessAI(difficulty: event.aiDifficulty!);
    }

    emit(initialState);

    // 检查是否需要AI先手
    _checkForAIMove(emit);
  }

  Future<GameState> _applyMove(GameState state, ChessMove move) async {
    // 创建新的棋盘状态
    final newBoard = List<List<ChessPiece?>>.from(
      state.board.map((row) => List<ChessPiece?>.from(row)),
    );

    // 移动棋子
    newBoard[move.to.row][move.to.col] = move.piece;
    newBoard[move.from.row][move.from.col] = null;

    // 处理吃过路兵
    if (move.isEnPassant) {
      newBoard[move.from.row][move.to.col] = null;
    }

    // 处理王车易位
    if (move.isCastling) {
      final rookFromCol = move.from.col > move.to.col ? 0 : 7;
      final rookToCol = move.from.col > move.to.col ? 3 : 5;
      newBoard[move.from.row][rookToCol] = newBoard[move.from.row][rookFromCol];
      newBoard[move.from.row][rookFromCol] = null;
    }

    // 处理升变
    if (move.isPromotion && move.promotionType != null) {
      newBoard[move.to.row][move.to.col] = ChessPiece(
        type: move.promotionType!,
        color: move.piece.color,
      );
    }

    // 更新状态
    return state.copyWith(
      board: newBoard,
      currentPlayer: state.currentPlayer == PieceColor.white
          ? PieceColor.black
          : PieceColor.white,
      selectedPosition: null,
      validMoves: const [],
      moveHistory: List.from(state.moveHistory)..add(move),
      lastMove: move,
    );
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
    if (state.allowedPlayer != null &&
        state.currentPlayer != state.allowedPlayer) {
      emit(state.copyWith(
        selectedPosition: null,
        validMoves: [],
      ));
      return;
    }

    final piece = state.board[event.position.row][event.position.col];

    // 检查是否是当前玩家的棋子
    if (piece?.color != state.currentPlayer) {
      emit(state.copyWith(
        selectedPosition: null,
        validMoves: [],
      ));
      return;
    }

    final validMoves = ChessRules.getValidMoves(
      state.board,
      event.position,
      hasKingMoved: state.hasKingMoved,
      hasRookMoved: state.hasRookMoved,
      // 修复：对于吃过路兵，应该根据当前回合玩家来传递对手的双步兵位置
      lastPawnDoubleMoved:
          state.lastPawnDoubleMoved[state.currentPlayer == PieceColor.white
              ? PieceColor.black // 如果当前是白方回合，则查找黑方的双步兵
              : PieceColor.white], // 如果当前是黑方回合，则查找白方的双步兵
      lastPawnDoubleMovedNumber: state.lastPawnDoubleMovedNumber[
          state.currentPlayer == PieceColor.white
              ? PieceColor.black
              : PieceColor.white],
      currentMoveNumber: state.currentMoveNumber,
    );

    emit(state.copyWith(
      selectedPosition: event.position,
      validMoves: validMoves,
    ));
  }

  void _onMovePiece(MovePiece event, Emitter<GameState> emit) {
    // 检查是否是AI移动（AI移动时不需要先选中棋子）
    final isAIMove = state.isAIThinking ||
        (state.gameMode == GameMode.offline &&
            state.aiColor == state.currentPlayer);

    if (!isAIMove && state.selectedPosition == null) {
      return;
    }

    // 对于AI移动，我们需要验证移动是否合法
    if (isAIMove) {
      // 获取该位置棋子的合法移动
      final piece = state.board[event.from.row][event.from.col];
      if (piece == null || piece.color != state.currentPlayer) {
        return;
      }

      // 使用chess规则验证移动
      final validMoves = ChessRules.getValidMoves(
        state.board,
        event.from,
        hasKingMoved: state.hasKingMoved,
        hasRookMoved: state.hasRookMoved,
        // 修复：为AI移动验证也添加吃过路兵参数，根据当前回合玩家传递对手双步兵信息
        lastPawnDoubleMoved: state.lastPawnDoubleMoved[
            state.currentPlayer == PieceColor.white
                ? PieceColor.black
                : PieceColor.white],
        lastPawnDoubleMovedNumber: state.lastPawnDoubleMovedNumber[
            state.currentPlayer == PieceColor.white
                ? PieceColor.black
                : PieceColor.white],
        currentMoveNumber: state.currentMoveNumber,
      );
      final isValidMove = validMoves
          .any((pos) => pos.row == event.to.row && pos.col == event.to.col);

      if (!isValidMove) {
        return;
      }
    } else {
      // 人类移动的原有逻辑
      final isValidMove = state.validMoves
          .any((pos) => pos.row == event.to.row && pos.col == event.to.col);
      if (!isValidMove) {
        return;
      }
    }

    final movingPiece = state.board[event.from.row][event.from.col]!;
    final capturedPiece = state.board[event.to.row][event.to.col];
    final newBoard = List<List<ChessPiece?>>.from(
        state.board.map((row) => List<ChessPiece?>.from(row)));

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
    _handleRegularMove(event, movingPiece, capturedPiece, newBoard,
        newLastPawnDoubleMoved, emit);
  }

  bool _isCastlingMove(ChessPiece movingPiece, MovePiece event) {
    return movingPiece.type == PieceType.king &&
        (event.from.col - event.to.col).abs() == 2;
  }

  void _handleCastling(MovePiece event, ChessPiece movingPiece,
      List<List<ChessPiece?>> newBoard, Emitter<GameState> emit) {
    final isKingside = event.to.col > event.from.col;
    final rookFromCol = isKingside ? 7 : 0;
    final rookToCol = isKingside ? 5 : 3;

    // 移动王
    newBoard[event.to.row][event.to.col] = movingPiece;
    newBoard[event.from.row][event.from.col] = null;

    // 移动车 - 修复：确保车正确移动
    final rook = newBoard[event.from.row][rookFromCol];
    print(
        '王车易位: 车从(${event.from.row}, $rookFromCol)移动到(${event.from.row}, $rookToCol)');
    print('车棋子: $rook');
    newBoard[event.from.row][rookToCol] = rook;
    newBoard[event.from.row][rookFromCol] = null;

    // 更新王的移动状态
    final newHasKingMoved = Map<PieceColor, bool>.from(state.hasKingMoved);
    newHasKingMoved[movingPiece.color] = true;

    // 修复：更新车的移动状态
    final newHasRookMoved = Map<PieceColor, Map<String, bool>>.from(
      state.hasRookMoved.map(
        (color, value) => MapEntry(
          color,
          Map<String, bool>.from(value),
        ),
      ),
    );
    // 标记参与易位的车为已移动
    if (isKingside) {
      newHasRookMoved[movingPiece.color]!['kingside'] = true;
    } else {
      newHasRookMoved[movingPiece.color]!['queenside'] = true;
    }

    final move = ChessMove(
      from: event.from,
      to: event.to,
      piece: movingPiece,
      isCastling: true,
    );

    String message =
        '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}王从${_getPositionName(event.from)}进行${isKingside ? "王翼" : "后翼"}易位到${_getPositionName(event.to)}';

    // 检查对手是否被将军或将死
    final nextPlayer = state.currentPlayer == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck &&
        ChessRules.isCheckmate(
          newBoard,
          nextPlayer,
          newHasKingMoved,
          newHasRookMoved, // 使用更新后的车移动状态
          state.lastPawnDoubleMoved,
          state.lastPawnDoubleMovedNumber,
          state.currentMoveNumber + 1,
        );
    final isStalemate = !isCheck &&
        ChessRules.isStalemate(
          newBoard,
          nextPlayer,
          newHasKingMoved,
          newHasRookMoved, // 使用更新后的车移动状态
          state.lastPawnDoubleMoved,
          state.lastPawnDoubleMovedNumber,
          state.currentMoveNumber + 1,
        );

    // 添加将军或将死的提示
    if (isCheckmate) {
      message +=
          ' 将死！${state.currentPlayer == PieceColor.white ? "白方" : "黑方"}获胜！';
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
      hasRookMoved: newHasRookMoved, // 修复：添加缺失的车移动状态更新
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [...state.moveHistory, move],
      specialMoveMessage: message,
      lastMove: move,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      undoStates: newUndoStates,
      redoStates: [], // 清空重做列表
      isAIThinking: false, // 清除AI思考状态
    ));

    // 检查是否需要AI移动
    _checkForAIMove(emit);
  }

  bool _isPawnDoubleMove(ChessPiece movingPiece, MovePiece event) {
    return movingPiece.type == PieceType.pawn &&
        (event.from.row - event.to.row).abs() == 2;
  }

  bool _isEnPassantMove(
      ChessPiece movingPiece, MovePiece event, ChessPiece? capturedPiece) {
    // 获取对手的双步兵记录
    final opponentColor = movingPiece.color == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    final opponentLastPawnDoubleMoved =
        state.lastPawnDoubleMoved[opponentColor];
    final opponentLastMoveNumber =
        state.lastPawnDoubleMovedNumber[opponentColor];

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

  void _handleEnPassant(MovePiece event, ChessPiece movingPiece,
      List<List<ChessPiece?>> newBoard, Emitter<GameState> emit) {
    final opponentColor = movingPiece.color == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    final opponentLastPawnDoubleMoved =
        state.lastPawnDoubleMoved[opponentColor]!;

    // 获取被吃的兵
    final capturedPawn = state.board[opponentLastPawnDoubleMoved.row]
        [opponentLastPawnDoubleMoved.col]!;

    // 移除被吃的兵
    newBoard[opponentLastPawnDoubleMoved.row][opponentLastPawnDoubleMoved.col] =
        null;

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
    final newLastPawnDoubleMoved =
        Map<PieceColor, Position?>.from(state.lastPawnDoubleMoved);
    final newLastPawnDoubleMovedNumber =
        Map<PieceColor, int>.from(state.lastPawnDoubleMovedNumber);
    newLastPawnDoubleMoved[opponentColor] = null;
    newLastPawnDoubleMovedNumber[opponentColor] = -1;

    String message =
        '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}兵从${_getPositionName(event.from)}吃过路兵到${_getPositionName(event.to)}';

    // 检查对手是否被将军或将死
    final nextPlayer = state.currentPlayer == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck &&
        ChessRules.isCheckmate(
          newBoard,
          nextPlayer,
          state.hasKingMoved,
          state.hasRookMoved,
          newLastPawnDoubleMoved,
          newLastPawnDoubleMovedNumber,
          state.currentMoveNumber + 1,
        );
    final isStalemate = !isCheck &&
        ChessRules.isStalemate(
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
      message +=
          ' 将死！${state.currentPlayer == PieceColor.white ? "白方" : "黑方"}获胜！';
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
      isAIThinking: false, // 清除AI思考状态
    ));

    // 检查是否需要AI移动
    _checkForAIMove(emit);
  }

  bool _isPawnPromotion(ChessPiece movingPiece, MovePiece event) {
    return movingPiece.type == PieceType.pawn &&
        (event.to.row == 0 || event.to.row == 7);
  }

  void _handlePawnPromotion(MovePiece event, ChessPiece movingPiece,
      List<List<ChessPiece?>> newBoard, Emitter<GameState> emit) {
    // 修复：在升变前保存当前状态，使升变作为整体操作
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state);

    newBoard[event.to.row][event.to.col] = movingPiece;
    newBoard[event.from.row][event.from.col] = null;

    final move = ChessMove(
      from: event.from,
      to: event.to,
      piece: movingPiece,
      isPromotion: true,
    );

    // 创建新的双步兵记录
    final newLastPawnDoubleMoved =
        Map<PieceColor, Position?>.from(state.lastPawnDoubleMoved);
    final newLastPawnDoubleMovedNumber =
        Map<PieceColor, int>.from(state.lastPawnDoubleMovedNumber);

    // 修复：升变时不切换玩家，等待用户选择升变类型后再切换

    emit(state.copyWith(
      board: newBoard,
      // 修复：不切换currentPlayer，保持当前玩家不变
      selectedPosition: null,
      validMoves: [],
      lastPawnDoubleMoved: newLastPawnDoubleMoved,
      lastPawnDoubleMovedNumber: newLastPawnDoubleMovedNumber,
      currentMoveNumber: state.currentMoveNumber + 1,
      moveHistory: [...state.moveHistory, move],
      lastMove: move,
      undoStates: newUndoStates,
      redoStates: [], // 清空重做列表
      isAIThinking: false, // 清除AI思考状态
    ));

    // 修复：升变时不检查AI移动，等升变完成后再检查
  }

  void _handleRegularMove(
      MovePiece event,
      ChessPiece movingPiece,
      ChessPiece? capturedPiece,
      List<List<ChessPiece?>> newBoard,
      Position? newLastPawnDoubleMoved,
      Emitter<GameState> emit) {
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

    Map<PieceColor, bool> newHasKingMoved =
        Map<PieceColor, bool>.from(state.hasKingMoved);
    if (movingPiece.type == PieceType.king) {
      newHasKingMoved[movingPiece.color] = true;
    }

    // 更新双步兵记录
    final newLastPawnDoubleMoved =
        Map<PieceColor, Position?>.from(state.lastPawnDoubleMoved);
    final newLastPawnDoubleMovedNumber =
        Map<PieceColor, int>.from(state.lastPawnDoubleMovedNumber);

    if (movingPiece.type == PieceType.pawn &&
        (event.from.row - event.to.row).abs() == 2) {
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
      message =
          '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}${_getPieceTypeName(movingPiece.type)}(${_getPositionName(event.from)})吃掉${capturedPiece.color == PieceColor.white ? "白方" : "黑方"}${_getPieceTypeName(capturedPiece.type)}(${_getPositionName(event.to)})';
    } else {
      message =
          '${movingPiece.color == PieceColor.white ? "白方" : "黑方"}${_getPieceTypeName(movingPiece.type)}从${_getPositionName(event.from)}移动到${_getPositionName(event.to)}';
    }

    // 检查对手是否被将军或将死
    final nextPlayer = state.currentPlayer == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck &&
        ChessRules.isCheckmate(
          newBoard,
          nextPlayer,
          newHasKingMoved,
          newHasRookMoved ?? state.hasRookMoved,
          newLastPawnDoubleMoved,
          newLastPawnDoubleMovedNumber,
          state.currentMoveNumber + 1,
        );
    final isStalemate = !isCheck &&
        ChessRules.isStalemate(
          newBoard,
          nextPlayer,
          newHasKingMoved,
          newHasRookMoved ?? state.hasRookMoved,
          newLastPawnDoubleMoved,
          newLastPawnDoubleMovedNumber,
          state.currentMoveNumber + 1,
        );

    // 添加将军或将死的提示
    if (isCheckmate) {
      message +=
          ' 将死！${state.currentPlayer == PieceColor.white ? "白方" : "黑方"}获胜！';
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
      isAIThinking: false, // 清除AI思考状态
    ));

    // 检查是否需要AI移动
    _checkForAIMove(emit);
  }

  String _getPositionName(Position position) {
    // 添加坐标验证以防止超出范围的索引
    if (position.col < 0 ||
        position.col > 7 ||
        position.row < 0 ||
        position.row > 7) {
      // 如果坐标异常，返回一个错误指示
      return '无效位置(${position.row},${position.col})';
    }

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
        state.board.map((row) => List<ChessPiece?>.from(row)));

    // 验证位置是否有效
    if (event.position.row < 0 ||
        event.position.row >= 8 ||
        event.position.col < 0 ||
        event.position.col >= 8) {
      print('错误：升变位置超出边界: (${event.position.row}, ${event.position.col})');
      return;
    }

    final pawn = newBoard[event.position.row][event.position.col];
    if (pawn == null) {
      print('错误：升变位置没有棋子: (${event.position.row}, ${event.position.col})');
      return;
    }

    final promotedPiece = ChessPiece(
      type: event.promotionType,
      color: pawn.color,
    );

    newBoard[event.position.row][event.position.col] = promotedPiece;

    // 获取最后一步移动，如果没有历史记录则创建一个默认移动
    ChessMove lastMove;
    if (state.moveHistory.isNotEmpty) {
      lastMove = state.moveHistory.last.copyWith(
        isPromotion: true,
        promotionType: event.promotionType,
      );
    } else {
      // 如果没有历史记录，创建一个默认的升变移动
      // 对于升变，起始位置应该是兵升变前的位置
      final isWhite = pawn.color == PieceColor.white;
      final fromRow = isWhite ? 6 : 1; // 白方从第6行升变到第0行，黑方从第1行升变到第7行
      lastMove = ChessMove(
        from: Position(row: fromRow, col: event.position.col), // 使用正确的起始位置
        to: event.position, // 升变目标位置
        piece: pawn,
        isPromotion: true,
        promotionType: event.promotionType,
      );
    }

    // 检查对手是否被将军或将死
    final nextPlayer = state.currentPlayer == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;

    // 创建清理后的双步兵记录，确保没有无效坐标
    final cleanLastPawnDoubleMoved = <PieceColor, Position?>{};
    final cleanLastPawnDoubleMovedNumber = <PieceColor, int>{};

    for (final color in PieceColor.values) {
      final position = state.lastPawnDoubleMoved[color];
      final moveNumber = state.lastPawnDoubleMovedNumber[color];

      // 验证坐标有效性
      if (position != null &&
          position.row >= 0 &&
          position.row <= 7 &&
          position.col >= 0 &&
          position.col <= 7) {
        cleanLastPawnDoubleMoved[color] = position;
        cleanLastPawnDoubleMovedNumber[color] = moveNumber ?? -1;
      } else {
        cleanLastPawnDoubleMoved[color] = null;
        cleanLastPawnDoubleMovedNumber[color] = -1;
      }
    }

    final isCheck = ChessRules.isInCheck(newBoard, nextPlayer);
    final isCheckmate = isCheck &&
        ChessRules.isCheckmate(
          newBoard,
          nextPlayer,
          state.hasKingMoved,
          state.hasRookMoved,
          cleanLastPawnDoubleMoved,
          cleanLastPawnDoubleMovedNumber,
          state.currentMoveNumber + 1,
        );
    final isStalemate = !isCheck &&
        ChessRules.isStalemate(
          newBoard,
          nextPlayer,
          state.hasKingMoved,
          state.hasRookMoved,
          cleanLastPawnDoubleMoved,
          cleanLastPawnDoubleMovedNumber,
          state.currentMoveNumber + 1,
        );

    String message =
        '${pawn.color == PieceColor.white ? "白方" : "黑方"}兵从${_getPositionName(lastMove.from)}升变为${_getPieceTypeName(event.promotionType)}到${_getPositionName(lastMove.to)}';

    // 添加将军或将死的提示
    if (isCheckmate) {
      message +=
          ' 将死！${state.currentPlayer == PieceColor.white ? "白方" : "黑方"}获胜！';
    } else if (isCheck) {
      message += ' 将军！';
    } else if (isStalemate) {
      message += ' 和棋！';
    }

    // 修复：不再重复保存撤销状态，因为_handlePawnPromotion已经保存了
    // 只更新棋盘和玩家状态

    emit(state.copyWith(
      board: newBoard,
      currentPlayer: nextPlayer, // 修复：添加缺失的玩家切换
      moveHistory: state.moveHistory.isNotEmpty
          ? [
              ...state.moveHistory.sublist(0, state.moveHistory.length - 1),
              lastMove,
            ]
          : [lastMove], // 如果没有历史记录，直接添加新移动
      specialMoveMessage: message,
      lastMove: lastMove,
      isCheck: isCheck,
      isCheckmate: isCheckmate,
      isStalemate: isStalemate,
      // 修复：不更新撤销状态，保持现有的撤销列表
      redoStates: [], // 清空重做列表
    ));

    // 检查是否需要AI移动
    _checkForAIMove(emit);
  }

  void _onUndoMove(UndoMove event, Emitter<GameState> emit) {
    if (state.undoStates.isEmpty) return;

    // 获取前一步的状态
    final previousState = state.undoStates.last;
    final newUndoStates = List<GameState>.from(state.undoStates)..removeLast();

    // 将当前状态添加到重做列表的开头
    final newRedoStates = List<GameState>.from(state.redoStates)
      ..insert(
          0,
          state.copyWith(
            undoStates: newUndoStates,
            redoStates: [],
          ));

    emit(previousState.copyWith(
      moveHistory: state.moveHistory,
      undoStates: newUndoStates,
      redoStates: newRedoStates,
      selectedPosition: null,
      validMoves: [],
    ));
  }

  void _onRedoMove(RedoMove event, Emitter<GameState> emit) {
    if (state.redoStates.isEmpty) return;

    // 获取下一步的状态
    final nextState = state.redoStates[0];
    final newRedoStates = List<GameState>.from(state.redoStates)..removeAt(0);

    // 将当前状态添加到撤销列表
    final newUndoStates = List<GameState>.from(state.undoStates)..add(state);

    emit(nextState.copyWith(
      moveHistory: state.moveHistory,
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

  void _onStartNewGameFromCurrentPosition(
    StartNewGameFromCurrentPosition event,
    Emitter<GameState> emit,
  ) {
    // 从当前棋局创建新的游戏状态
    final newState = state.copyWith(
      // 保持当前棋盘状态
      currentPlayer: state.currentPlayer,
      // 清除历史记录和状态
      moveHistory: [],
      undoStates: [],
      redoStates: [],
      selectedPosition: null,
      validMoves: [],
      specialMoveMessage: null,
      lastMove: null,
      // 设置新的游戏模式和交互状态
      gameMode: event.gameMode,
      isInteractive: event.isInteractive,
      allowedPlayer: event.allowedPlayer,
      // 重置检查状态
      isCheck: false,
      isCheckmate: false,
      isStalemate: false,
      // 重置移动计数
      currentMoveNumber: 0,
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

  void _onMakeAIMove(
    MakeAIMove event,
    Emitter<GameState> emit,
  ) async {
    // 检查是否是AI的回合
    if (state.gameMode != GameMode.offline ||
        state.aiColor == null ||
        state.currentPlayer != state.aiColor ||
        state.isAIThinking ||
        state.isCheckmate ||
        state.isStalemate) {
      return;
    }

    print('AI开始思考...');
    // 设置AI思考状态
    if (!emit.isDone) {
      emit(state.copyWith(isAIThinking: true));
    }

    try {
      // 初始化AI（如果还没有初始化）
      if (_chessAI == null || _chessAI!.difficulty != state.aiDifficulty) {
        _chessAI =
            ChessAI(difficulty: state.aiDifficulty ?? AIDifficulty.medium);
        print('初始化AI: 难度=${state.aiDifficulty}');
      }

      // 获取AI移动
      print('调用AI获取最佳移动...');
      final aiMove = await _chessAI!.getBestMove(
        state.board,
        state.currentPlayer,
        hasKingMoved: state.hasKingMoved,
        hasRookMoved: state.hasRookMoved,
        enPassantTarget: _getEnPassantTarget(state),
        halfMoveClock: 0, // 简化处理
        fullMoveNumber: (state.currentMoveNumber ~/ 2) + 1,
      );

      if (aiMove != null) {
        print('AI找到移动: 从${aiMove.from}到${aiMove.to}');
        // 使用Future.microtask延迟发送移动事件，避免emitter重复使用
        Future.microtask(() {
          if (!isClosed) {
            add(MovePiece(aiMove.from, aiMove.to));
          }
        });
      } else {
        print('AI没有找到合法移动');
        // AI没有找到合法移动，清除思考状态
        if (!emit.isDone) {
          emit(state.copyWith(isAIThinking: false));
        }
      }
    } catch (e) {
      print('AI移动失败: $e');
      // AI移动失败，清除思考状态
      if (!emit.isDone) {
        emit(state.copyWith(isAIThinking: false));
      }
    }
  }

  void _onSetAIDifficulty(
    SetAIDifficulty event,
    Emitter<GameState> emit,
  ) {
    emit(state.copyWith(aiDifficulty: event.difficulty));
    // 重新初始化AI
    _chessAI = ChessAI(difficulty: event.difficulty);
  }

  /// 获取吃过路兵目标位置
  Position? _getEnPassantTarget(GameState state) {
    final opponentColor = state.currentPlayer == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;

    final lastPawnDoubleMoved = state.lastPawnDoubleMoved[opponentColor];
    final lastPawnDoubleMovedNumber =
        state.lastPawnDoubleMovedNumber[opponentColor];

    if (lastPawnDoubleMoved != null &&
        lastPawnDoubleMovedNumber == state.currentMoveNumber - 1) {
      // 计算吃过路兵的目标位置
      final direction = opponentColor == PieceColor.white ? 1 : -1;
      final targetRow = lastPawnDoubleMoved.row + direction;

      // 添加边界检查，防止坐标越界
      if (targetRow >= 0 && targetRow <= 7) {
        return Position(
          row: targetRow,
          col: lastPawnDoubleMoved.col,
        );
      }
    }

    return null;
  }

  /// 检查是否应该触发AI移动
  void _checkForAIMove(Emitter<GameState> emit) {
    if (state.gameMode == GameMode.offline &&
        state.aiColor != null &&
        state.currentPlayer == state.aiColor &&
        !state.isAIThinking &&
        !state.isCheckmate &&
        !state.isStalemate) {
      // 使用Future.microtask延迟触发AI移动，避免emitter重复使用
      print('触发AI移动: 当前玩家=${state.currentPlayer}, AI颜色=${state.aiColor}');
      Future.microtask(() {
        if (!isClosed) {
          add(MakeAIMove());
        }
      });
    }
  }
}
