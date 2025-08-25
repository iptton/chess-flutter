import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';

import '../blocs/chess_bloc.dart';
import '../blocs/chess_event.dart';
import '../blocs/replay_bloc.dart';
import '../models/chess_models.dart';
import '../models/game_history.dart';
import '../screens/game_screen.dart';
import '../utils/chess_rules.dart';
import '../services/settings_service.dart';
import '../services/chess_ai.dart';
import '../utils/chess_constants.dart';
import '../utils/chess_formatters.dart';
import '../services/game_history_service.dart';

// 主入口组件
class ChessBoard extends StatelessWidget {
  final GameMode gameMode;
  final bool isInteractive;
  final PieceColor? allowedPlayer;
  final GameHistory? replayGame;
  final List<List<ChessPiece?>>? initialBoard;
  final PieceColor? initialPlayer;
  final List<ChessMove>? initialMoves;
  final AIDifficulty? aiDifficulty;
  final PieceColor? aiColor;
  final ChessAI? advancedAI; // 新增：支持高级AI实例

  const ChessBoard({
    super.key,
    required this.gameMode,
    this.isInteractive = true,
    this.allowedPlayer,
    this.replayGame,
    this.initialBoard,
    this.initialPlayer,
    this.initialMoves,
    this.aiDifficulty,
    this.aiColor,
    this.advancedAI, // 新增：高级AI实例参数
  });

  @override
  Widget build(BuildContext context) {
    print('ChessBoard: build方法被调用');
    print(
        'ChessBoard: gameMode=${gameMode.name}, advancedAI=${advancedAI != null ? advancedAI!.advancedDifficulty.displayName : "null"}');

    return FutureBuilder<bool>(
      future: SettingsService.getDefaultHintMode(),
      builder: (context, snapshot) {
        print(
            'ChessBoard: FutureBuilder - hasData=${snapshot.hasData}, data=${snapshot.data}');

        // 修复：在未拿到设置前不要初始化对局，避免默认使用 false
        if (!snapshot.hasData) {
          print('ChessBoard: 显示加载指示器');
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('ChessBoard: 获取设置失败: ${snapshot.error}');
          return Center(child: Text('加载失败: ${snapshot.error}'));
        }

        final defaultHintMode = snapshot.data!;
        print('ChessBoard: 创建BlocProvider, hintMode=$defaultHintMode');

        return BlocProvider(
          create: (context) {
            print('ChessBoard: 创建ChessBloc...');
            final bloc = ChessBloc();
            print('ChessBoard: 正在发送InitializeGame事件...');
            bloc.add(InitializeGame(
              defaultHintMode,
              isInteractive: replayGame != null ? false : isInteractive,
              allowedPlayer: allowedPlayer,
              gameMode: gameMode,
              replayGame: replayGame,
              initialBoard: initialBoard,
              initialPlayer: initialPlayer,
              initialMoves: initialMoves,
              aiDifficulty: aiDifficulty,
              aiColor: aiColor,
              advancedAI: advancedAI, // 传递高级AI实例
            ));
            print('ChessBoard: InitializeGame事件已发送');
            return bloc;
          },
          child: _ChessBoardView(
            gameMode: gameMode,
            isInteractive: replayGame != null ? false : isInteractive,
            allowedPlayer: allowedPlayer,
            isReplayMode: replayGame != null,
          ),
        );
      },
    );
  }
}

// 主视图组件
class _ChessBoardView extends StatelessWidget {
  final GameMode gameMode;
  final bool isInteractive;
  final PieceColor? allowedPlayer;
  final bool isReplayMode;

  const _ChessBoardView({
    required this.gameMode,
    required this.isInteractive,
    required this.isReplayMode,
    this.allowedPlayer,
  });

