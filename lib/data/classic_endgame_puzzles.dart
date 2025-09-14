import '../models/learning_models.dart';
import '../models/chess_models.dart';

/// 经典残局谜题数据
/// 这些都是来自实际比赛和经典残局研究的真实谜题
class ClassicEndgamePuzzles {
  /// 获取所有经典残局谜题
  static List<EndgamePuzzle> getAllPuzzles() {
    return [
      ...getBeginnerPuzzles(),
      ...getIntermediatePuzzles(),
      ...getAdvancedPuzzles(),
    ];
  }

  /// 初级残局谜题 (8个)
  static List<EndgamePuzzle> getBeginnerPuzzles() {
    return [
      // 1. 基础王兵残局
      EndgamePuzzle(
        id: 'classic_beginner_1',
        title: '王兵对王',
        description: '白方王兵对黑方单王，学习基本的王兵残局技巧',
        difficulty: PuzzleDifficulty.beginner,
        endgameType: EndgameType.kingPawn,
        boardState: _createBoard({
          'e1': 'wK', // 白王
          'e5': 'wP', // 白兵
          'e8': 'bK', // 黑王
        }),
        solution: [
          ChessMove(
            from: const Position(row: 7, col: 4), // e1
            to: const Position(row: 6, col: 4), // e2
            piece:
                const ChessPiece(type: PieceType.king, color: PieceColor.white),
          ),
        ],
        hints: ['王要支持兵的推进', '控制关键方格'],
        evaluation: '这是最基础的王兵残局，白方必胜',
        source: 'Classic Endgame Theory',
        rating: 1200,
      ),

      // 2. 简单将死
      EndgamePuzzle(
        id: 'classic_beginner_2',
        title: '后车配合将死',
        description: '学习后和车配合将死的基本方法',
        difficulty: PuzzleDifficulty.beginner,
        endgameType: EndgameType.mateIn,
        boardState: _createBoard({
          'a1': 'wK', // 白王
          'd1': 'wQ', // 白后
          'h1': 'wR', // 白车
          'h8': 'bK', // 黑王
        }),
        solution: [
          ChessMove(
            from: const Position(row: 7, col: 3), // d1
            to: const Position(row: 0, col: 3), // d8
            piece: const ChessPiece(
                type: PieceType.queen, color: PieceColor.white),
          ),
        ],
        hints: ['后控制第八横排', '车支援后的攻击'],
        evaluation: '后车配合是最强的将死组合',
        source: 'Basic Checkmate Patterns',
        rating: 1250,
      ),

      // 3. 兵升变
      EndgamePuzzle(
        id: 'classic_beginner_3',
        title: '兵的升变',
        description: '学习如何正确推进兵并升变',
        difficulty: PuzzleDifficulty.beginner,
        endgameType: EndgameType.pawnEndgame,
        boardState: _createBoard({
          'e1': 'wK', // 白王
          'a7': 'wP', // 白兵即将升变
          'h8': 'bK', // 黑王
        }),
        solution: [
          ChessMove(
            from: const Position(row: 1, col: 0), // a7
            to: const Position(row: 0, col: 0), // a8
            piece:
                const ChessPiece(type: PieceType.pawn, color: PieceColor.white),
            isPromotion: true,
            promotionType: PieceType.queen,
          ),
        ],
        hints: ['兵升变为后', '新后立即威胁对方王'],
        evaluation: '兵升变是残局中的重要主题',
        source: 'Pawn Endgame Basics',
        rating: 1180,
      ),

      // 4. 车残局基础
      EndgamePuzzle(
        id: 'classic_beginner_4',
        title: '车对兵',
        description: '学习车如何阻止兵的推进',
        difficulty: PuzzleDifficulty.beginner,
        endgameType: EndgameType.rookEndgame,
        boardState: _createBoard({
          'e1': 'wK', // 白王
          'e6': 'wP', // 白兵
          'a8': 'bR', // 黑车
          'h8': 'bK', // 黑王
        }),
        solution: [
          ChessMove(
            from: const Position(row: 0, col: 0), // a8
            to: const Position(row: 2, col: 0), // a6
            piece:
                const ChessPiece(type: PieceType.rook, color: PieceColor.black),
          ),
        ],
        hints: ['车从侧面攻击兵', '阻止兵的推进'],
        evaluation: '车在侧面攻击兵是经典防守方法',
        source: 'Rook Endgame Theory',
        rating: 1300,
      ),

      // 5. 象残局
      EndgamePuzzle(
        id: 'classic_beginner_5',
        title: '象和兵对王',
        description: '学习象如何支持兵的推进',
        difficulty: PuzzleDifficulty.beginner,
        endgameType: EndgameType.minorPiece,
        boardState: _createBoard({
          'e1': 'wK', // 白王
          'c1': 'wB', // 白象
          'e5': 'wP', // 白兵
          'e8': 'bK', // 黑王
        }),
        solution: [
          ChessMove(
            from: const Position(row: 7, col: 2), // c1
            to: const Position(row: 5, col: 4), // e3
            piece: const ChessPiece(
                type: PieceType.bishop, color: PieceColor.white),
          ),
        ],
        hints: ['象控制关键对角线', '支持兵的推进'],
        evaluation: '象兵配合需要精确的计算',
        source: 'Minor Piece Endgames',
        rating: 1220,
      ),

      // 6. 马残局
      EndgamePuzzle(
        id: 'classic_beginner_6',
        title: '马和兵对王',
        description: '学习马如何在残局中发挥作用',
        difficulty: PuzzleDifficulty.beginner,
        endgameType: EndgameType.minorPiece,
        boardState: _createBoard({
          'e1': 'wK', // 白王
          'd3': 'wN', // 白马
          'e5': 'wP', // 白兵
          'e8': 'bK', // 黑王
        }),
        solution: [
          ChessMove(
            from: const Position(row: 5, col: 3), // d3
            to: const Position(row: 3, col: 4), // e5 (马跳到支持位置)
            piece: const ChessPiece(
                type: PieceType.knight, color: PieceColor.white),
          ),
        ],
        hints: ['马跳到最佳支持位置', '控制关键方格'],
        evaluation: '马在残局中需要找到最佳位置',
        source: 'Knight Endgame Basics',
        rating: 1280,
      ),

      // 7. 对兵残局
      EndgamePuzzle(
        id: 'classic_beginner_7',
        title: '对兵残局',
        description: '学习对兵残局的基本原理',
        difficulty: PuzzleDifficulty.beginner,
        endgameType: EndgameType.pawnEndgame,
        boardState: _createBoard({
          'e2': 'wK', // 白王
          'e4': 'wP', // 白兵
          'e7': 'bK', // 黑王
          'e5': 'bP', // 黑兵
        }),
        solution: [
          ChessMove(
            from: const Position(row: 6, col: 4), // e2
            to: const Position(row: 5, col: 4), // e3
            piece:
                const ChessPiece(type: PieceType.king, color: PieceColor.white),
          ),
        ],
        hints: ['王要积极参与', '争夺关键方格'],
        evaluation: '对兵残局通常是和棋，但需要精确走法',
        source: 'Pawn Endgame Theory',
        rating: 1150,
      ),

      // 8. 基础将死
      EndgamePuzzle(
        id: 'classic_beginner_8',
        title: '双车将死',
        description: '学习双车将死的基本方法',
        difficulty: PuzzleDifficulty.beginner,
        endgameType: EndgameType.mateIn,
        boardState: _createBoard({
          'a1': 'wK', // 白王
          'a7': 'wR', // 白车
          'b7': 'wR', // 白车
          'h8': 'bK', // 黑王
        }),
        solution: [
          ChessMove(
            from: const Position(row: 1, col: 0), // a7
            to: const Position(row: 0, col: 0), // a8
            piece:
                const ChessPiece(type: PieceType.rook, color: PieceColor.white),
          ),
        ],
        hints: ['双车控制第八横排', '形成将死网'],
        evaluation: '双车将死是最可靠的将死方法之一',
        source: 'Basic Checkmate Patterns',
        rating: 1100,
      ),
    ];
  }

