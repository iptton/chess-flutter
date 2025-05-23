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

  const ChessBoard({
    super.key,
    required this.gameMode,
    this.isInteractive = true,
    this.allowedPlayer,
    this.replayGame,
    this.initialBoard,
    this.initialPlayer,
    this.initialMoves,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SettingsService.getDefaultHintMode(),
      builder: (context, snapshot) {
        final defaultHintMode = snapshot.data ?? false;
        return BlocProvider(
          create: (context) => ChessBloc()
            ..add(InitializeGame(
              defaultHintMode,
              isInteractive: replayGame != null ? false : isInteractive,
              allowedPlayer: allowedPlayer,
              gameMode: gameMode,
              replayGame: replayGame,
              initialBoard: initialBoard,
              initialPlayer: initialPlayer,
              initialMoves: initialMoves,
            )),
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
        startTime: DateTime.now().subtract(Duration(minutes: state.moveHistory.length)), // 估算开始时间
        endTime: DateTime.now(),
        moves: state.moveHistory,
        winner: state.isCheckmate ? (state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white) : null,
        gameMode: gameMode,
        isCompleted: state.isCheckmate || state.isStalemate,
      );
      await GameHistoryService.saveGame(history);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChessBloc, GameState>(
      listener: (context, state) {
        if (state.isPendingPromotion && state.promotionPosition != null) {
          // Ensure the dialog is not already open, if necessary (e.g. by managing a local flag or checking ModalRoute.of(context)?.isCurrent != true)
          // For simplicity, we call it directly here. If it can be called multiple times due to rapid state changes,
          // a more robust check might be needed.
          WidgetsBinding.instance.addPostFrameCallback((_) { // Ensure it's called after build
            if (ModalRoute.of(context)?.isCurrent ?? false) { // Only show if current route is active
                 showPromotionDialog(context, state.promotionPosition!);
            }
          });
        }
        if ((state.isCheckmate || state.isStalemate) && !isReplayMode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _saveGame(state);
          });
        }
      },
      builder: (context, state) {
        // The check for game over and saving is now in the listener.
        // if ((state.isCheckmate || state.isStalemate) && !isReplayMode) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     _saveGame(state);
        //   });
        // }

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
                              startTime: DateTime.now().subtract(Duration(minutes: state.moveHistory.length)), // 估算开始时间
                              endTime: DateTime.now(),
                              moves: state.moveHistory,
                              winner: state.isCheckmate ? (state.currentPlayer == PieceColor.white ? PieceColor.black : PieceColor.white) : null,
                              gameMode: gameMode,
                              isCompleted: state.isCheckmate || state.isStalemate,
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
              title: Text(isReplayMode ? '对局复盘' : ChessFormatters.getGameModeTitle(gameMode)),
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
        return Text(
          '当前回合: ${state.currentPlayer == PieceColor.white ? "白方" : "黑方"}',
          style: const TextStyle(fontSize: 20),
        );
      },
    );
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
            onPressed: state.undoStates.isEmpty ? null : () {
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
          if (isReplayMode)
            const SizedBox(width: 20),
          ElevatedButton.icon(
            onPressed: state.redoStates.isEmpty ? null : () {
              context.read<ChessBloc>().add(const RedoMove());
            },
            icon: const Icon(Icons.redo),
            label: Text(isReplayMode ? '下一步' : '后一步'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[100],
              foregroundColor: Colors.black,
            ),
          ),
          if (!isReplayMode) ...[
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ChessBloc>().add(const ToggleHintMode());
              },
              icon: Icon(state.hintMode ? Icons.lightbulb : Icons.lightbulb_outline),
              label: Text(state.hintMode ? '关闭提示' : '开启提示'),
              style: ElevatedButton.styleFrom(
                backgroundColor: state.hintMode ? Colors.yellow[100] : Colors.grey[100],
                foregroundColor: Colors.black,
              ),
            ),
          ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = _calculateBoardSize(constraints);

        return SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: ChessConstants.topBarHeight),
                ...topContent.expand((widget) => [
                  widget,
                  const SizedBox(height: ChessConstants.spacing),
                ]).toList(),
                ChessBoardGrid(boardSize: boardSize),
                const SizedBox(height: ChessConstants.spacing),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateBoardSize(BoxConstraints constraints) {
    final availableHeight = constraints.maxHeight;
    final availableWidth = constraints.maxWidth;

    final maxBoardSize = availableHeight - (
      ChessConstants.topBarHeight +
      ChessConstants.turnIndicatorHeight +
      ChessConstants.specialMoveHeight +
      ChessConstants.controlButtonsHeight +
      ChessConstants.spacing * 5
    );

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
    final isValidMove = state.validMoves.any(
      (pos) => pos.row == row && pos.col == col
    );
    final isMovablePiece = _isMovablePiece(state, row, col);

    return GestureDetector(
      onTap: state.isInteractive ? () => _handleTap(context, row, col) : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(isDark),
          if (state.board[row][col] != null)
            _buildPiece(state.board[row][col]!),
          if (state.hintMode && isValidMove)
            _buildMoveHint(isDark),
          if (isSelected || (state.hintMode && (isValidMove || isMovablePiece)) ||
              (state.isCheck && !state.hintMode && (state.isCheck ? isMovablePiece : !isMovablePiece)))
            _buildHighlight(isSelected, state.hintMode, isValidMove, isMovablePiece),
        ],
      ),
    );
  }

  bool _isMovablePiece(GameState state, int row, int col) {
    final piece = state.board[row][col];
    if (piece?.color != state.currentPlayer) return false;

    return ChessRules.getValidMoves(
      state.board,
      Position(row: row, col: col),
      hasKingMoved: state.hasKingMoved,
      hasRookMoved: state.hasRookMoved,
      lastPawnDoubleMoved: state.lastPawnDoubleMoved[piece?.color == PieceColor.white ? PieceColor.black : PieceColor.white],
      lastPawnDoubleMovedNumber: state.lastPawnDoubleMovedNumber[piece?.color == PieceColor.white ? PieceColor.black : PieceColor.white],
      currentMoveNumber: state.currentMoveNumber,
    ).isNotEmpty;
  }

  Widget _buildBackground(bool isDark) {
    return Container(
      color: isDark ? Colors.brown[300] : Colors.brown[100],
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

  Widget _buildHighlight(bool isSelected, bool hintMode, bool isValidMove, bool isMovablePiece) {
    return Container(
      color: isSelected
          ? Colors.blue.withOpacity(0.3)
          : hintMode && (isValidMove || isMovablePiece)
              ? Colors.yellow.withOpacity(0.3)
              : Colors.grey.withOpacity(0.5),
    );
  }

  void _handleTap(BuildContext context, int row, int col) {
    final bloc = context.read<ChessBloc>();
    final tappedPosition = Position(row: row, col: col);

    if (state.selectedPosition == null) {
      // No piece is currently selected, so select the tapped piece if it's the current player's.
      final pieceOnTappedSquare = state.board[row][col];
      if (pieceOnTappedSquare != null && pieceOnTappedSquare.color == state.currentPlayer) {
        bloc.add(SelectPiece(tappedPosition));
      }
      // If tapping an empty square or opponent's piece without selection, do nothing or clear selection (already handled by SelectPiece logic in BLoC if needed)
    } else {
      // A piece is selected. Check if the tap is on a valid move.
      if (state.validMoves.any((pos) => pos.row == row && pos.col == col)) {
        bloc.add(MovePiece(state.selectedPosition!, tappedPosition));
      } else {
        // Tapped on a square that's not a valid move for the selected piece.
        // Option 1: Deselect current piece if tapping the same selected piece again.
        if (state.selectedPosition!.row == row && state.selectedPosition!.col == col) {
          bloc.add(SelectPiece(tappedPosition)); // Or a dedicated DeselectPiece event if preferred
        } else {
        // Option 2: Select the new piece if it's the current player's, otherwise keep current selection or clear.
          final pieceOnTappedSquare = state.board[row][col];
          if (pieceOnTappedSquare != null && pieceOnTappedSquare.color == state.currentPlayer) {
            bloc.add(SelectPiece(tappedPosition));
          } else {
            // Tapped on an empty square or an opponent's piece, not a valid move.
            // Optionally, deselect by sending SelectPiece with current selectedPosition
            // or a specific Deselect event, or do nothing to keep selection.
            // For now, let's make it select the new piece if it's selectable, or clear.
            bloc.add(SelectPiece(tappedPosition)); // This will clear if not selectable
          }
        }
      }
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
    );
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
  final promotedPiece = await showDialog<PieceType>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const PromotionDialog();
    },
  );

  if (promotedPiece != null) {
    bloc.add(PromotePawn(position, promotedPiece));
  }
}

// 升变对话框组件
class PromotionDialog extends StatelessWidget {
  const PromotionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '选择升变棋子',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PromotionOption(pieceType: PieceType.queen),
                  SizedBox(width: 8),
                  PromotionOption(pieceType: PieceType.rook),
                  SizedBox(width: 8),
                  PromotionOption(pieceType: PieceType.bishop),
                  SizedBox(width: 8),
                  PromotionOption(pieceType: PieceType.knight),
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

  const PromotionOption({
    super.key,
    required this.pieceType,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Image.asset(
          'assets/images/white_${pieceType.toString().split('.').last}.png',
          fit: BoxFit.contain,
        ),
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