  Future<void> _saveGame(GameState state) async {
    if (state.moveHistory.isNotEmpty) {
      final history = GameHistory(
        id: GameHistoryService.generateGameId(),
        startTime: DateTime.now()
            .subtract(Duration(minutes: state.moveHistory.length)), // 估算开始时间
        endTime: DateTime.now(),
        moves: state.moveHistory,
        winner: state.isCheckmate
            ? (state.currentPlayer == PieceColor.white
                ? PieceColor.black
                : PieceColor.white)
            : null,
        gameMode: gameMode,
        isCompleted: state.isCheckmate || state.isStalemate,
      );
      await GameHistoryService.saveGame(history);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessBloc, GameState>(
      builder: (context, state) {
        if ((state.isCheckmate || state.isStalemate) && !isReplayMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _saveGame(state);
          });
        }

        return WillPopScope(
          onWillPop: () async {
            // 如果有历史步数，且未结束显示确认对话框
            if (!isReplayMode && state.moveHistory.isNotEmpty) {
              bool shouldSave = true; // 默认勾选保存
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: const Text('退出对局'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('确定要退出吗？'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: shouldSave,
                              onChanged: (value) {
                                setState(() {
                                  shouldSave = value ?? true;
                                });
                              },
                            ),
                            const Text('保存当前棋局'),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // 如果选择保存，则保存游戏历史
                          if (shouldSave && state.moveHistory.isNotEmpty) {
                            final history = GameHistory(
                              id: GameHistoryService.generateGameId(),
                              startTime: DateTime.now().subtract(Duration(
                                  minutes: state.moveHistory.length)), // 估算开始时间
                              endTime: DateTime.now(),
                              moves: state.moveHistory,
                              winner: state.isCheckmate
                                  ? (state.currentPlayer == PieceColor.white
                                      ? PieceColor.black
                                      : PieceColor.white)
                                  : null,
                              gameMode: gameMode,
                              isCompleted:
                                  state.isCheckmate || state.isStalemate,
                            );
                            await GameHistoryService.saveGame(history);
                          }
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                ),
              );
              return shouldPop ?? false;
            }
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(isReplayMode
                  ? '对局复盘'
                  : ChessFormatters.getGameModeTitle(gameMode)),
              actions: [
                if (isReplayMode)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: '从当前局面开始新对局',
                    onPressed: () => _showNewGameDialog(context, state),
                  ),
              ],
            ),
            body: ChessBoardLayout(
              topContent: [
                _buildTurnIndicator(context),
                _buildSpecialMoveIndicator(context),
                _buildControls(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTurnIndicator(BuildContext context) {
    return BlocBuilder<ChessBloc, GameState>(
      builder: (context, state) {
        String turnText =
            '当前回合: ${state.currentPlayer == PieceColor.white ? "白方" : "黑方"}';

        // 如果是单机对战模式，显示AI状态
        if (state.gameMode == GameMode.offline && state.aiColor != null) {
          if (state.currentPlayer == state.aiColor) {
            if (state.isAIInitializing) {
              turnText += ' (AI初始化中...)';
            } else if (state.isAIThinking) {
              turnText += ' (AI思考中...)';
            } else {
              turnText += ' (AI)';
            }
          } else {
            turnText += ' (玩家)';
          }
        }

        return Column(
          children: [
            // 第一行：回合信息
            Text(
              turnText,
              style: const TextStyle(fontSize: 20),
            ),
            // 第二行：提示按钮
            if (!isReplayMode) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<ChessBloc>().add(const ToggleHintMode());
                },
                icon: Icon(
                    state.hintMode ? Icons.lightbulb : Icons.lightbulb_outline),
                label: Text(state.hintMode ? '关闭提示' : '开启提示'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      state.hintMode ? Colors.yellow[100] : Colors.grey[100],
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            // 第二行：AI难度信息
            if (state.gameMode == GameMode.offline &&
                state.aiDifficulty != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'AI难度: ${_getDifficultyText(state.aiDifficulty!)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getDifficultyText(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return '简单';
      case AIDifficulty.medium:
        return '中等';
      case AIDifficulty.hard:
        return '困难';
    }
  }

  Widget _buildSpecialMoveIndicator(BuildContext context) {
    return BlocBuilder<ChessBloc, GameState>(
      builder: (context, state) {
        if (state.lastMove == null) {
          return const SizedBox(height: ChessConstants.specialMoveHeight);
        }

        return Container(
          height: ChessConstants.specialMoveHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: MoveMessageContent(state: state),
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, GameState state) {
    // 计算当前步数和总步数
    final totalSteps = state.moveHistory.length;
    final currentStep = totalSteps - state.redoStates.length;

    return SizedBox(
      height: ChessConstants.controlButtonsHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: state.undoStates.isEmpty
                ? null
                : () {
                    context.read<ChessBloc>().add(const UndoMove());
                  },
            icon: const Icon(Icons.undo),
            label: Text(isReplayMode ? '上一步' : '前一步'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[100],
              foregroundColor: Colors.black,
            ),
          ),
          const SizedBox(width: 20),
          if (isReplayMode)
            Text(
              '$currentStep/$totalSteps',
              style: const TextStyle(fontSize: 16),
            ),
          if (isReplayMode) const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: state.redoStates.isEmpty
                ? null
                : () {
                    context.read<ChessBloc>().add(const RedoMove());
                  },
            icon: const Icon(Icons.redo),
            label: Text(isReplayMode ? '下一步' : '后一步'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[100],
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _showNewGameDialog(BuildContext context, GameState state) {
    // 计算当前步数
    final currentStep = state.moveHistory.length - state.redoStates.length;
    final currentMoves = state.moveHistory.sublist(0, currentStep);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('开始新对局'),
        content: const Text('是否要从当前局面开始新的对局？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext); // 先关闭对话框
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChessBoard(
                    gameMode: GameMode.faceToFace,
                    initialBoard: state.board,
                    initialPlayer: state.currentPlayer,
                    isInteractive: true,
                    initialMoves: currentMoves,
                  ),
                ),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// 布局组件
class ChessBoardLayout extends StatelessWidget {
  final List<Widget> topContent;

  const ChessBoardLayout({
    super.key,
    required this.topContent,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessBloc, GameState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final boardSize = _calculateBoardSize(constraints);

            return Stack(
              children: [
                // 主体内容
                SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: ChessConstants.topBarHeight),
                        ...topContent
                            .expand((widget) => [
                                  widget,
                                  const SizedBox(height: ChessConstants.spacing),
                                ])
                            .toList(),
                        ChessBoardGrid(boardSize: boardSize),
                        const SizedBox(height: ChessConstants.spacing),
                      ],
                    ),
                  ),
                ),
                // AI初始化加载遮罩
                if (state.isAIInitializing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'AI引擎初始化中...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '请稍候，正在加载国际象棋AI引擎',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  double _calculateBoardSize(BoxConstraints constraints) {
    final availableHeight = constraints.maxHeight;
    final availableWidth = constraints.maxWidth;

    final maxBoardSize = availableHeight -
        (ChessConstants.topBarHeight +
            ChessConstants.turnIndicatorHeight +
            ChessConstants.specialMoveHeight +
            ChessConstants.controlButtonsHeight +
            ChessConstants.spacing * 5);

    return min(
      min(maxBoardSize, availableWidth * 0.9),
      availableHeight * 0.7,
    );
  }
}

// 棋盘网格组件
class ChessBoardGrid extends StatelessWidget {
  final double boardSize;
  final bool isReplayMode;
  final bool isFlipped;

  const ChessBoardGrid({
    super.key,
    required this.boardSize,
    this.isReplayMode = false,
    this.isFlipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: boardSize + 30,
      height: boardSize + 30,
      child: Column(
        children: [
          BoardColumnLabels(isFlipped: isFlipped),
          Expanded(
            child: Row(
              children: [
                BoardRowLabels(isFlipped: isFlipped),
                Expanded(
                  child: isReplayMode
                      ? const ReplayChessBoardSquares()
                      : const ChessBoardSquares(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 棋盘方格组件
class ChessBoardSquares extends StatelessWidget {
  const ChessBoardSquares({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessBloc, GameState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 64,
            itemBuilder: (context, index) => ChessSquare(
              index: index,
              state: state,
            ),
          ),
        );
      },
    );
  }
}

// 复盘棋盘方格组件
class ReplayChessBoardSquares extends StatelessWidget {
  const ReplayChessBoardSquares({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReplayBloc, ReplayState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            itemCount: 64,
            itemBuilder: (context, index) => ChessSquare(
              index: index,
              state: state,
            ),
          ),
        );
      },
    );
  }
}

// 单个棋盘方格组件
class ChessSquare extends StatelessWidget {
  final int index;
  final GameState state;

  const ChessSquare({
    super.key,
    required this.index,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final row = index ~/ 8;
    final col = index % 8;
    final isDark = (row + col) % 2 == 1;
    final isSelected = state.selectedPosition?.row == row &&
        state.selectedPosition?.col == col;
    final isValidMove =
        state.validMoves.any((pos) => pos.row == row && pos.col == col);
    final isMovablePiece = _isMovablePiece(state, row, col);

    // 检查是否是最后移动的位置
    final isLastMoveFrom =
        state.lastMove?.from.row == row && state.lastMove?.from.col == col;
    final isLastMoveTo =
        state.lastMove?.to.row == row && state.lastMove?.to.col == col;

    return GestureDetector(
      onTap: state.isInteractive ? () => _handleTap(context, row, col) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(isDark, isLastMoveTo),
          if (state.board[row][col] != null)
            _buildPiece(state.board[row][col]!),
          if (state.hintMode && isValidMove) _buildMoveHint(isDark),
          if (isSelected ||
              (state.hintMode && (isValidMove || isMovablePiece)) ||
              (state.isCheck &&
                  !state.hintMode &&
                  (state.isCheck ? isMovablePiece : !isMovablePiece)))
            _buildHighlight(
                isSelected, state.hintMode, isValidMove, isMovablePiece),
          // 添加最后移动的原位置标记（虚框）
          if (isLastMoveFrom) _buildLastMoveFromIndicator(),
        ],
      ),
    );
  }

  bool _isMovablePiece(GameState state, int row, int col) {
    final piece = state.board[row][col];
    if (piece?.color != state.currentPlayer) return false;

    // 获取对手的双步兵信息，并进行安全性检查
    final opponentColor = state.currentPlayer == PieceColor.white
        ? PieceColor.black
        : PieceColor.white;
    final opponentLastPawnDoubleMoved =
        state.lastPawnDoubleMoved[opponentColor];

    // 验证对手双步兵坐标的有效性，防止传递异常坐标给chess库
    Position? safeLastPawnDoubleMoved;
    if (opponentLastPawnDoubleMoved != null &&
        opponentLastPawnDoubleMoved.row >= 0 &&
        opponentLastPawnDoubleMoved.row <= 7 &&
        opponentLastPawnDoubleMoved.col >= 0 &&
        opponentLastPawnDoubleMoved.col <= 7) {
      safeLastPawnDoubleMoved = opponentLastPawnDoubleMoved;
    }

    try {
      return ChessRules.getValidMoves(
        state.board,
        Position(row: row, col: col),
        hasKingMoved: state.hasKingMoved,
        hasRookMoved: state.hasRookMoved,
        lastPawnDoubleMoved: safeLastPawnDoubleMoved,
        lastPawnDoubleMovedNumber:
            state.lastPawnDoubleMovedNumber[opponentColor],
        currentMoveNumber: state.currentMoveNumber,
      ).isNotEmpty;
    } catch (e) {
      // 如果获取有效移动时出现错误，记录错误并返回false
      print('警告：检查棋子是否可移动时出现错误: $e');
      print(
          '位置: ($row, $col), 棋子: ${piece?.type}, 对手双步兵位置: $opponentLastPawnDoubleMoved');
      return false; // 安全地返回false，避免显示错误信息给用户
    }
  }

  Widget _buildBackground(bool isDark, [bool isLastMoveTo = false]) {
    Color backgroundColor;
    if (isLastMoveTo) {
      // 最后移动的目标位置使用更柔和的绿色背景
      backgroundColor = isDark ? Colors.green[400]! : Colors.green[200]!;
    } else {
      backgroundColor = isDark ? Colors.brown[300]! : Colors.brown[100]!;
    }

    return Container(
      color: backgroundColor,
    );
  }

  Widget _buildPiece(ChessPiece piece) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ChessPieceImage(piece: piece),
    );
  }

  Widget _buildMoveHint(bool isDark) {
    return Center(
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildHighlight(
      bool isSelected, bool hintMode, bool isValidMove, bool isMovablePiece) {
    return Container(
      color: isSelected
          ? Colors.blue.withOpacity(0.3)
          : hintMode && (isValidMove || isMovablePiece)
              ? Colors.yellow.withOpacity(0.3)
              : Colors.grey.withOpacity(0.5),
    );
  }

  Widget _buildLastMoveFromIndicator() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.orange[400]!,
          width: 2.0,
          style: BorderStyle.solid,
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int row, int col) {
    final bloc = context.read<ChessBloc>();

    if (state.selectedPosition != null) {
      if (state.validMoves.any((pos) => pos.row == row && pos.col == col)) {
        final from = state.selectedPosition!;
        final to = Position(row: row, col: col);
        final piece = state.board[from.row][from.col]!;

        if (piece.type == PieceType.pawn && (row == 0 || row == 7)) {
          bloc.add(MovePiece(from, to));
          showPromotionDialog(context, to);
        } else {
          bloc.add(MovePiece(from, to));
        }
      } else {
        bloc.add(SelectPiece(Position(row: row, col: col)));
      }
    } else {
      bloc.add(SelectPiece(Position(row: row, col: col)));
    }
  }
}

// 棋子图片组件
class ChessPieceImage extends StatelessWidget {
  final ChessPiece piece;

  const ChessPieceImage({
    super.key,
    required this.piece,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ChessFormatters.getPieceImage(piece),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // 如果图片加载失败，显示一个简单的文本替代
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              _getPieceSymbol(piece),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: piece.color == PieceColor.white
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  String _getPieceSymbol(ChessPiece piece) {
    switch (piece.type) {
      case PieceType.king:
        return piece.color == PieceColor.white ? '♔' : '♚';
      case PieceType.queen:
        return piece.color == PieceColor.white ? '♕' : '♛';
      case PieceType.rook:
        return piece.color == PieceColor.white ? '♖' : '♜';
      case PieceType.bishop:
        return piece.color == PieceColor.white ? '♗' : '♝';
      case PieceType.knight:
        return piece.color == PieceColor.white ? '♘' : '♞';
      case PieceType.pawn:
        return piece.color == PieceColor.white ? '♙' : '♟';
    }
  }
}

// 棋盘列标签组件
class BoardColumnLabels extends StatelessWidget {
  final bool isFlipped;

  const BoardColumnLabels({
    super.key,
    this.isFlipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          const SizedBox(width: 30),
          ...List.generate(8, (col) {
            return Expanded(
              child: Center(
                child: Text(
                  ChessFormatters.getColumnLabel(col, isFlipped: isFlipped),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// 棋盘行标签组件
class BoardRowLabels extends StatelessWidget {
  final bool isFlipped;

  const BoardRowLabels({
    super.key,
    this.isFlipped = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Column(
        children: List.generate(8, (row) {
          return Expanded(
            child: Center(
              child: Text(
                ChessFormatters.getRowLabel(row, isFlipped: isFlipped),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// 升变对话框
Future<void> showPromotionDialog(
    BuildContext context, Position position) async {
  final bloc = context.read<ChessBloc>();
  final currentState = bloc.state;
  final piece = currentState.board[position.row][position.col];
  final pieceColor = piece?.color ?? currentState.currentPlayer;

  final promotedPiece = await showDialog<PieceType>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PromotionDialog(pieceColor: pieceColor);
    },
  );

  if (promotedPiece != null) {
    bloc.add(PromotePawn(position, promotedPiece));
  }
}

// 升变对话框组件
class PromotionDialog extends StatelessWidget {
  final PieceColor pieceColor;

  const PromotionDialog({super.key, required this.pieceColor});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择升变棋子',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PromotionOption(
                      pieceType: PieceType.queen, pieceColor: pieceColor),
                  const SizedBox(width: 8),
                  PromotionOption(
                      pieceType: PieceType.rook, pieceColor: pieceColor),
                  const SizedBox(width: 8),
                  PromotionOption(
                      pieceType: PieceType.bishop, pieceColor: pieceColor),
                  const SizedBox(width: 8),
                  PromotionOption(
                      pieceType: PieceType.knight, pieceColor: pieceColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 升变选项组件
class PromotionOption extends StatelessWidget {
  final PieceType pieceType;
  final PieceColor pieceColor;

  const PromotionOption({
    super.key,
    required this.pieceType,
    required this.pieceColor,
  });

  @override
  Widget build(BuildContext context) {
    final piece = ChessPiece(type: pieceType, color: pieceColor);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(pieceType),
      child: Container(
        width: 60,
        height: 60,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ChessPieceImage(piece: piece),
      ),
    );
  }
}

// 移动信息内容组件
class MoveMessageContent extends StatelessWidget {
  final GameState state;

  const MoveMessageContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final lastMove = state.lastMove;
    if (lastMove == null) return const SizedBox();

    final moveMessage = state.specialMoveMessage ??
        (ChessFormatters.buildDefaultMoveMessage(lastMove) +
            ChessFormatters.buildMoveStateMessage(state));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChessPieceImage(piece: lastMove.piece),
        const SizedBox(width: 8),
        if (lastMove.isPromotion && lastMove.promotionType != null)
          _buildPromotionMessage(lastMove)
        else
          Text(
            moveMessage,
            style: const TextStyle(fontSize: 16),
          ),
        if (lastMove.capturedPiece != null && !lastMove.isPromotion) ...[
          const SizedBox(width: 8),
          ChessPieceImage(piece: lastMove.capturedPiece!),
        ],
      ],
    );
  }

  Widget _buildPromotionMessage(ChessMove move) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${move.piece.color == PieceColor.white ? "白方" : "黑方"}兵从${ChessFormatters.getPositionName(move.from)}升变为',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        if (move.promotionType != null)
          ChessPieceImage(
            piece: ChessPiece(
              type: move.promotionType!,
              color: move.piece.color,
            ),
          ),
        const SizedBox(width: 8),
        Text(
          '到${ChessFormatters.getPositionName(move.to)}',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
