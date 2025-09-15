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
            instructions: ['兵只能向前移动', '第一次移动可以走1格或2格', '之后每次只能走1格', '斜向攻击敌方棋子'],
            boardState: _createPawnDemonstrationBoard(),
            demonstrationMoves: [
              ChessMove(
                from: const Position(row: 6, col: 4),
                to: const Position(row: 4, col: 4),
                piece: const ChessPiece(
                    type: PieceType.pawn, color: PieceColor.white),
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
            instructions: ['车可以水平或垂直移动任意格数', '不能跳过其他棋子', '可以吃掉路径终点的敌方棋子'],
            boardState: _createRookPracticeBoard(),
            requiredMoves: [
              ChessMove(
                from: const Position(row: 7, col: 0),
                to: const Position(row: 7, col: 4),
                piece: const ChessPiece(
                    type: PieceType.rook, color: PieceColor.white),
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
            instructions: ['马走"L"形：2格直线+1格垂直', '马是唯一可以跳过其他棋子的', '总共有8个可能的移动方向'],
            boardState: _createKnightPracticeBoard(),
            requiredMoves: [
              ChessMove(
                from: const Position(row: 7, col: 1),
                to: const Position(row: 5, col: 2),
                piece: const ChessPiece(
                    type: PieceType.knight, color: PieceColor.white),
              ),
            ],
            highlightPositions: [
              const Position(row: 7, col: 1), // 白马位置
            ],
            successMessage: '完美！马的L形移动很特殊，需要多练习。',
            failureMessage: '马必须走L形，请选择正确的目标位置。',
          ),
          LearningStep(
            id: 'bishop_movement',
            title: '象的移动',
            description: '学习象的斜向移动规则',
            type: StepType.practice,
            instructions: ['象只能斜向移动', '可以移动任意格数', '不能跳过其他棋子', '每个象只能在同色格子上移动'],
            boardState: _createBishopPracticeBoard(),
            requiredMoves: [
              ChessMove(
                from: const Position(row: 7, col: 2),
                to: const Position(row: 4, col: 5),
                piece: const ChessPiece(
                    type: PieceType.bishop, color: PieceColor.white),
              ),
            ],
            highlightPositions: [
              const Position(row: 7, col: 2), // 白象位置
            ],
            successMessage: '很好！象的斜向移动很优雅。',
            failureMessage: '象只能斜向移动，请选择对角线上的位置。',
          ),
          LearningStep(
            id: 'queen_movement',
            title: '后的移动',
            description: '学习后的强大移动能力',
            type: StepType.practice,
            instructions: [
              '后是最强大的棋子',
              '可以水平、垂直或斜向移动',
              '结合了车和象的移动方式',
              '可以移动任意格数但不能跳过棋子'
            ],
            boardState: _createQueenPracticeBoard(),
            requiredMoves: [
              ChessMove(
                from: const Position(row: 7, col: 3),
                to: const Position(row: 3, col: 7),
                piece: const ChessPiece(
                    type: PieceType.queen, color: PieceColor.white),
              ),
            ],
            highlightPositions: [
              const Position(row: 7, col: 3), // 白后位置
            ],
            successMessage: '完美！后的移动能力确实强大。',
            failureMessage: '后可以像车和象一样移动，请选择正确的路径。',
          ),
          LearningStep(
            id: 'king_movement',
            title: '王的移动',
            description: '学习王的移动和保护规则',
            type: StepType.practice,
            instructions: ['王是最重要的棋子', '只能移动一格', '可以向任意方向移动', '不能移动到被攻击的位置'],
            boardState: _createKingPracticeBoard(),
            requiredMoves: [
              ChessMove(
                from: const Position(row: 7, col: 4),
                to: const Position(row: 6, col: 4),
                piece: const ChessPiece(
                    type: PieceType.king, color: PieceColor.white),
              ),
            ],
            highlightPositions: [
              const Position(row: 7, col: 4), // 白王位置
            ],
            successMessage: '很好！保护王是游戏的核心目标。',
            failureMessage: '王只能移动一格，且不能进入危险位置。',
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
          LearningStep(
            id: 'en_passant',
            title: '吃过路兵',
            description: '学习吃过路兵的特殊规则',
            type: StepType.practice,
            instructions: [
              '吃过路兵是兵的特殊吃子方式',
              '只能在对方兵刚走两格后立即进行',
              '己方兵必须在第5行（白方）或第4行（黑方）',
              '吃掉的是对方刚移动的兵'
            ],
            boardState: _createEnPassantBoard(),
            requiredMoves: [
              ChessMove(
                from: const Position(row: 3, col: 4),
                to: const Position(row: 2, col: 5),
                piece: const ChessPiece(
                    type: PieceType.pawn, color: PieceColor.white),
              ),
            ],
            highlightPositions: [
              const Position(row: 3, col: 4), // 白兵位置
              const Position(row: 3, col: 5), // 黑兵位置（将被吃掉）
            ],
            successMessage: '很好！吃过路兵是一个重要的战术技巧。',
            failureMessage: '吃过路兵只能在特定条件下进行，请仔细阅读规则。',
          ),
          LearningStep(
            id: 'pawn_promotion',
            title: '兵升变',
            description: '学习兵升变的规则和选择',
            type: StepType.practice,
            instructions: [
              '兵到达对方底线时必须升变',
              '可以升变为后、车、象或马',
              '通常升变为后最有利',
              '升变是强制性的，不能保持兵'
            ],
            boardState: _createPawnPromotionBoard(),
            requiredMoves: [
              ChessMove(
                from: const Position(row: 1, col: 6),
                to: const Position(row: 0, col: 6),
                piece: const ChessPiece(
                    type: PieceType.pawn, color: PieceColor.white),
              ),
            ],
            highlightPositions: [
              const Position(row: 1, col: 6), // 白兵位置
            ],
            successMessage: '完美！兵升变可以改变游戏的局面。',
            failureMessage: '兵必须移动到底线才能升变，请选择正确的移动。',
          ),
        ],
      );

  /// 战术训练课程
  LearningLesson get tacticsLesson => LearningLesson(
        id: 'tactics',
        title: '基础战术',
        description: '学习常见的战术技巧和组合',
        mode: LearningMode.tactics,
        steps: [
          LearningStep(
            id: 'tactics_intro',
            title: '战术概述',
            description: '了解国际象棋中的基本战术概念',
            type: StepType.explanation,
            instructions: const [
              '战术是国际象棋中的短期计划和技巧',
              '好的战术能够获得物质优势或位置优势',
              '基本战术包括：牵制、叉攻、串攻、发现攻击',
              '掌握战术是提高棋力的关键'
            ],
            boardState: _createInitialBoard(),
            highlightPositions: const [
              Position(row: 3, col: 3), // d5
              Position(row: 3, col: 4), // e5
              Position(row: 4, col: 3), // d4
              Position(row: 4, col: 4), // e4 - 战术常发生的中心区域
            ],
          ),
          LearningStep(
            id: 'pin_tactic',
            title: '牵制战术',
            description: '学习如何使用牵制战术',
            type: StepType.explanation,
            instructions: const [
              '牵制是限制对方棋子移动的战术',
              '被牵制的棋子不能移动，否则会暴露更重要的棋子',
              '牵制分为绝对牵制和相对牵制',
              '绝对牵制：被牵制棋子后面是王，不能移动'
            ],
            boardState: _createPinTacticBoard(),
            highlightPositions: const [
              Position(row: 4, col: 4), // 被牵制的棋子
              Position(row: 4, col: 0), // 牵制的车
              Position(row: 4, col: 7), // 被保护的王
            ],
          ),
          LearningStep(
            id: 'pin_practice',
            title: '牵制练习',
            description: '练习识别和执行牵制战术',
            type: StepType.practice,
            instructions: const [
              '观察棋盘上的局面',
              '找到可以牵制对方棋子的机会',
              '执行牵制移动',
              '牵制能限制对方的选择'
            ],
            boardState: _createPinPracticeBoard(),
            requiredMoves: const [
              ChessMove(
                from: Position(row: 7, col: 0), // a1车
                to: Position(row: 4, col: 0), // a4
                piece:
                    ChessPiece(type: PieceType.rook, color: PieceColor.white),
              ),
            ],
            successMessage: '很好！你成功牵制了对方的马，它现在不能移动了。',
            failureMessage: '试试用车牵制对方的马，让它无法移动。',
            highlightPositions: const [
              Position(row: 7, col: 0), // 白车
              Position(row: 4, col: 0), // 目标位置
              Position(row: 4, col: 1), // 被牵制的马
            ],
          ),
          LearningStep(
            id: 'fork_tactic',
            title: '叉攻战术',
            description: '学习如何使用叉攻战术',
            type: StepType.demonstration,
            instructions: const [
              '叉攻是同时攻击两个或多个目标',
              '马是执行叉攻的最佳棋子',
              '叉攻通常能获得物质优势',
              '王叉是最强力的叉攻形式'
            ],
            boardState: _createForkTacticBoard(),
            demonstrationMoves: const [
              ChessMove(
                from: Position(row: 5, col: 2), // c3马
                to: Position(row: 3, col: 3), // d5
                piece:
                    ChessPiece(type: PieceType.knight, color: PieceColor.white),
              ),
            ],
            highlightPositions: const [
              Position(row: 3, col: 3), // 叉攻位置
              Position(row: 2, col: 4), // 被攻击的王
              Position(row: 4, col: 5), // 被攻击的车
            ],
          ),
          LearningStep(
            id: 'skewer_tactic',
            title: '串攻战术',
            description: '学习如何使用串攻战术',
            type: StepType.explanation,
            instructions: const [
              '串攻是攻击一个棋子，迫使它移动后攻击后面的棋子',
              '串攻与牵制相反：先攻击前面的棋子',
              '通常用来攻击价值较低的棋子，获得后面价值更高的棋子',
              '长距离棋子（车、象、后）最适合执行串攻'
            ],
            boardState: _createSkewerTacticBoard(),
            highlightPositions: const [
              Position(row: 4, col: 0), // 攻击的车
              Position(row: 4, col: 3), // 前面的象
              Position(row: 4, col: 6), // 后面的王
            ],
          ),
          LearningStep(
            id: 'discovery_attack',
            title: '发现攻击',
            description: '学习发现攻击的战术',
            type: StepType.demonstration,
            instructions: const [
              '发现攻击是移动一个棋子，暴露后面棋子的攻击',
              '移动的棋子和后面的棋子都能造成威胁',
              '发现将军是最强力的发现攻击',
              '可以同时攻击多个目标'
            ],
            boardState: _createDiscoveryAttackBoard(),
            demonstrationMoves: const [
              ChessMove(
                from: Position(row: 4, col: 3), // d4马
                to: Position(row: 2, col: 2), // c6
                piece:
                    ChessPiece(type: PieceType.knight, color: PieceColor.white),
              ),
            ],
            highlightPositions: const [
              Position(row: 4, col: 3), // 移动的马
              Position(row: 4, col: 0), // 后面的车
              Position(row: 4, col: 7), // 被攻击的王
            ],
          ),
          LearningStep(
            id: 'tactical_combination',
            title: '战术组合',
            description: '学习如何组合多种战术',
            type: StepType.practice,
            instructions: const [
              '战术组合是连续使用多种战术技巧',
              '先用一个战术创造机会，再用另一个战术获得优势',
              '观察局面，寻找组合的可能性',
              '执行第一步战术移动'
            ],
            boardState: _createTacticalCombinationBoard(),
            requiredMoves: const [
              ChessMove(
                from: Position(row: 5, col: 5), // f3马
                to: Position(row: 3, col: 4), // e5
                piece:
                    ChessPiece(type: PieceType.knight, color: PieceColor.white),
              ),
            ],
            successMessage: '很好！这个马叉同时攻击了王和车，这是一个强力的战术组合。',
            failureMessage: '试试用马叉攻击王和车，这是一个经典的战术组合。',
            highlightPositions: const [
              Position(row: 5, col: 5), // 白马
              Position(row: 3, col: 4), // 叉攻位置
              Position(row: 2, col: 3), // 黑王
              Position(row: 4, col: 6), // 黑车
            ],
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
            instructions: ['王兵残局是最基础的残局类型', '需要学会如何推进兵升变', '王的位置至关重要'],
            boardState: _createKingPawnEndgameBoard(),
          ),
          // 谜题步骤会通过 EndgamePuzzleService 动态添加
          ...(_puzzleSteps ?? []),
        ],
      );

  // 静态变量用于存储谜题步骤
  static List<LearningStep>? _puzzleSteps;

  /// 添加谜题步骤到残局课程
  static void addPuzzleSteps(List<LearningStep> steps) {
    _puzzleSteps = steps;
  }

  /// 开局训练课程
  LearningLesson get openingsLesson => LearningLesson(
        id: 'openings',
        title: '基础开局',
        description: '学习常见的开局原则和经典开局系统',
        mode: LearningMode.openings,
        steps: [
          LearningStep(
            id: 'opening_principles_intro',
            title: '开局原则概述',
            description: '学习开局的四大基本原则',
            type: StepType.explanation,
            instructions: [
              '开局阶段是国际象棋游戏的开始，通常指前10-15步',
              '好的开局能为中局和残局奠定坚实基础',
              '开局有四大基本原则需要遵循',
              '掌握这些原则比记住具体变化更重要'
            ],
            boardState: _createInitialBoard(),
            highlightPositions: [
              const Position(row: 3, col: 3), // d5
              const Position(row: 3, col: 4), // e5
              const Position(row: 4, col: 3), // d4
              const Position(row: 4, col: 4), // e4 - 中心格子
            ],
          ),
          LearningStep(
            id: 'center_control',
            title: '控制中心',
            description: '学习如何控制棋盘中心',
            type: StepType.demonstration,
            instructions: [
              '棋盘中心的四个格子（d4, d5, e4, e5）最重要',
              '控制中心的棋子活动范围更大',
              '用兵和棋子共同控制中心',
              '不要急于占领中心，先控制再占领'
            ],
            boardState: _createCenterControlBoard(),
            demonstrationMoves: const [
              ChessMove(
                from: Position(row: 6, col: 4), // e2
                to: Position(row: 4, col: 4), // e4
                piece:
                    ChessPiece(type: PieceType.pawn, color: PieceColor.white),
              ),
              ChessMove(
                from: Position(row: 1, col: 4), // e7
                to: Position(row: 3, col: 4), // e5
                piece:
                    ChessPiece(type: PieceType.pawn, color: PieceColor.black),
              ),
            ],
            highlightPositions: const [
              Position(row: 3, col: 3), // d5
              Position(row: 3, col: 4), // e5
              Position(row: 4, col: 3), // d4
              Position(row: 4, col: 4), // e4
            ],
          ),
          LearningStep(
            id: 'piece_development',
            title: '快速出子',
            description: '学习如何快速发展棋子',
            type: StepType.demonstration,
            instructions: [
              '先出马，再出象，最后出后',
              '不要过早出后，容易被攻击',
              '每步棋都要发展新的棋子',
              '避免重复移动同一个棋子'
            ],
            boardState: _createDevelopmentBoard(),
            demonstrationMoves: [
              ChessMove(
                from: const Position(row: 7, col: 1), // b1
                to: const Position(row: 5, col: 2), // c3
                piece: const ChessPiece(
                    type: PieceType.knight, color: PieceColor.white),
              ),
              ChessMove(
                from: const Position(row: 7, col: 2), // c1
                to: const Position(row: 4, col: 5), // f4
                piece: const ChessPiece(
                    type: PieceType.bishop, color: PieceColor.white),
              ),
            ],
            highlightPositions: const [
              Position(row: 7, col: 1), // b1 马
              Position(row: 7, col: 2), // c1 象
              Position(row: 7, col: 5), // f1 象
              Position(row: 7, col: 6), // g1 马
            ],
          ),
          LearningStep(
            id: 'king_safety',
            title: '保护王的安全',
            description: '学习如何保护王的安全',
            type: StepType.explanation,
            instructions: const [
              '王车易位是保护王的最佳方式',
              '尽早进行王车易位',
              '避免过早移动王前的兵',
              '不要让王暴露在中央'
            ],
            boardState: _createKingSafetyBoard(),
            highlightPositions: const [
              Position(row: 7, col: 4), // 白王
              Position(row: 7, col: 6), // 王车易位后的位置
              Position(row: 6, col: 5), // f2兵
              Position(row: 6, col: 6), // g2兵
              Position(row: 6, col: 7), // h2兵
            ],
          ),
          LearningStep(
            id: 'opening_practice',
            title: '开局练习',
            description: '练习正确的开局移动',
            type: StepType.practice,
            instructions: const [
              '请按照开局原则进行移动',
              '先控制中心，然后发展棋子',
              '记住：控制中心 → 发展棋子 → 保护王'
            ],
            boardState: _createInitialBoard(),
            requiredMoves: const [
              ChessMove(
                from: Position(row: 6, col: 4), // e2
                to: Position(row: 4, col: 4), // e4
                piece:
                    ChessPiece(type: PieceType.pawn, color: PieceColor.white),
              ),
            ],
            successMessage: '很好！e4是一个经典的开局移动，控制了中心。',
            failureMessage: '试试移动e2兵到e4，这是控制中心的好方法。',
            highlightPositions: const [
              Position(row: 6, col: 4), // e2兵
              Position(row: 4, col: 4), // e4目标位置
            ],
          ),
          LearningStep(
            id: 'italian_game_intro',
            title: '意大利开局简介',
            description: '学习经典的意大利开局',
            type: StepType.demonstration,
            instructions: const [
              '意大利开局是最古老的开局之一',
              '白方快速发展象到c4攻击f7弱点',
              '这是学习开局原则的好例子',
              '遵循了控制中心和快速发展的原则'
            ],
            boardState: _createItalianGameBoard(),
            demonstrationMoves: const [
              ChessMove(
                from: Position(row: 6, col: 4), // e2
                to: Position(row: 4, col: 4), // e4
                piece:
                    ChessPiece(type: PieceType.pawn, color: PieceColor.white),
              ),
              ChessMove(
                from: Position(row: 7, col: 6), // g1
                to: Position(row: 5, col: 5), // f3
                piece:
                    ChessPiece(type: PieceType.knight, color: PieceColor.white),
              ),
              ChessMove(
                from: Position(row: 7, col: 5), // f1
                to: Position(row: 4, col: 2), // c4
                piece:
                    ChessPiece(type: PieceType.bishop, color: PieceColor.white),
              ),
            ],
            highlightPositions: const [
              Position(row: 4, col: 4), // e4
              Position(row: 5, col: 5), // f3
              Position(row: 4, col: 2), // c4
              Position(row: 1, col: 5), // f7 - 攻击目标
            ],
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
    board[0][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);
    board[1][4] =
        const ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[2][3] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    return board;
  }

  List<List<ChessPiece?>> _createPawnDemonstrationBoard() {
    final board = _createEmptyBoard();
    board[6][4] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    board[1][4] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createRookPracticeBoard() {
    final board = _createEmptyBoard();
    board[7][0] =
        const ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[7][7] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][0] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createKnightPracticeBoard() {
    final board = _createEmptyBoard();
    board[7][1] =
        const ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[7][7] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][0] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createCastlingBoard() {
    final board = _createEmptyBoard();
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[7][7] =
        const ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[0][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createPinTacticBoard() {
    final board = _createEmptyBoard();
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[6][4] =
        const ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[4][4] =
        const ChessPiece(type: PieceType.rook, color: PieceColor.black);
    board[0][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createKingPawnEndgameBoard() {
    final board = _createEmptyBoard();
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[5][4] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    board[0][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);
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

  List<List<ChessPiece?>> _createBishopPracticeBoard() {
    final board = _createEmptyBoard();
    board[7][2] =
        const ChessPiece(type: PieceType.bishop, color: PieceColor.white);
    board[7][7] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][0] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);
    // Add some pawns to show blocking
    board[5][4] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createQueenPracticeBoard() {
    final board = _createEmptyBoard();
    board[7][3] =
        const ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[7][7] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][0] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);
    // Add some pieces to show queen's power
    board[5][5] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    board[4][3] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    return board;
  }

  List<List<ChessPiece?>> _createKingPracticeBoard() {
    final board = _createEmptyBoard();
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);
    // Add some pieces to show king's limited movement
    board[6][3] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    board[6][5] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    return board;
  }

  List<List<ChessPiece?>> _createEnPassantBoard() {
    final board = _createEmptyBoard();
    // White king and black king
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);

    // White pawn on 5th rank (row 3) ready for en passant
    board[3][4] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

    // Black pawn adjacent to white pawn (just moved two squares)
    board[3][5] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

    return board;
  }

  List<List<ChessPiece?>> _createPawnPromotionBoard() {
    final board = _createEmptyBoard();
    // White king and black king
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);

    // White pawn on 7th rank (row 1) ready to promote
    board[1][6] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

    // Add some other pieces for context
    board[2][5] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

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

  /// 创建中心控制演示棋盘
  List<List<ChessPiece?>> _createCenterControlBoard() {
    final board = _createInitialBoard();
    return board;
  }

  /// 创建棋子发展演示棋盘
  List<List<ChessPiece?>> _createDevelopmentBoard() {
    final board = _createInitialBoard();
    // 移动一些兵为棋子发展做准备
    board[6][4] = null; // 移除e2兵
    board[4][4] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.white); // e4
    board[1][4] = null; // 移除e7兵
    board[3][4] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.black); // e5
    return board;
  }

  /// 创建王安全演示棋盘
  List<List<ChessPiece?>> _createKingSafetyBoard() {
    final board = _createInitialBoard();
    // 模拟王车易位后的位置
    board[7][4] = null; // 移除原王位置
    board[7][6] = const ChessPiece(
        type: PieceType.king, color: PieceColor.white); // 王车易位后
    board[7][7] = null; // 移除原车位置
    board[7][5] =
        const ChessPiece(type: PieceType.rook, color: PieceColor.white); // 车易位后
    return board;
  }

  /// 创建意大利开局演示棋盘
  List<List<ChessPiece?>> _createItalianGameBoard() {
    final board = _createInitialBoard();
    // 意大利开局的前几步
    board[6][4] = null; // 移除e2兵
    board[4][4] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.white); // e4
    board[7][6] = null; // 移除g1马
    board[5][5] = const ChessPiece(
        type: PieceType.knight, color: PieceColor.white); // Nf3
    board[7][5] = null; // 移除f1象
    board[4][2] = const ChessPiece(
        type: PieceType.bishop, color: PieceColor.white); // Bc4

    // 黑方回应
    board[1][4] = null; // 移除e7兵
    board[3][4] =
        const ChessPiece(type: PieceType.pawn, color: PieceColor.black); // e5
    board[0][1] = null; // 移除b8马
    board[2][2] = const ChessPiece(
        type: PieceType.knight, color: PieceColor.black); // Nc6

    return board;
  }

  /// 创建牵制练习棋盘
  List<List<ChessPiece?>> _createPinPracticeBoard() {
    final board = _createEmptyBoard();
    // 白王和黑王
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[0][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);

    // 白车在a1，可以牵制黑马
    board[7][0] =
        const ChessPiece(type: PieceType.rook, color: PieceColor.white);

    // 黑马在a4，黑王在a8（可以被牵制）
    board[4][1] =
        const ChessPiece(type: PieceType.knight, color: PieceColor.black);
    board[4][0] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black); // 改为a4

    return board;
  }

  /// 创建叉攻战术棋盘
  List<List<ChessPiece?>> _createForkTacticBoard() {
    final board = _createEmptyBoard();
    // 白王和黑王
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[2][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);

    // 白马在c3，可以叉攻黑王和黑车
    board[5][2] =
        const ChessPiece(type: PieceType.knight, color: PieceColor.white);

    // 黑车在f4
    board[4][5] =
        const ChessPiece(type: PieceType.rook, color: PieceColor.black);

    return board;
  }

  /// 创建串攻战术棋盘
  List<List<ChessPiece?>> _createSkewerTacticBoard() {
    final board = _createEmptyBoard();
    // 白王和黑王
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[4][6] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);

    // 白车在a4，可以串攻黑象和黑王
    board[4][0] =
        const ChessPiece(type: PieceType.rook, color: PieceColor.white);

    // 黑象在d4（前面），黑王在g4（后面）
    board[4][3] =
        const ChessPiece(type: PieceType.bishop, color: PieceColor.black);

    return board;
  }

  /// 创建发现攻击棋盘
  List<List<ChessPiece?>> _createDiscoveryAttackBoard() {
    final board = _createEmptyBoard();
    // 白王和黑王
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[4][7] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);

    // 白车在a4，白马在d4（挡住攻击线）
    board[4][0] =
        const ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[4][3] =
        const ChessPiece(type: PieceType.knight, color: PieceColor.white);

    return board;
  }

  /// 创建战术组合棋盘
  List<List<ChessPiece?>> _createTacticalCombinationBoard() {
    final board = _createEmptyBoard();
    // 白王和黑王
    board[7][4] =
        const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[2][3] =
        const ChessPiece(type: PieceType.king, color: PieceColor.black);

    // 白马在f3，可以叉攻黑王和黑车
    board[5][5] =
        const ChessPiece(type: PieceType.knight, color: PieceColor.white);

    // 黑车在f4
    board[4][6] =
        const ChessPiece(type: PieceType.rook, color: PieceColor.black);

    return board;
  }
}
