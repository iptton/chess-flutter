import 'package:flutter/material.dart';
import '../models/chess_models.dart';
import '../models/learning_models.dart';

class EnhancedLearningBoard extends StatefulWidget {
  final List<List<ChessPiece?>> boardState;
  final LearningStep? currentStep;
  final Function(Position from, Position to)? onMove;
  final bool isInteractive;
  final bool showFeedback;
  final List<Position> highlightedPositions;

  const EnhancedLearningBoard({
    Key? key,
    required this.boardState,
    this.currentStep,
    this.onMove,
    this.isInteractive = true,
    this.showFeedback = true,
    this.highlightedPositions = const [],
  }) : super(key: key);

  @override
  State<EnhancedLearningBoard> createState() => _EnhancedLearningBoardState();
}

class _EnhancedLearningBoardState extends State<EnhancedLearningBoard>
    with TickerProviderStateMixin {
  Position? selectedPosition;
  List<Position> validMoves = [];
  String? feedbackMessage;
  bool? isCorrectMove;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _feedbackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        
        if (isWideScreen) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      key: const Key('desktop_layout'),
      child: Column(
        children: [
          if (widget.showFeedback && feedbackMessage != null)
            _buildFeedbackPanel(),
          Expanded(
            child: _buildChessBoard(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      key: const Key('mobile_layout'),
      child: Column(
        children: [
          if (widget.showFeedback && feedbackMessage != null)
            _buildCompactFeedbackPanel(),
          Expanded(
            child: _buildChessBoard(),
          ),
        ],
      ),
    );
  }

  Widget _buildChessBoard() {
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
    final piece = widget.boardState[row][col];
    final isLight = (row + col) % 2 == 0;
    final isSelected = selectedPosition == position;
    final isHighlighted = widget.highlightedPositions.contains(position);
    final isValidMove = validMoves.contains(position);

    return GestureDetector(
      key: Key('square_${row}_$col'),
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

  Widget _buildFeedbackPanel() {
    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _feedbackAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCorrectMove == true ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCorrectMove == true ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isCorrectMove == true ? Icons.check_circle : Icons.error,
                  color: isCorrectMove == true ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feedbackMessage!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isCorrectMove == true ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactFeedbackPanel() {
    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _feedbackAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCorrectMove == true ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCorrectMove == true ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCorrectMove == true ? Icons.check_circle : Icons.error,
                  color: isCorrectMove == true ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    feedbackMessage!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCorrectMove == true ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleTap(int row, int col) {
    final position = Position(row: row, col: col);
    final piece = widget.boardState[row][col];

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
        final move = ChessMove(
          from: selectedPosition!,
          to: position,
          piece: widget.boardState[selectedPosition!.row][selectedPosition!.col]!,
        );
        
        _checkMoveCorrectness(move);
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

  void _checkMoveCorrectness(ChessMove move) {
    if (widget.currentStep?.requiredMoves != null) {
      final isCorrect = widget.currentStep!.requiredMoves!.any((requiredMove) =>
          requiredMove.from.row == move.from.row &&
          requiredMove.from.col == move.from.col &&
          requiredMove.to.row == move.to.row &&
          requiredMove.to.col == move.to.col);
      
      setState(() {
        isCorrectMove = isCorrect;
        feedbackMessage = isCorrect 
            ? (widget.currentStep?.successMessage ?? '正确！')
            : (widget.currentStep?.failureMessage ?? '错误，请再试一次');
      });
      
      _feedbackController.forward().then((_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              feedbackMessage = null;
              isCorrectMove = null;
            });
            _feedbackController.reset();
          }
        });
      });
    }
  }

  // Helper methods (simplified for brevity)
  Color _getSquareColor(bool isLight, bool isHighlighted, bool isSelected, bool isValidMove) {
    if (isSelected) return Colors.blue[300]!;
    if (isValidMove) return Colors.green[200]!;
    if (isHighlighted) return Colors.yellow[200]!;
    return isLight ? Colors.brown[100]! : Colors.brown[400]!;
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
      pieceSymbols[piece.type]!,
      style: const TextStyle(fontSize: 32),
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
          color: Colors.brown[800],
        ),
      ),
    );
  }

  Widget _buildFileLabel(int col) {
    return Positioned(
      right: 2,
      bottom: 2,
      child: Text(
        String.fromCharCode(97 + col), // a-h
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.brown[800],
        ),
      ),
    );
  }

  List<Position> _getValidMoves(Position position) {
    // Simplified valid moves calculation for demo
    // In a real implementation, this would use proper chess rules
    final moves = <Position>[];
    final piece = widget.boardState[position.row][position.col];
    
    if (piece?.type == PieceType.pawn) {
      // Simple pawn moves
      if (piece!.color == PieceColor.white && position.row > 0) {
        moves.add(Position(row: position.row - 1, col: position.col));
        if (position.row == 6) {
          moves.add(Position(row: position.row - 2, col: position.col));
        }
      }
    }
    
    return moves;
  }
}
