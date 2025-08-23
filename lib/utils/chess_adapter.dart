import 'package:chess/chess.dart' as chess_lib;
import '../models/chess_models.dart';

/// 适配器类，用于在 chess 包和现有数据模型之间进行转换
class ChessAdapter {
  /// 将现有的 PieceColor 转换为 chess 包的 Color
  static chess_lib.Color toChessLibColor(PieceColor color) {
    switch (color) {
      case PieceColor.white:
        return chess_lib.Color.WHITE;
      case PieceColor.black:
        return chess_lib.Color.BLACK;
    }
  }

  /// 将 chess 包的 Color 转换为现有的 PieceColor
  static PieceColor fromChessLibColor(chess_lib.Color color) {
    switch (color) {
      case chess_lib.Color.WHITE:
        return PieceColor.white;
      case chess_lib.Color.BLACK:
        return PieceColor.black;
    }
  }

  /// 将现有的 PieceType 转换为 chess 包的 PieceType
  static chess_lib.PieceType toChessLibPieceType(PieceType type) {
    switch (type) {
      case PieceType.king:
        return chess_lib.Chess.KING;
      case PieceType.queen:
        return chess_lib.Chess.QUEEN;
      case PieceType.rook:
        return chess_lib.Chess.ROOK;
      case PieceType.bishop:
        return chess_lib.Chess.BISHOP;
      case PieceType.knight:
        return chess_lib.Chess.KNIGHT;
      case PieceType.pawn:
        return chess_lib.Chess.PAWN;
    }
  }

  /// 将 chess 包的 PieceType 转换为现有的 PieceType
  static PieceType fromChessLibPieceType(chess_lib.PieceType type) {
    if (type == chess_lib.Chess.KING) return PieceType.king;
    if (type == chess_lib.Chess.QUEEN) return PieceType.queen;
    if (type == chess_lib.Chess.ROOK) return PieceType.rook;
    if (type == chess_lib.Chess.BISHOP) return PieceType.bishop;
    if (type == chess_lib.Chess.KNIGHT) return PieceType.knight;
    if (type == chess_lib.Chess.PAWN) return PieceType.pawn;
    throw ArgumentError('Unknown piece type: $type');
  }

  /// 将现有的 ChessPiece 转换为 chess 包的 Piece
  static chess_lib.Piece toChessLibPiece(ChessPiece piece) {
    return chess_lib.Piece(
      toChessLibPieceType(piece.type),
      toChessLibColor(piece.color),
    );
  }

  /// 将 chess 包的 Piece 转换为现有的 ChessPiece
  static ChessPiece fromChessLibPiece(chess_lib.Piece piece) {
    return ChessPiece(
      type: fromChessLibPieceType(piece.type),
      color: fromChessLibColor(piece.color),
    );
  }

  /// 将现有的 Position 转换为 chess 包的方格表示法 (如 'e4')
  static String toChessLibSquare(Position position) {
    // 添加坐标验证以防止超出范围的索引
    if (position.col < 0 ||
        position.col > 7 ||
        position.row < 0 ||
        position.row > 7) {
      throw ArgumentError('无效的位置坐标: (${position.row}, ${position.col})');
    }
    final file = String.fromCharCode('a'.codeUnitAt(0) + position.col);
    final rank = (8 - position.row).toString();
    return '$file$rank';
  }

  /// 将 chess 包的方格表示法转换为现有的 Position
  static Position fromChessLibSquare(String square) {
    if (square.length != 2) {
      throw ArgumentError('Invalid square format: $square');
    }
    final file = square[0].toLowerCase();
    final rank = int.parse(square[1]);

    final col = file.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - rank;

    return Position(row: row, col: col);
  }