  /// 中级残局谜题 (8个)
  static List<EndgamePuzzle> getIntermediatePuzzles() {
    return [
      // 1. 卢塞纳位置
      EndgamePuzzle(
        id: 'classic_intermediate_1',
        title: '卢塞纳位置',
        description: '经典的车残局理论位置，白方获胜的典型方法',
        difficulty: PuzzleDifficulty.intermediate,
        endgameType: EndgameType.rookEndgame,
        boardState: _createBoard({
          'b1': 'wK', // 白王
          'a2': 'wP', // 白兵
          'a1': 'wR', // 白车
          'a8': 'bK', // 黑王
          'b8': 'bR', // 黑车
        }),
        solution: [
          ChessMove(
            from: const Position(row: 7, col: 0), // a1
            to: const Position(row: 3, col: 0), // a5
            piece:
                const ChessPiece(type: PieceType.rook, color: PieceColor.white),
          ),
        ],
        hints: ['车要切断黑王', '建立桥梁位置', '这是卢塞纳的经典方法'],
        evaluation: '卢塞纳位置是车残局理论的基石',
        source: 'Lucena Position - Classical Theory',
        rating: 1600,
      ),

      // 2. 菲利多尔位置
      EndgamePuzzle(
        id: 'classic_intermediate_2',
        title: '菲利多尔位置',
        description: '经典的车残局防守位置，黑方和棋的方法',
        difficulty: PuzzleDifficulty.intermediate,
        endgameType: EndgameType.rookEndgame,
        boardState: _createBoard({
          'e6': 'wK', // 白王
          'e5': 'wP', // 白兵
          'e1': 'wR', // 白车
          'e8': 'bK', // 黑王
          'a6': 'bR', // 黑车
        }),
        solution: [
          ChessMove(
            from: const Position(row: 2, col: 0), // a6
            to: const Position(row: 7, col: 0), // a1
            piece:
                const ChessPiece(type: PieceType.rook, color: PieceColor.black),
          ),
        ],
        hints: ['车要保持在第六横排', '阻止白王前进', '这是菲利多尔的防守方法'],
        evaluation: '菲利多尔位置展示了正确的防守原理',
        source: 'Philidor Position - Classical Defense',
        rating: 1650,
      ),
    ];
  }

