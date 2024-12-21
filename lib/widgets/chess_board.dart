import 'package:flutter/material.dart';
import '../screens/game_screen.dart';
import '../utils/chess_rules.dart';

class ChessBoard extends StatefulWidget {
  final GameMode gameMode;

  const ChessBoard({
    super.key,
    required this.gameMode,
  });

  @override
  State<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends State<ChessBoard> {
  static const int BOARD_SIZE = 8;
  
  // 棋盘状态
  List<List<ChessPiece?>> board = List.generate(
    BOARD_SIZE,
    (i) => List.generate(BOARD_SIZE, (j) => null),
  );

  // 当前选中的棋子位置
  Position? selectedPosition;
  
  // 当前玩家
  PieceColor currentPlayer = PieceColor.white;

  // 可移动位置
  List<Position> validMoves = [];

  // 记录王和车是否移动过（用于王车易位）
  Map<PieceColor, bool> hasKingMoved = {
    PieceColor.white: false,
    PieceColor.black: false,
  };
  Map<PieceColor, Map<String, bool>> hasRookMoved = {
    PieceColor.white: {'kingside': false, 'queenside': false},
    PieceColor.black: {'kingside': false, 'queenside': false},
  };

  // 记录最后一次移动的兵（用于吃过路兵）
  Position? lastPawnDoubleMoved;
  int lastMoveNumber = 0;
  int currentMoveNumber = 0;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    // 初始化白方棋子
    board[7][0] = ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[7][1] = ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[7][2] = ChessPiece(type: PieceType.bishop, color: PieceColor.white);
    board[7][3] = ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[7][4] = ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[7][5] = ChessPiece(type: PieceType.bishop, color: PieceColor.white);
    board[7][6] = ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[7][7] = ChessPiece(type: PieceType.rook, color: PieceColor.white);
    for (int i = 0; i < BOARD_SIZE; i++) {
      board[6][i] = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    }

    // 初始化黑方棋子
    board[0][0] = ChessPiece(type: PieceType.rook, color: PieceColor.black);
    board[0][1] = ChessPiece(type: PieceType.knight, color: PieceColor.black);
    board[0][2] = ChessPiece(type: PieceType.bishop, color: PieceColor.black);
    board[0][3] = ChessPiece(type: PieceType.queen, color: PieceColor.black);
    board[0][4] = ChessPiece(type: PieceType.king, color: PieceColor.black);
    board[0][5] = ChessPiece(type: PieceType.bishop, color: PieceColor.black);
    board[0][6] = ChessPiece(type: PieceType.knight, color: PieceColor.black);
    board[0][7] = ChessPiece(type: PieceType.rook, color: PieceColor.black);
    for (int i = 0; i < BOARD_SIZE; i++) {
      board[1][i] = ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getGameModeTitle()),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '当前回合: ${currentPlayer == PieceColor.white ? "白方" : "黑方"}',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 20),
          Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                ),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: BOARD_SIZE,
                  ),
                  itemCount: BOARD_SIZE * BOARD_SIZE,
                  itemBuilder: (context, index) {
                    final row = index ~/ BOARD_SIZE;
                    final col = index % BOARD_SIZE;
                    final isDark = (row + col) % 2 == 1;
                    final isSelected = selectedPosition?.row == row && 
                                     selectedPosition?.col == col;
                    final isValidMove = validMoves.any(
                      (pos) => pos.row == row && pos.col == col
                    );

                    return GestureDetector(
                      onTap: () => _handleTap(row, col),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 背景
                          Container(
                            color: isSelected 
                                ? Colors.blue.withOpacity(0.5)
                                : isDark 
                                    ? Colors.brown[300] 
                                    : Colors.brown[100],
                          ),
                          // 棋子
                          if (board[row][col] != null)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                _getPieceImage(board[row][col]!),
                                fit: BoxFit.contain,
                              ),
                            ),
                          // 可移动位置指示器
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
          ),
        ],
      ),
    );
  }

  String _getPieceImage(ChessPiece piece) {
    final color = piece.color == PieceColor.white ? 'white' : 'black';
    final type = piece.type.toString().split('.').last;
    return 'assets/images/${color}_$type.png';
  }

  void _handleTap(int row, int col) {
    setState(() {
      if (selectedPosition != null) {
        // 如果已经选中了棋子，尝试移动
        if (validMoves.any((pos) => pos.row == row && pos.col == col)) {
          _movePiece(selectedPosition!, Position(row: row, col: col));
          selectedPosition = null;
          validMoves = [];
        } else {
          // 选中新的棋子
          _selectPiece(row, col);
        }
      } else {
        // 选中新的棋子
        _selectPiece(row, col);
      }
    });
  }

  void _selectPiece(int row, int col) {
    final piece = board[row][col];
    if (piece != null && piece.color == currentPlayer) {
      selectedPosition = Position(row: row, col: col);
      validMoves = _getValidMoves(row, col);
    } else {
      selectedPosition = null;
      validMoves = [];
    }
  }

  void _movePiece(Position from, Position to) {
    final movingPiece = board[from.row][from.col]!;
    final isCapture = board[to.row][to.col] != null;

    // 处理王车易位
    if (movingPiece.type == PieceType.king) {
      _handleCastling(from, to);
      hasKingMoved[movingPiece.color] = true;
    } else if (movingPiece.type == PieceType.rook) {
      if (from.col == 0) { // 后翼车
        hasRookMoved[movingPiece.color]!['queenside'] = true;
      } else if (from.col == 7) { // 前翼车
        hasRookMoved[movingPiece.color]!['kingside'] = true;
      }
    }

    // 处理吃过路兵
    if (movingPiece.type == PieceType.pawn) {
      // 记录双步移动的兵
      if ((from.row - to.row).abs() == 2) {
        lastPawnDoubleMoved = to;
        lastMoveNumber = currentMoveNumber;
      }
      
      // 处理吃过路兵
      if (lastPawnDoubleMoved != null && 
          !isCapture && 
          from.col != to.col) {
        // 移除被吃的过路兵
        board[lastPawnDoubleMoved!.row][lastPawnDoubleMoved!.col] = null;
      }

      // 处理兵的升变
      if (to.row == 0 || to.row == 7) {
        // 先移动兵到目标位置
        board[to.row][to.col] = board[from.row][from.col];
        board[from.row][from.col] = null;
        _showPromotionDialog(to);
        return;
      }
    }

    // 执行常规移动
    board[to.row][to.col] = board[from.row][from.col];
    board[from.row][from.col] = null;

    // 更新游戏状态
    currentMoveNumber++;
    currentPlayer = currentPlayer == PieceColor.white 
        ? PieceColor.black 
        : PieceColor.white;
  }

  void _handleCastling(Position from, Position to) {
    // 王车易位
    if ((from.col - to.col).abs() == 2) {
      final isKingside = to.col > from.col;
      final rookFromCol = isKingside ? 7 : 0;
      final rookToCol = isKingside ? 5 : 3;
      
      // 移动车
      board[from.row][rookToCol] = board[from.row][rookFromCol];
      board[from.row][rookFromCol] = null;
    }
  }

  Future<void> _showPromotionDialog(Position pawnPosition) async {
    final piece = board[pawnPosition.row][pawnPosition.col]!;
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
                      _buildPromotionOption(PieceType.queen, piece.color),
                      const SizedBox(width: 8),
                      _buildPromotionOption(PieceType.rook, piece.color),
                      const SizedBox(width: 8),
                      _buildPromotionOption(PieceType.bishop, piece.color),
                      const SizedBox(width: 8),
                      _buildPromotionOption(PieceType.knight, piece.color),
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
      setState(() {
        // 保持原来的颜色
        board[pawnPosition.row][pawnPosition.col] = ChessPiece(
          type: promotedPiece,
          color: piece.color,
        );
        // 更新游戏状态
        currentMoveNumber++;
        currentPlayer = currentPlayer == PieceColor.white 
            ? PieceColor.black 
            : PieceColor.white;
      });
    }
  }

  Widget _buildPromotionOption(PieceType type, PieceColor color) {
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
          _getPieceImage(ChessPiece(type: type, color: color)),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  List<Position> _getValidMoves(int row, int col) {
    return ChessRules.getValidMoves(
      board,
      Position(row: row, col: col),
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      lastPawnDoubleMoved: lastPawnDoubleMoved,
      lastMoveNumber: lastMoveNumber,
      currentMoveNumber: currentMoveNumber,
    );
  }

  String _getGameModeTitle() {
    switch (widget.gameMode) {
      case GameMode.offline:
        return '单机对战';
      case GameMode.online:
        return '联网对战';
      case GameMode.faceToFace:
        return '面对面对战';
    }
  }
}

class ChessPiece {
  final PieceType type;
  final PieceColor color;

  ChessPiece({
    required this.type,
    required this.color,
  });
}

enum PieceType {
  king,
  queen,
  bishop,
  knight,
  rook,
  pawn,
}

enum PieceColor {
  white,
  black,
}

class Position {
  final int row;
  final int col;

  Position({
    required this.row,
    required this.col,
  });
} 