import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math';

import '../blocs/chess_bloc.dart';
import '../blocs/chess_event.dart';
import '../models/chess_models.dart';
import '../screens/game_screen.dart';

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
              const spacing = 20.0; // 间距
              
              // 计算棋盘可用的最大尺寸
              final maxBoardSize = availableHeight - (topBarHeight + turnIndicatorHeight + specialMoveHeight + spacing * 3);
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
                      SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
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

                              return GestureDetector(
                                onTap: () => _handleTap(context, row, col, state),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Container(
                                      color: isSelected 
                                          ? Colors.blue.withOpacity(0.5)
                                          : isDark 
                                              ? Colors.brown[300] 
                                              : Colors.brown[100],
                                    ),
                                    if (state.board[row][col] != null)
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.asset(
                                          _getPieceImage(state.board[row][col]!),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    if (isValidMove)
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSpecialMoveIndicator(GameState state) {
    if (state.lastMove == null || state.specialMoveMessage == null) {
      return const SizedBox(height: 50);
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
          Image.asset(
            _getPieceImage(state.lastMove!.piece),
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 8),
          Text(
            state.specialMoveMessage ?? '',
            style: const TextStyle(fontSize: 16),
          ),
          if (state.lastMove!.capturedPiece != null) ...[
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
