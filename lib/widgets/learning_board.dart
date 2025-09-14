import 'package:flutter/material.dart';
import '../models/chess_models.dart';

class LearningBoard extends StatefulWidget {
  final List<List<ChessPiece?>>? boardState;
  final List<Position> highlightedPositions;
  final Function(Position from, Position to)? onMove;
  final bool isInteractive;

  const LearningBoard({
    Key? key,
    this.boardState,
    this.highlightedPositions = const [],
    this.onMove,
    this.isInteractive = true,
  }) : super(key: key);

  @override
  State<LearningBoard> createState() => _LearningBoardState();
}

class _LearningBoardState extends State<LearningBoard> {
  Position? selectedPosition;
  List<Position> validMoves = [];

  @override
  Widget build(BuildContext context) {
    if (widget.boardState == null) {
      return const Center(
        child: Text('棋盘加载中...'),
      );
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.brown[800]!, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: List.generate(8, (row) {
            return Expanded(
              child: Row(
                children: List.generate(8, (col) {
                  return Expanded(
                    child: _buildSquare(row, col),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSquare(int row, int col) {
    final position = Position(row: row, col: col);
    final piece = widget.boardState![row][col];
    final isLight = (row + col) % 2 == 0;
    final isHighlighted = widget.highlightedPositions.contains(position);
    final isSelected = selectedPosition == position;
    final isValidMove = validMoves.contains(position);

    return GestureDetector(
      onTap: widget.isInteractive ? () => _handleTap(row, col) : null,
      child: Container(
        decoration: BoxDecoration(
          color: _getSquareColor(isLight, isHighlighted, isSelected, isValidMove),
          border: isHighlighted 
              ? Border.all(color: Colors.yellow, width: 3)
              : null,
        ),
        child: Stack(
          children: [
            // 棋盘坐标标记
            if (col == 0) _buildRankLabel(row),
            if (row == 7) _buildFileLabel(col),
            
            // 棋子
            if (piece != null)
              Center(
                child: _buildPiece(piece),
              ),
            
            // 移动提示点
            if (isValidMove && piece == null)
              const Center(
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.green,
                ),
              ),
            
            // 可吃子提示
            if (isValidMove && piece != null)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getSquareColor(bool isLight, bool isHighlighted, bool isSelected, bool isValidMove) {
    if (isSelected) {
      return Colors.blue[300]!;
    }
    if (isHighlighted) {
      return isLight ? Colors.yellow[200]! : Colors.yellow[400]!;
    }
    if (isValidMove) {
      return isLight ? Colors.green[100]! : Colors.green[200]!;
    }
    return isLight ? Colors.grey[200]! : Colors.brown[400]!;
  }

  Widget _buildPiece(ChessPiece piece) {
    final pieceSymbols = {
      PieceType.king: piece.color == PieceColor.white ? '♔' : '♚',
      PieceType.queen: piece.color == PieceColor.white ? '♕' : '♛',
      PieceType.rook: piece.color == PieceColor.white ? '♖' : '♜',
      PieceType.bishop: piece.color == PieceColor.white ? '♗' : '♝',
      PieceType.knight: piece.color == PieceColor.white ? '♘' : '♞',
      PieceType.pawn: piece.color == PieceColor.white ? '♙' : '♟',
    };

    return Text(
      pieceSymbols[piece.type] ?? '',
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRankLabel(int row) {
    return Positioned(
      left: 2,
      top: 2,
      child: Text(
        '${8 - row}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: (row) % 2 == 0 ? Colors.brown[800] : Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildFileLabel(int col) {
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    return Positioned(
      right: 2,
      bottom: 2,
      child: Text(
        files[col],
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: col % 2 == 1 ? Colors.brown[800] : Colors.grey[200],
        ),
      ),
    );
  }

  void _handleTap(int row, int col) {
    final position = Position(row: row, col: col);
    final piece = widget.boardState![row][col];

    if (selectedPosition == null) {
      // 选择棋子
      if (piece != null) {
        setState(() {
          selectedPosition = position;
          validMoves = _getValidMoves(position);
        });
      }
    } else {
      // 执行移动或重新选择
      if (validMoves.contains(position)) {
        // 执行移动
        widget.onMove?.call(selectedPosition!, position);
        setState(() {
          selectedPosition = null;
          validMoves = [];
        });
      } else if (piece != null) {
        // 重新选择棋子
        setState(() {
          selectedPosition = position;
          validMoves = _getValidMoves(position);
        });
      } else {
        // 取消选择
        setState(() {
          selectedPosition = null;
          validMoves = [];
        });
      }
    }
  }

  List<Position> _getValidMoves(Position position) {
    // 简化的移动计算，实际应该使用 ChessRules
    final piece = widget.boardState![position.row][position.col];
    if (piece == null) return [];

    final moves = <Position>[];
    
    // 这里应该实现具体的移动规则
    // 为了简化，我们只返回一些基本的移动
    switch (piece.type) {
      case PieceType.pawn:
        _addPawnMoves(position, piece.color, moves);
        break;
      case PieceType.rook:
        _addRookMoves(position, moves);
        break;
      case PieceType.knight:
        _addKnightMoves(position, moves);
        break;
      case PieceType.bishop:
        _addBishopMoves(position, moves);
        break;
      case PieceType.queen:
        _addQueenMoves(position, moves);
        break;
      case PieceType.king:
        _addKingMoves(position, moves);
        break;
    }

    return moves;
  }

  void _addPawnMoves(Position position, PieceColor color, List<Position> moves) {
    final direction = color == PieceColor.white ? -1 : 1;
    final startRow = color == PieceColor.white ? 6 : 1;
    
    // 向前一格
    final oneStep = Position(row: position.row + direction, col: position.col);
    if (_isValidPosition(oneStep) && widget.boardState![oneStep.row][oneStep.col] == null) {
      moves.add(oneStep);
      
      // 向前两格（首次移动）
      if (position.row == startRow) {
        final twoStep = Position(row: position.row + 2 * direction, col: position.col);
        if (_isValidPosition(twoStep) && widget.boardState![twoStep.row][twoStep.col] == null) {
          moves.add(twoStep);
        }
      }
    }
    
    // 斜向攻击
    for (final colOffset in [-1, 1]) {
      final attackPos = Position(row: position.row + direction, col: position.col + colOffset);
      if (_isValidPosition(attackPos)) {
        final targetPiece = widget.boardState![attackPos.row][attackPos.col];
        if (targetPiece != null && targetPiece.color != color) {
          moves.add(attackPos);
        }
      }
    }
  }

  void _addRookMoves(Position position, List<Position> moves) {
    final directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1], // 上下左右
    ];
    
    for (final direction in directions) {
      for (int i = 1; i < 8; i++) {
        final newPos = Position(
          row: position.row + direction[0] * i,
          col: position.col + direction[1] * i,
        );
        
        if (!_isValidPosition(newPos)) break;
        
        final targetPiece = widget.boardState![newPos.row][newPos.col];
        if (targetPiece == null) {
          moves.add(newPos);
        } else {
          if (targetPiece.color != widget.boardState![position.row][position.col]!.color) {
            moves.add(newPos);
          }
          break;
        }
      }
    }
  }

  void _addKnightMoves(Position position, List<Position> moves) {
    final knightMoves = [
      [-2, -1], [-2, 1], [-1, -2], [-1, 2],
      [1, -2], [1, 2], [2, -1], [2, 1],
    ];
    
    for (final move in knightMoves) {
      final newPos = Position(
        row: position.row + move[0],
        col: position.col + move[1],
      );
      
      if (_isValidPosition(newPos)) {
        final targetPiece = widget.boardState![newPos.row][newPos.col];
        if (targetPiece == null || 
            targetPiece.color != widget.boardState![position.row][position.col]!.color) {
          moves.add(newPos);
        }
      }
    }
  }

  void _addBishopMoves(Position position, List<Position> moves) {
    final directions = [
      [-1, -1], [-1, 1], [1, -1], [1, 1], // 对角线
    ];
    
    for (final direction in directions) {
      for (int i = 1; i < 8; i++) {
        final newPos = Position(
          row: position.row + direction[0] * i,
          col: position.col + direction[1] * i,
        );
        
        if (!_isValidPosition(newPos)) break;
        
        final targetPiece = widget.boardState![newPos.row][newPos.col];
        if (targetPiece == null) {
          moves.add(newPos);
        } else {
          if (targetPiece.color != widget.boardState![position.row][position.col]!.color) {
            moves.add(newPos);
          }
          break;
        }
      }
    }
  }

  void _addQueenMoves(Position position, List<Position> moves) {
    _addRookMoves(position, moves);
    _addBishopMoves(position, moves);
  }

  void _addKingMoves(Position position, List<Position> moves) {
    final kingMoves = [
      [-1, -1], [-1, 0], [-1, 1],
      [0, -1],           [0, 1],
      [1, -1],  [1, 0],  [1, 1],
    ];
    
    for (final move in kingMoves) {
      final newPos = Position(
        row: position.row + move[0],
        col: position.col + move[1],
      );
      
      if (_isValidPosition(newPos)) {
        final targetPiece = widget.boardState![newPos.row][newPos.col];
        if (targetPiece == null || 
            targetPiece.color != widget.boardState![position.row][position.col]!.color) {
          moves.add(newPos);
        }
      }
    }
  }

  bool _isValidPosition(Position position) {
    return position.row >= 0 && position.row < 8 && 
           position.col >= 0 && position.col < 8;
  }
}
