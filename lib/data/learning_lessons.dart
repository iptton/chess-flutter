import '../models/learning_models.dart';
import '../models/chess_models.dart';

class LearningLessons {
  /// 基础规则课程
  LearningLesson get basicRulesLesson => LearningLesson(
    id: 'basic_rules',
    title: '国际象棋基础规则',
    description: '学习国际象棋的基本规则和目标',
    mode: LearningMode.basicRules,
    steps: [
      LearningStep(
        id: 'basic_rules_intro',
        title: '欢迎来到国际象棋世界',
        description: '国际象棋是一种策略棋类游戏，由两名玩家对弈。',
        type: StepType.explanation,
        instructions: [
          '国际象棋在8×8的棋盘上进行',
          '每位玩家开始时有16个棋子',
          '白方先行，然后轮流移动',
          '游戏目标是将死对方的王'
        ],
        boardState: _createInitialBoard(),
      ),
      LearningStep(
        id: 'basic_rules_board',
        title: '认识棋盘',
        description: '了解国际象棋棋盘的构成',
        type: StepType.explanation,
        instructions: [
          '棋盘由64个方格组成，黑白相间',
          '从左到右标记为a-h列',
          '从下到上标记为1-8行',
          '右下角必须是白色方格'
        ],
        boardState: _createEmptyBoard(),
        highlightPositions: [
          const Position(row: 7, col: 0), // a1
          const Position(row: 7, col: 7), // h1
          const Position(row: 0, col: 0), // a8
          const Position(row: 0, col: 7), // h8
        ],
      ),
      LearningStep(
        id: 'basic_rules_objective',
        title: '游戏目标',
        description: '学习如何获胜',
        type: StepType.explanation,
        instructions: [
          '主要目标：将死对方的王',
          '将军：攻击对方的王',
          '将死：王被攻击且无法逃脱',
          '和棋：无法继续进行有效移动'
        ],
        boardState: _createCheckmateExample(),
        highlightPositions: [
          const Position(row: 0, col: 4), // 黑王位置
        ],
      ),
    ],
  );

  /// 棋子移动课程
  LearningLesson get pieceMovementLesson => LearningLesson(
    id: 'piece_movement',
    title: '棋子移动规则',
    description: '学习每个棋子的移动方式',
    mode: LearningMode.pieceMovement,
    steps: [
      LearningStep(
        id: 'pawn_movement',
        title: '兵的移动',
        description: '学习兵的移动规则',
        type: StepType.demonstration,
        instructions: [
          '兵只能向前移动',
          '第一次移动可以走1格或2格',
          '之后每次只能走1格',
          '斜向攻击敌方棋子'
        ],
        boardState: _createPawnDemonstrationBoard(),
        demonstrationMoves: [
          ChessMove(
            from: const Position(row: 6, col: 4),
            to: const Position(row: 4, col: 4),
            piece: const ChessPiece(type: PieceType.pawn, color: PieceColor.white),
          ),
        ],
        highlightPositions: [
          const Position(row: 6, col: 4), // 白兵位置
        ],
      ),
      LearningStep(
        id: 'rook_movement',
        title: '车的移动',
        description: '学习车的移动规则',
        type: StepType.practice,
        instructions: [
          '车可以水平或垂直移动任意格数',
          '不能跳过其他棋子',
          '可以吃掉路径终点的敌方棋子'
        ],
        boardState: _createRookPracticeBoard(),
        requiredMoves: [
          ChessMove(
            from: const Position(row: 7, col: 0),
            to: const Position(row: 7, col: 4),
            piece: const ChessPiece(type: PieceType.rook, color: PieceColor.white),
          ),
        ],
        highlightPositions: [
          const Position(row: 7, col: 0), // 白车位置
        ],
        successMessage: '很好！车可以在直线上移动任意距离。',
        failureMessage: '车只能水平或垂直移动，请再试一次。',
      ),
      LearningStep(
        id: 'knight_movement',
        title: '马的移动',
        description: '学习马的特殊移动方式',
        type: StepType.practice,
        instructions: [
          '马走"L"形：2格直线+1格垂直',
          '马是唯一可以跳过其他棋子的',
          '总共有8个可能的移动方向'
        ],
        boardState: _createKnightPracticeBoard(),
        requiredMoves: [
          ChessMove(
            from: const Position(row: 7, col: 1),
            to: const Position(row: 5, col: 2),
            piece: const ChessPiece(type: PieceType.knight, color: PieceColor.white),
          ),
        ],
        highlightPositions: [
          const Position(row: 7, col: 1), // 白马位置
        ],
        successMessage: '完美！马的L形移动很特殊，需要多练习。',
        failureMessage: '马必须走L形，请选择正确的目标位置。',
      ),
    ],
  );

