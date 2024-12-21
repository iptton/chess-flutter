import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';

import '../blocs/chess_bloc.dart';
import '../blocs/chess_event.dart';
import '../models/chess_models.dart';
import '../screens/game_screen.dart';
import '../utils/chess_rules.dart';

class ChessBoard extends StatelessWidget {
  final GameMode gameMode;

  const ChessBoard({
    super.key,
    required this.gameMode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChessBloc()..add(const InitializeGame()),
      child: _ChessBoardView(gameMode: gameMode),
    );
  }
}

class _ChessBoardView extends StatelessWidget {
  final GameMode gameMode;

  const _ChessBoardView({
    required this.gameMode,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChessBloc, GameState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_getGameModeTitle()),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              // 计算可用空间
              final availableHeight = constraints.maxHeight;
              final availableWidth = constraints.maxWidth;
              
              // 计算需要的空间
              const topBarHeight = 20.0; // SizedBox height
              const turnIndicatorHeight = 30.0; // 回合指示器高度
              const specialMoveHeight = 50.0; // 特殊移动提示高度
              const controlButtonsHeight = 50.0; // 控制按钮高度
              const spacing = 20.0; // 间距
              
              // 计算棋盘可用的最大尺寸
              final maxBoardSize = availableHeight - (topBarHeight + turnIndicatorHeight + specialMoveHeight + controlButtonsHeight + spacing * 4);
              final boardSize = min(
                min(maxBoardSize, availableWidth * 0.9),
                availableHeight * 0.7,
              );

              return SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: topBarHeight),
                      Text(
                        '当前回合: ${state.currentPlayer == PieceColor.white ? "白方" : "黑方"}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: spacing),
                      Container(
                        height: specialMoveHeight,
                        alignment: Alignment.center,
                        child: _buildSpecialMoveIndicator(state),
                      ),
                      const SizedBox(height: spacing),
                      Container(
                        height: controlButtonsHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: state.undoStates.isEmpty ? null : () {
                                context.read<ChessBloc>().add(const UndoMove());
                              },
                              icon: const Icon(Icons.undo),
                              label: const Text('前一步'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[100],
                                foregroundColor: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              onPressed: state.redoStates.isEmpty ? null : () {
                                context.read<ChessBloc>().add(const RedoMove());
                              },
                              icon: const Icon(Icons.redo),
                              label: const Text('后一步'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[100],
                                foregroundColor: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.read<ChessBloc>().add(ToggleHintMode());
                              },
                              icon: Icon(state.hintMode ? Icons.lightbulb : Icons.lightbulb_outline),
                              label: Text(state.hintMode ? '关闭提示' : '开启提示'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: state.hintMode ? Colors.yellow[100] : Colors.grey[100],
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: spacing),
                      SizedBox(
                        width: boardSize + 30, // 增加宽度以容纳行号
                        height: boardSize + 30, // 增加高度以容纳列号
                        child: Column(
                          children: [
                            // 列标记 (A-H)
                            SizedBox(
                              height: 30,
                              child: Row(
                                children: [
                                  const SizedBox(width: 30), // 左上角空白
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
                            ),
                            // 棋盘和行号
                            Expanded(
                              child: Row(
                                children: [
                                  // 行号 (8-1)
                                  SizedBox(
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
                                  ),
                                  // 棋盘
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.black, width: 2.0),
                                      ),
                                      child: GridView.builder(
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 8,
                                        ),
                                        itemCount: 64,
                                        itemBuilder: (context, index) {
                                          final row = index ~/ 8;
                                          final col = index % 8;
                                          final isDark = (row + col) % 2 == 1;
                                          final isSelected = state.selectedPosition?.row == row && 
                                                         state.selectedPosition?.col == col;
                                          final isValidMove = state.validMoves.any(
                                            (pos) => pos.row == row && pos.col == col
                                          );
                                          final isMovablePiece = state.board[row][col]?.color == state.currentPlayer &&
                                            ChessRules.getValidMoves(
                                              state.board,
                                              Position(row: row, col: col),
                                              hasKingMoved: state.hasKingMoved,
                                              hasRookMoved: state.hasRookMoved,
                                              lastPawnDoubleMoved: state.lastPawnDoubleMoved[state.board[row][col]?.color == PieceColor.white ? PieceColor.black : PieceColor.white],
                                              lastPawnDoubleMovedNumber: state.lastPawnDoubleMovedNumber[state.board[row][col]?.color == PieceColor.white ? PieceColor.black : PieceColor.white],
                                              currentMoveNumber: state.currentMoveNumber,
                                            ).isNotEmpty;

                                          return GestureDetector(
                                            onTap: () => _handleTap(context, row, col, state),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Container(
                                                  color: isDark ? Colors.brown[300] : Colors.brown[100],
                                                ),
                                                if (state.board[row][col] != null)
                                                  Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Image.asset(
                                                      _getPieceImage(state.board[row][col]!),
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                                if (state.hintMode && isValidMove)
                                                  Center(
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
                                                  ),
                                                if (isSelected || (state.hintMode && (state.isCheck ? isMovablePiece : !isMovablePiece)))
                                                  Container(
                                                    color: isSelected
                                                        ? Colors.blue.withOpacity(0.3)
                                                        : Colors.grey.withOpacity(0.5),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSpecialMoveIndicator(GameState state) {
    if (state.lastMove == null) {
      return const SizedBox(height: 50);  // 保持固定高度，避免布局跳动
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.lastMove?.piece != null) ...[
            Image.asset(
              _getPieceImage(state.lastMove!.piece),
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 8),
          ],
          if (state.lastMove!.isPromotion && state.lastMove!.promotionType != null) ...[
            Text(
              '${state.lastMove!.piece.color == PieceColor.white ? "白方" : "黑方"}兵从${_getPositionName(state.lastMove!.from)}升变为',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Image.asset(
              _getPieceImage(ChessPiece(
                type: state.lastMove!.promotionType!,
                color: state.lastMove!.piece.color,
              )),
              width: 32,
              height: 32,
            ),
            const SizedBox(width: 8),
            Text(
              '到${_getPositionName(state.lastMove!.to)}',
              style: const TextStyle(fontSize: 16),
            ),
          ] else if (state.specialMoveMessage != null || state.lastMove != null) ...[
            Text(
              state.specialMoveMessage ?? _buildDefaultMoveMessage(state.lastMove!),
              style: const TextStyle(fontSize: 16),
            ),
          ],
          if (state.lastMove?.capturedPiece != null && !state.lastMove!.isPromotion) ...[
            const SizedBox(width: 8),
            Image.asset(
              _getPieceImage(state.lastMove!.capturedPiece!),
              width: 32,
              height: 32,
            ),
          ],
        ],
      ),
    );
  }

  String _buildDefaultMoveMessage(ChessMove move) {
    final pieceColor = move.piece.color == PieceColor.white ? "白方" : "黑方";
    final pieceType = _getPieceTypeName(move.piece.type);
    final from = _getPositionName(move.from);
    final to = _getPositionName(move.to);

    if (move.capturedPiece != null) {
      final capturedColor = move.capturedPiece!.color == PieceColor.white ? "白方" : "黑方";
      final capturedType = _getPieceTypeName(move.capturedPiece!.type);
      return '$pieceColor$pieceType($from)吃掉$capturedColor$capturedType($to)';
    } else {
      return '$pieceColor$pieceType从$from移动到$to';
    }
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

  String _getPositionName(Position position) {
    final col = String.fromCharCode('A'.codeUnitAt(0) + position.col);
    final row = 8 - position.row;
    return '$col$row';
  }

  void _handleTap(BuildContext context, int row, int col, GameState state) {
    final bloc = context.read<ChessBloc>();

    if (state.selectedPosition != null) {
      // 如果已经选中了棋子，尝试移动
      if (state.validMoves.any((pos) => pos.row == row && pos.col == col)) {
        final from = state.selectedPosition!;
        final to = Position(row: row, col: col);
        final piece = state.board[from.row][from.col]!;

        // 检查是否需要升变
        if (piece.type == PieceType.pawn && (row == 0 || row == 7)) {
          bloc.add(MovePiece(from, to));
          showPromotionDialog(context, to);
        } else {
          bloc.add(MovePiece(from, to));
        }
      } else {
        // 选中新的棋子
        bloc.add(SelectPiece(Position(row: row, col: col)));
      }
    } else {
      // 选中新的棋子
      bloc.add(SelectPiece(Position(row: row, col: col)));
    }
  }

  String _getPieceImage(ChessPiece piece) {
    final color = piece.color == PieceColor.white ? 'white' : 'black';
    final type = piece.type.toString().split('.').last;
    return 'assets/images/${color}_$type.png';
  }

  String _getGameModeTitle() {
    switch (gameMode) {
      case GameMode.offline:
        return '单机对战';
      case GameMode.online:
        return '联网对战';
      case GameMode.faceToFace:
        return '面对面对战';
    }
  }
}

Future<void> showPromotionDialog(
    BuildContext context, Position position) async {
  final bloc = context.read<ChessBloc>();
  final promotedPiece = await showDialog<PieceType>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
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
                    _buildPromotionOption(context, PieceType.queen),
                    const SizedBox(width: 8),
                    _buildPromotionOption(context, PieceType.rook),
                    const SizedBox(width: 8),
                    _buildPromotionOption(context, PieceType.bishop),
                    const SizedBox(width: 8),
                    _buildPromotionOption(context, PieceType.knight),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (promotedPiece != null) {
    bloc.add(PromotePawn(position, promotedPiece));
  }
}

Widget _buildPromotionOption(BuildContext context, PieceType type) {
  return GestureDetector(
    onTap: () => Navigator.of(context).pop(type),
    child: Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Image.asset(
        'assets/images/white_${type.toString().split('.').last}.png',
        fit: BoxFit.contain,
      ),
    ),
  );
}
