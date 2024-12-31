import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';

import '../blocs/chess_bloc.dart';
import '../blocs/chess_event.dart';
import '../models/chess_models.dart';
import '../screens/game_screen.dart';
import '../utils/chess_rules.dart';
import '../services/settings_service.dart';
import '../utils/chess_constants.dart';
import '../utils/chess_formatters.dart';

// 主入口组件
class ChessBoard extends StatelessWidget {
  final GameMode gameMode;
  final bool isInteractive;
  final PieceColor? allowedPlayer;

  const ChessBoard({
    super.key,
    required this.gameMode,
    this.isInteractive = true,
    this.allowedPlayer,
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
              isInteractive: isInteractive,
              allowedPlayer: allowedPlayer,
              gameMode: gameMode,
            )),
          child: _ChessBoardView(
            gameMode: gameMode,
            isInteractive: isInteractive,
            allowedPlayer: allowedPlayer,
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

  const _ChessBoardView({
    required this.gameMode,
    required this.isInteractive,
    this.allowedPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessBloc, GameState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(ChessFormatters.getGameModeTitle(gameMode)),
            actions: [
              if (!state.isInteractive)
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: '从当前局面开始新对局',
                  onPressed: () => _showNewGameDialog(context, state),
                ),
            ],
          ),
          body: const ChessBoardLayout(),
        );
      },
    );
  }

  void _showNewGameDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开始新对局'),
        content: const Text('是否要从当前局面开始新的对局？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<ChessBloc>().add(
                StartNewGameFromCurrentPosition(
                  gameMode: gameMode,
                  isInteractive: true,
                  allowedPlayer: null,
                ),
              );
              Navigator.pop(context);
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
  const ChessBoardLayout({super.key});

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
                const TurnIndicator(),
                const SizedBox(height: ChessConstants.spacing),
                const SpecialMoveIndicator(),
                const SizedBox(height: ChessConstants.spacing),
                const ControlButtons(),
                const SizedBox(height: ChessConstants.spacing),
                ChessBoardGrid(boardSize: boardSize),
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
      ChessConstants.spacing * 4
    );

    return min(
      min(maxBoardSize, availableWidth * 0.9),
      availableHeight * 0.7,
    );
  }
}

// 回合指示器组件
class TurnIndicator extends StatelessWidget {
  const TurnIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessBloc, GameState>(
      builder: (context, state) {
        return Text(
          '当前回合: ${state.currentPlayer == PieceColor.white ? "白方" : "黑方"}',
          style: const TextStyle(fontSize: 20),
        );
      },
    );
  }
}

// 特殊移动提示组件
class SpecialMoveIndicator extends StatelessWidget {
  const SpecialMoveIndicator({super.key});

  @override
  Widget build(BuildContext context) {
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
}

// 移动信息内容组件
class MoveMessageContent extends StatelessWidget {
  final GameState state;

  const MoveMessageContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final lastMove = state.lastMove;
    if (lastMove == null) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...[
        ChessPieceImage(piece: lastMove.piece),
        const SizedBox(width: 8),
      ],
        if (lastMove.isPromotion && lastMove.promotionType != null)
          _buildPromotionMessage(lastMove)
        else
          Text(
            state.specialMoveMessage ??
            ChessFormatters.buildDefaultMoveMessage(lastMove),
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

// 控制按钮组件
class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessBloc, GameState>(
      builder: (context, state) {
        return SizedBox(
          height: ChessConstants.controlButtonsHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUndoButton(context, state),
              const SizedBox(width: 20),
              _buildRedoButton(context, state),
              const SizedBox(width: 20),
              _buildHintButton(context, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUndoButton(BuildContext context, GameState state) {
    return ElevatedButton.icon(
      onPressed: state.undoStates.isEmpty ? null : () {
        context.read<ChessBloc>().add(const UndoMove());
      },
      icon: const Icon(Icons.undo),
      label: const Text('前一步'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildRedoButton(BuildContext context, GameState state) {
    return ElevatedButton.icon(
      onPressed: state.redoStates.isEmpty ? null : () {
        context.read<ChessBloc>().add(const RedoMove());
      },
      icon: const Icon(Icons.redo),
      label: const Text('后一步'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildHintButton(BuildContext context, GameState state) {
    return ElevatedButton.icon(
      onPressed: () {
        context.read<ChessBloc>().add(const ToggleHintMode());
      },
      icon: Icon(state.hintMode ? Icons.lightbulb : Icons.lightbulb_outline),
      label: Text(state.hintMode ? '关闭提示' : '开启提示'),
      style: ElevatedButton.styleFrom(
        backgroundColor: state.hintMode ? Colors.yellow[100] : Colors.grey[100],
        foregroundColor: Colors.black,
      ),
    );
  }
}

// 棋盘网格组件
class ChessBoardGrid extends StatelessWidget {
  final double boardSize;

  const ChessBoardGrid({
    super.key,
    required this.boardSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: boardSize + 30,
      height: boardSize + 30,
      child: Column(
        children: [
          BoardColumnLabels(),
          Expanded(
            child: Row(
              children: [
                BoardRowLabels(),
                const Expanded(
                  child: ChessBoardSquares(),
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
    );
  }
}

// 棋盘列标签组件
class BoardColumnLabels extends StatelessWidget {
  const BoardColumnLabels({super.key});

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
                  String.fromCharCode('A'.codeUnitAt(0) + col),
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
  const BoardRowLabels({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Column(
        children: List.generate(8, (row) {
          return Expanded(
            child: Center(
              child: Text(
                '${8 - row}',
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