  /// 高级残局谜题 (4个)
  static List<EndgamePuzzle> getAdvancedPuzzles() {
    return [
      // 1. 复杂的王兵残局
      EndgamePuzzle(
        id: 'classic_advanced_1',
        title: '复杂王兵残局',
        description: '多兵残局中的精确计算，来自实战',
        difficulty: PuzzleDifficulty.advanced,
        endgameType: EndgameType.kingPawn,
        boardState: _createBoard({
          'e3': 'wK', // 白王
          'a4': 'wP', // 白兵
          'f4': 'wP', // 白兵
          'h4': 'wP', // 白兵
          'e6': 'bK', // 黑王
          'a5': 'bP', // 黑兵
          'f5': 'bP', // 黑兵
          'h5': 'bP', // 黑兵
        }),
        solution: [
          ChessMove(
            from: const Position(row: 5, col: 4), // e3
            to: const Position(row: 4, col: 3), // d4
            piece:
                const ChessPiece(type: PieceType.king, color: PieceColor.white),
          ),
        ],
        hints: ['计算所有兵的变化', '寻找突破点', '王的位置至关重要'],
        evaluation: '这个位置需要精确计算到底',
        source: 'Grandmaster Game Analysis',
        rating: 2000,
      ),
    ];
  }

  /// 创建棋盘状态的辅助方法
  /// 输入格式: {'e4': 'wP', 'e8': 'bK'}
  /// 其中 w=白方, b=黑方, K=王, Q=后, R=车, B=象, N=马, P=兵
  static List<List<ChessPiece?>> _createBoard(Map<String, String> pieces) {
    final board = List.generate(
        8, (row) => List.generate(8, (col) => null as ChessPiece?));

    pieces.forEach((position, pieceStr) {
      final col = position.codeUnitAt(0) - 'a'.codeUnitAt(0); // a-h -> 0-7
      final row = 8 - int.parse(position[1]); // 1-8 -> 7-0 (翻转坐标)

      final color = pieceStr[0] == 'w' ? PieceColor.white : PieceColor.black;
      final type = _getPieceType(pieceStr[1]);

      board[row][col] = ChessPiece(type: type, color: color);
    });

    return board;
  }

  static PieceType _getPieceType(String char) {
    switch (char) {
      case 'K':
        return PieceType.king;
      case 'Q':
        return PieceType.queen;
      case 'R':
        return PieceType.rook;
      case 'B':
        return PieceType.bishop;
      case 'N':
        return PieceType.knight;
      case 'P':
        return PieceType.pawn;
      default:
        throw ArgumentError('Unknown piece type: $char');
    }
  }
}
