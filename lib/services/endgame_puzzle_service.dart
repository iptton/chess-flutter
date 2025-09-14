import '../models/learning_models.dart';
import '../models/chess_models.dart';
import '../data/learning_lessons.dart';
import '../data/classic_endgame_puzzles.dart';

class EndgamePuzzleService {
  static final EndgamePuzzleService _instance =
      EndgamePuzzleService._internal();
  factory EndgamePuzzleService() => _instance;
  EndgamePuzzleService._internal();

  // Cache for puzzles
  List<EndgamePuzzle>? _cachedPuzzles;

  // User progress tracking
  final Map<String, _PuzzleAttempt> _userAttempts = {};
  final Set<String> _completedPuzzles = {};

  /// 获取残局谜题
  Future<List<EndgamePuzzle>> getEndgamePuzzles() async {
    if (_cachedPuzzles != null) {
      return _cachedPuzzles!;
    }

    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 1000));

    _cachedPuzzles = _generateEndgamePuzzles();
    return _cachedPuzzles!;
  }

  /// 获取缓存的谜题
  Future<List<EndgamePuzzle>?> getCachedPuzzles() async {
    return _cachedPuzzles;
  }

  /// 集成到学习模式
  Future<void> integrateIntoLearningMode() async {
    final puzzles = await getEndgamePuzzles();

    // 将谜题转换为学习步骤并添加到残局课程
    final puzzleSteps =
        puzzles.map((puzzle) => _convertPuzzleToStep(puzzle)).toList();

    // 添加谜题步骤到学习课程
    LearningLessons.addPuzzleSteps(puzzleSteps);
  }

  /// 标记谜题完成
  Future<void> markPuzzleCompleted(
      String puzzleId, bool successful, int attempts) async {
    _userAttempts[puzzleId] = _PuzzleAttempt(
      puzzleId: puzzleId,
      successful: successful,
      attempts: attempts,
      timestamp: DateTime.now(),
    );

    if (successful) {
      _completedPuzzles.add(puzzleId);
    }
  }

  /// 获取用户进度
  Future<UserPuzzleProgress> getUserProgress() async {
    final totalAttempts = _userAttempts.values
        .map((attempt) => attempt.attempts)
        .fold(0, (sum, attempts) => sum + attempts);

    final successfulSolutions = _completedPuzzles.length;

    final averageAttempts =
        _userAttempts.isEmpty ? 0.0 : totalAttempts / _userAttempts.length;

    final puzzles = await getEndgamePuzzles();
    final difficultyProgress = <PuzzleDifficulty, int>{};

    for (final difficulty in PuzzleDifficulty.values) {
      difficultyProgress[difficulty] = _completedPuzzles
          .where((id) =>
              puzzles.firstWhere((p) => p.id == id).difficulty == difficulty)
          .length;
    }

    return UserPuzzleProgress(
      completedPuzzles: _completedPuzzles.toList(),
      totalAttempts: totalAttempts,
      successfulSolutions: successfulSolutions,
      averageAttempts: averageAttempts,
      difficultyProgress: difficultyProgress,
    );
  }

  /// 获取下一个推荐谜题
  Future<EndgamePuzzle?> getNextRecommendedPuzzle() async {
    final puzzles = await getEndgamePuzzles();
    final progress = await getUserProgress();

    // 根据用户表现推荐下一个谜题
    if (progress.completedPuzzles.length < 3) {
      // 新手推荐初级谜题
      return puzzles.firstWhere(
        (p) =>
            p.difficulty == PuzzleDifficulty.beginner &&
            !_completedPuzzles.contains(p.id),
        orElse: () => puzzles.first,
      );
    } else if (progress.successfulSolutions / progress.totalAttempts > 0.7) {
      // 表现好的用户推荐更难的谜题
      return puzzles.firstWhere(
        (p) =>
            p.difficulty == PuzzleDifficulty.advanced &&
            !_completedPuzzles.contains(p.id),
        orElse: () => puzzles.firstWhere(
          (p) =>
              p.difficulty == PuzzleDifficulty.intermediate &&
              !_completedPuzzles.contains(p.id),
          orElse: () => puzzles.first,
        ),
      );
    } else {
      // 表现一般的用户推荐中级谜题
      return puzzles.firstWhere(
        (p) =>
            p.difficulty == PuzzleDifficulty.intermediate &&
            !_completedPuzzles.contains(p.id),
        orElse: () => puzzles.first,
      );
    }
  }

  /// 获取谜题统计
  Future<PuzzleStatistics> getPuzzleStatistics() async {
    final puzzles = await getEndgamePuzzles();
    final totalAttempted = _userAttempts.length;
    final totalSolved =
        _userAttempts.values.where((attempt) => attempt.successful).length;
    final successRate =
        totalAttempted == 0 ? 0.0 : totalSolved / totalAttempted;

    final totalAttempts = _userAttempts.values
        .map((attempt) => attempt.attempts)
        .fold(0, (sum, attempts) => sum + attempts);
    final averageAttempts =
        totalAttempted == 0 ? 0.0 : totalAttempts / totalAttempted;

    final difficultyBreakdown = <PuzzleDifficulty, int>{};
    final endgameTypeBreakdown = <EndgameType, int>{};

    for (final difficulty in PuzzleDifficulty.values) {
      difficultyBreakdown[difficulty] = _completedPuzzles
          .where((id) =>
              puzzles.firstWhere((p) => p.id == id).difficulty == difficulty)
          .length;
    }

    for (final type in EndgameType.values) {
      endgameTypeBreakdown[type] = _completedPuzzles
          .where(
              (id) => puzzles.firstWhere((p) => p.id == id).endgameType == type)
          .length;
    }

    return PuzzleStatistics(
      totalPuzzlesAttempted: totalAttempted,
      totalPuzzlesSolved: totalSolved,
      successRate: successRate,
      averageAttemptsPerPuzzle: averageAttempts,
      difficultyBreakdown: difficultyBreakdown,
      endgameTypeBreakdown: endgameTypeBreakdown,
    );
  }

  // Private helper methods

  List<EndgamePuzzle> _generateEndgamePuzzles() {
    // 使用经典残局谜题数据，完全离线可用
    final classicPuzzles = ClassicEndgamePuzzles.getAllPuzzles();

    // 如果经典谜题不足20个，补充生成的谜题
    final puzzles = <EndgamePuzzle>[...classicPuzzles];

    // 补充到20个谜题 - 避免无限循环
    int generatedCount = 0;
    while (puzzles.length < 20 && generatedCount < 20) {
      puzzles.add(_createBeginnerPuzzle(puzzles.length + 1));
      generatedCount++;
    }

    // 按难度排序
    puzzles.sort((a, b) => a.difficulty.index.compareTo(b.difficulty.index));

    return puzzles.take(20).toList();
  }

  EndgamePuzzle _createBeginnerPuzzle(int index) {
    final endgameTypes = [
      EndgameType.kingPawn,
      EndgameType.pawnEndgame,
      EndgameType.mateIn
    ];
    final type = endgameTypes[index % endgameTypes.length];

    return EndgamePuzzle(
      id: 'puzzle_beginner_$index',
      title: '初级残局 $index',
      description: '这是一个适合初学者的${_getEndgameTypeName(type)}练习',
      difficulty: PuzzleDifficulty.beginner,
      endgameType: type,
      boardState: _createPuzzleBoard(type, PuzzleDifficulty.beginner),
      solution: _createPuzzleSolution(type, PuzzleDifficulty.beginner),
      hints: ['考虑王的位置', '注意兵的推进'],
      evaluation: '这个残局展示了${_getEndgameTypeName(type)}的基本原理',
      source: 'Generated',
      rating: 1200 + index * 10,
    );
  }

  EndgamePuzzle _createIntermediatePuzzle(int index) {
    final endgameTypes = [
      EndgameType.rookEndgame,
      EndgameType.minorPiece,
      EndgameType.kingPawn
    ];
    final type = endgameTypes[index % endgameTypes.length];

    return EndgamePuzzle(
      id: 'puzzle_intermediate_$index',
      title: '中级残局 $index',
      description: '这是一个中等难度的${_getEndgameTypeName(type)}练习',
      difficulty: PuzzleDifficulty.intermediate,
      endgameType: type,
      boardState: _createPuzzleBoard(type, PuzzleDifficulty.intermediate),
      solution: _createPuzzleSolution(type, PuzzleDifficulty.intermediate),
      hints: ['分析棋子的协调', '寻找关键方格', '计算变化'],
      evaluation: '这个残局需要精确的计算和${_getEndgameTypeName(type)}的深入理解',
      source: 'Generated',
      rating: 1500 + index * 15,
    );
  }

  EndgamePuzzle _createAdvancedPuzzle(int index) {
    final endgameTypes = [
      EndgameType.queenEndgame,
      EndgameType.rookEndgame,
      EndgameType.mateIn
    ];
    final type = endgameTypes[index % endgameTypes.length];

    return EndgamePuzzle(
      id: 'puzzle_advanced_$index',
      title: '高级残局 $index',
      description: '这是一个高难度的${_getEndgameTypeName(type)}练习',
      difficulty: PuzzleDifficulty.advanced,
      endgameType: type,
      boardState: _createPuzzleBoard(type, PuzzleDifficulty.advanced),
      solution: _createPuzzleSolution(type, PuzzleDifficulty.advanced),
      hints: [
        '深入分析位置，考虑棋子间的相互作用',
        '考虑所有候选着法，不要遗漏任何可能性',
        '计算到底，确保每一步都是最佳选择',
        '寻找唯一解，这个位置只有一个正确答案'
      ],
      evaluation: '这个复杂的${_getEndgameTypeName(type)}需要大师级的技巧',
      source: 'Generated',
      rating: 1800 + index * 25,
    );
  }

  String _getEndgameTypeName(EndgameType type) {
    switch (type) {
      case EndgameType.kingPawn:
        return '王兵残局';
      case EndgameType.rookEndgame:
        return '车残局';
      case EndgameType.queenEndgame:
        return '后残局';
      case EndgameType.minorPiece:
        return '轻子残局';
      case EndgameType.pawnEndgame:
        return '兵残局';
      case EndgameType.mateIn:
        return '将死题';
    }
  }

  List<List<ChessPiece?>> _createPuzzleBoard(
      EndgameType type, PuzzleDifficulty difficulty) {
    final board = List.generate(
        8, (row) => List.generate(8, (col) => null as ChessPiece?));

    // 基本设置：两个王
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);

    // 根据残局类型添加棋子
    switch (type) {
      case EndgameType.kingPawn:
        board[5][4] =
            const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        break;
      case EndgameType.rookEndgame:
        board[7][0] =
            const ChessPiece(type: PieceType.rook, color: PieceColor.white);
        board[0][0] =
            const ChessPiece(type: PieceType.rook, color: PieceColor.black);
        break;
      case EndgameType.queenEndgame:
        board[7][3] =
            const ChessPiece(type: PieceType.queen, color: PieceColor.white);
        board[0][3] =
            const ChessPiece(type: PieceType.queen, color: PieceColor.black);
        break;
      case EndgameType.minorPiece:
        board[7][2] =
            const ChessPiece(type: PieceType.bishop, color: PieceColor.white);
        board[7][1] =
            const ChessPiece(type: PieceType.knight, color: PieceColor.white);
        break;
      case EndgameType.pawnEndgame:
        board[6][3] =
            const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        board[6][5] =
            const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
        board[1][3] =
            const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
        break;
      case EndgameType.mateIn:
        board[7][3] =
            const ChessPiece(type: PieceType.queen, color: PieceColor.white);
        board[7][0] =
            const ChessPiece(type: PieceType.rook, color: PieceColor.white);
        break;
    }

    return board;
  }

  List<ChessMove> _createPuzzleSolution(
      EndgameType type, PuzzleDifficulty difficulty) {
    // 生成示例解答
    switch (type) {
      case EndgameType.kingPawn:
        return [
          ChessMove(
            from: const Position(row: 7, col: 4),
            to: const Position(row: 6, col: 4),
            piece:
                const ChessPiece(type: PieceType.king, color: PieceColor.white),
          ),
        ];
      case EndgameType.rookEndgame:
        return [
          ChessMove(
            from: const Position(row: 7, col: 0),
            to: const Position(row: 0, col: 0),
            piece:
                const ChessPiece(type: PieceType.rook, color: PieceColor.white),
          ),
        ];
      default:
        return [
          ChessMove(
            from: const Position(row: 7, col: 4),
            to: const Position(row: 6, col: 4),
            piece:
                const ChessPiece(type: PieceType.king, color: PieceColor.white),
          ),
        ];
    }
  }

  LearningStep _convertPuzzleToStep(EndgamePuzzle puzzle) {
    return LearningStep(
      id: puzzle.id,
      title: puzzle.title,
      description: puzzle.description,
      type: StepType.practice,
      instructions: puzzle.hints ?? ['解决这个残局谜题'],
      boardState: puzzle.boardState,
      requiredMoves: puzzle.solution,
      successMessage: '很好！你解决了这个${puzzle.title}',
      failureMessage: '再试一次。${puzzle.evaluation ?? "仔细分析位置"}',
    );
  }
}

// Private class for tracking puzzle attempts
class _PuzzleAttempt {
  final String puzzleId;
  final bool successful;
  final int attempts;
  final DateTime timestamp;

  _PuzzleAttempt({
    required this.puzzleId,
    required this.successful,
    required this.attempts,
    required this.timestamp,
  });
}