  /// 从现有的棋盘状态创建 chess 包的 Chess 实例
  static chess_lib.Chess createChessFromBoard(
    List<List<ChessPiece?>> board,
    PieceColor currentPlayer, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
    int halfMoveClock = 0,
    int fullMoveNumber = 1,
  }) {
    final chess = chess_lib.Chess();
    chess.clear(); // 清空棋盘

    // 验证棋盘尺寸
    if (board.length != 8) {
      throw ArgumentError('棋盘必须是8x8的尺寸，当前行数: ${board.length}');
    }

    // 设置棋子，添加严格的边界检查
    for (int row = 0; row < 8; row++) {
      if (board[row].length != 8) {
        throw ArgumentError('棋盘第$row行必须有8列，当前列数: ${board[row].length}');
      }

      for (int col = 0; col < 8; col++) {
        final piece = board[row][col];
        if (piece != null) {
          // 添加额外的坐标验证
          if (row < 0 || row > 7 || col < 0 || col > 7) {
            throw ArgumentError('无效的棋盘坐标: ($row, $col)');
          }

          try {
            final square = toChessLibSquare(Position(row: row, col: col));
            chess.put(toChessLibPiece(piece), square);
          } catch (e) {
            // 如果坐标转换失败，记录错误但继续处理
            print('警告：无法在位置($row, $col)放置棋子 ${piece.type}，错误: $e');
          }
        }
      }
    }

    // 设置当前玩家
    chess.turn = toChessLibColor(currentPlayer);

    // 设置易位权限
    if (hasKingMoved != null && hasRookMoved != null) {
      _setCastlingRights(chess, hasKingMoved, hasRookMoved);
    }

    // 设置吃过路兵目标
    if (enPassantTarget != null) {
      // 添加边界检查，确保坐标有效
      if (enPassantTarget.row >= 0 &&
          enPassantTarget.row <= 7 &&
          enPassantTarget.col >= 0 &&
          enPassantTarget.col <= 7) {
        try {
          final squareNotation = toChessLibSquare(enPassantTarget);
          chess.ep_square = chess_lib.Chess.SQUARES[squareNotation];
        } catch (e) {
          // 如果坐标转换失败，忽略enPassantTarget设置
          print(
              '警告：无效的enPassantTarget坐标 (${enPassantTarget.row}, ${enPassantTarget.col})，已忽略');
        }
      } else {
        // 坐标超出边界，忽略enPassantTarget设置
        print(
            '警告：enPassantTarget坐标超出边界 (${enPassantTarget.row}, ${enPassantTarget.col})，已忽略');
      }
    }

    // 设置半步计数和全步计数
    chess.half_moves = halfMoveClock;
    chess.move_number = fullMoveNumber;

    return chess;
  }

  /// 设置易位权限
  static void _setCastlingRights(
    chess_lib.Chess chess,
    Map<PieceColor, bool> hasKingMoved,
    Map<PieceColor, Map<String, bool>> hasRookMoved,
  ) {
    // 重置易位权限
    chess.castling[chess_lib.Color.WHITE] = 0;
    chess.castling[chess_lib.Color.BLACK] = 0;

    // 白方易位权限
    if (!(hasKingMoved[PieceColor.white] ?? true)) {
      if (!(hasRookMoved[PieceColor.white]?['kingside'] ?? true)) {
        chess.castling[chess_lib.Color.WHITE] |=
            chess_lib.Chess.BITS_KSIDE_CASTLE; // 王翼易位
      }
      if (!(hasRookMoved[PieceColor.white]?['queenside'] ?? true)) {
        chess.castling[chess_lib.Color.WHITE] |=
            chess_lib.Chess.BITS_QSIDE_CASTLE; // 后翼易位
      }
    }

    // 黑方易位权限
    if (!(hasKingMoved[PieceColor.black] ?? true)) {
      if (!(hasRookMoved[PieceColor.black]?['kingside'] ?? true)) {
        chess.castling[chess_lib.Color.BLACK] |=
            chess_lib.Chess.BITS_KSIDE_CASTLE; // 王翼易位
      }
      if (!(hasRookMoved[PieceColor.black]?['queenside'] ?? true)) {
        chess.castling[chess_lib.Color.BLACK] |=
            chess_lib.Chess.BITS_QSIDE_CASTLE; // 后翼易位
      }
    }
  }

  /// 将 chess 包的棋盘状态转换为现有的棋盘格式
  static List<List<ChessPiece?>> fromChessLibBoard(chess_lib.Chess chess) {
    final board = List.generate(
      8,
      (row) => List.generate(8, (col) => null as ChessPiece?),
    );

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final square = toChessLibSquare(Position(row: row, col: col));
        final piece = chess.get(square);
        if (piece != null) {
          board[row][col] = fromChessLibPiece(piece);
        }
      }
    }

    return board;
  }

  /// 将 chess 包的移动转换为现有的 ChessMove
  static ChessMove fromChessLibMove(
      chess_lib.Move move, chess_lib.Chess chess) {
    final from = fromChessLibSquare(chess_lib.Chess.algebraic(move.from));
    final to = fromChessLibSquare(chess_lib.Chess.algebraic(move.to));

    // 获取移动的棋子 - 从棋盘上获取
    final pieceOnBoard = chess.board[move.from];
    if (pieceOnBoard == null) {
      throw ArgumentError('No piece found at move.from position');
    }
    final piece = fromChessLibPiece(pieceOnBoard);

    // 获取被吃的棋子 - 从目标位置获取
    ChessPiece? capturedPiece;
    final capturedPieceOnBoard = chess.board[move.to];
    if (capturedPieceOnBoard != null) {
      capturedPiece = fromChessLibPiece(capturedPieceOnBoard);
    }

    // 检查特殊移动
    final isPromotion = move.promotion != null;
    final promotionType =
        move.promotion != null ? fromChessLibPieceType(move.promotion!) : null;

    final isCastling = (move.flags & chess_lib.Chess.BITS_KSIDE_CASTLE) != 0 ||
        (move.flags & chess_lib.Chess.BITS_QSIDE_CASTLE) != 0;

    final isEnPassant = (move.flags & chess_lib.Chess.BITS_EP_CAPTURE) != 0;

    return ChessMove(
      from: from,
      to: to,
      piece: piece,
      capturedPiece: capturedPiece,
      isPromotion: isPromotion,
      promotionType: promotionType,
      isCastling: isCastling,
      isEnPassant: isEnPassant,
    );
  }

  /// 将现有的 ChessMove 转换为 chess 包可以理解的移动格式
  static Map<String, dynamic> toChessLibMoveMap(ChessMove move) {
    return {
      'from': toChessLibSquare(move.from),
      'to': toChessLibSquare(move.to),
      if (move.isPromotion && move.promotionType != null)
        'promotion': _pieceTypeToString(move.promotionType!),
    };
  }

  /// 将 PieceType 转换为字符串表示
  static String _pieceTypeToString(PieceType type) {
    switch (type) {
      case PieceType.queen:
        return 'q';
      case PieceType.rook:
        return 'r';
      case PieceType.bishop:
        return 'b';
      case PieceType.knight:
        return 'n';
      default:
        return 'q'; // 默认升变为后
    }
  }

  /// 获取所有合法移动
  static List<ChessMove> getLegalMoves(
    List<List<ChessPiece?>> board,
    PieceColor currentPlayer, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
    int halfMoveClock = 0,
    int fullMoveNumber = 1,
  }) {
    final chess = createChessFromBoard(
      board,
      currentPlayer,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
    );

    final moves = chess.generate_moves();
    return moves.map((move) => fromChessLibMove(move, chess)).toList();
  }

  /// 检查是否被将军
  static bool isInCheck(
    List<List<ChessPiece?>> board,
    PieceColor color, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    try {
      final chess = createChessFromBoard(
        board,
        color,
        hasKingMoved: hasKingMoved,
        hasRookMoved: hasRookMoved,
        enPassantTarget: enPassantTarget,
      );

      return chess.in_check;
    } catch (e) {
      // 如果检查将军时出现错误，记录错误信息并返回false
      print('警告：检查将军状态时出现错误: $e');
      return false; // 安全地返回false，避免崩溃
    }
  }

  /// 检查是否将死
  static bool isCheckmate(
    List<List<ChessPiece?>> board,
    PieceColor color, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    try {
      final chess = createChessFromBoard(
        board,
        color,
        hasKingMoved: hasKingMoved,
        hasRookMoved: hasRookMoved,
        enPassantTarget: enPassantTarget,
      );

      return chess.in_checkmate;
    } catch (e) {
      // 如果检查将死时出现错误，记录错误信息并返回false
      print('警告：检查将死状态时出现错误: $e');
      print('棋盘状态: ${board.map((row) => row.map((piece) => piece?.toString() ?? 'null').join(', ')).join('\n')}');
      print('当前玩家: $color');
      print('enPassantTarget: $enPassantTarget');
      return false; // 安全地返回false，避免崩溃
    }
  }

  /// 检查是否和棋
  static bool isStalemate(
    List<List<ChessPiece?>> board,
    PieceColor color, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    try {
      final chess = createChessFromBoard(
        board,
        color,
        hasKingMoved: hasKingMoved,
        hasRookMoved: hasRookMoved,
        enPassantTarget: enPassantTarget,
      );

      return chess.in_stalemate;
    } catch (e) {
      // 如果检查和棋时出现错误，记录错误信息并返回false
      print('警告：检查和棋状态时出现错误: $e');
      return false; // 安全地返回false，避免崩溃
    }
  }

  /// 检查是否游戏结束
  static bool isGameOver(
    List<List<ChessPiece?>> board,
    PieceColor color, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
  }) {
    final chess = createChessFromBoard(
      board,
      color,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
    );

    return chess.game_over;
  }
}