  /// 特殊移动课程
  LearningLesson get specialMovesLesson => LearningLesson(
    id: 'special_moves',
    title: '特殊移动规则',
    description: '学习王车易位、吃过路兵和兵升变',
    mode: LearningMode.specialMoves,
    steps: [
      LearningStep(
        id: 'castling',
        title: '王车易位',
        description: '学习王车易位的规则和条件',
        type: StepType.explanation,
        instructions: [
          '王车易位是王和车的联合移动',
          '王向车的方向移动2格',
          '车移动到王跨过的位置',
          '需要满足特定条件才能进行'
        ],
        boardState: _createCastlingBoard(),
        highlightPositions: [
          const Position(row: 7, col: 4), // 白王
          const Position(row: 7, col: 7), // 白车
        ],
      ),
    ],
  );

  /// 战术训练课程
  LearningLesson get tacticsLesson => LearningLesson(
    id: 'tactics',
    title: '基础战术',
    description: '学习常见的战术技巧',
    mode: LearningMode.tactics,
    steps: [
      LearningStep(
        id: 'pin_tactic',
        title: '牵制战术',
        description: '学习如何使用牵制战术',
        type: StepType.explanation,
        instructions: [
          '牵制是限制对方棋子移动的战术',
          '被牵制的棋子不能移动，否则会暴露更重要的棋子',
          '牵制可以创造战术机会'
        ],
        boardState: _createPinTacticBoard(),
      ),
    ],
  );

  /// 残局训练课程
  LearningLesson get endgameLesson => LearningLesson(
    id: 'endgame',
    title: '基础残局',
    description: '学习常见的残局技巧',
    mode: LearningMode.endgame,
    steps: [
      LearningStep(
        id: 'king_pawn_endgame',
        title: '王兵残局',
        description: '学习王兵残局的基本技巧',
        type: StepType.explanation,
        instructions: [
          '王兵残局是最基础的残局类型',
          '需要学会如何推进兵升变',
          '王的位置至关重要'
        ],
        boardState: _createKingPawnEndgameBoard(),
      ),
    ],
  );

  /// 开局训练课程
  LearningLesson get openingsLesson => LearningLesson(
    id: 'openings',
    title: '基础开局',
    description: '学习常见的开局原则',
    mode: LearningMode.openings,
    steps: [
      LearningStep(
        id: 'opening_principles',
        title: '开局原则',
        description: '学习开局的基本原则',
        type: StepType.explanation,
        instructions: [
          '控制中心',
          '快速出子',
          '保护王的安全',
          '不要重复移动同一个棋子'
        ],
        boardState: _createInitialBoard(),
      ),
    ],
  );

  // 辅助方法创建特定的棋盘状态
  List<List<ChessPiece?>> _createEmptyBoard() {
    return List.generate(8, (i) => List.generate(8, (j) => null));
  }

  List<List<ChessPiece?>> _createCheckmateExample() {
    final board = _createEmptyBoard();
    // 创建一个简单的将死局面
    board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
    board[1][4] = const ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[2][3] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
    return board;
  }

  List<List<ChessPiece?>> _createPawnDemonstrationBoard() {
    final board = _createEmptyBoard();
    board[6][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    board[1][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createRookPracticeBoard() {
    final board = _createEmptyBoard();
    board[7][0] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[7][7] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][0] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createKnightPracticeBoard() {
    final board = _createEmptyBoard();
    board[7][1] = const ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[7][7] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][0] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createCastlingBoard() {
    final board = _createEmptyBoard();
    board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createPinTacticBoard() {
    final board = _createEmptyBoard();
    board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[6][4] = const ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[4][4] = const ChessPiece(type: PieceType.rook, color: PieceColor.black);
    board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createKingPawnEndgameBoard() {
    final board = _createEmptyBoard();
    board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[5][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
    return board;
  }

  /// 创建初始棋盘状态
  List<List<ChessPiece?>> _createInitialBoard() {
    final board = List.generate(8, (row) {
      return List.generate(8, (col) {
        return _getInitialPiece(row, col);
      });
    });
    return board;
  }

  /// 获取初始位置的棋子
  ChessPiece? _getInitialPiece(int row, int col) {
    if (row == 1) {
      return const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    } else if (row == 6) {
      return const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    } else if (row == 0 || row == 7) {
      final color = row == 0 ? PieceColor.black : PieceColor.white;
      switch (col) {
        case 0:
        case 7:
          return ChessPiece(type: PieceType.rook, color: color);
        case 1:
        case 6:
          return ChessPiece(type: PieceType.knight, color: color);
        case 2:
        case 5:
          return ChessPiece(type: PieceType.bishop, color: color);
        case 3:
          return ChessPiece(type: PieceType.queen, color: color);
        case 4:
          return ChessPiece(type: PieceType.king, color: color);
      }
    }
    return null;
  }
}
