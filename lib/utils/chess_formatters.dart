import '../models/chess_models.dart';
import '../screens/game_screen.dart';

class ChessFormatters {
  static String getGameModeTitle(GameMode gameMode) {
    switch (gameMode) {
      case GameMode.offline:
        return 'AI 对战';
      case GameMode.online:
        return '联网对战';
      case GameMode.faceToFace:
        return '面对面对战';
      case GameMode.endgamePractice:
        return '残局练习';
    }
  }

  static String getPieceImage(ChessPiece piece) {
    final color = piece.color == PieceColor.white ? 'white' : 'black';
    final type = piece.type.toString().split('.').last;
    return 'assets/images/${color}_$type.png';
  }

  static String getPositionName(Position position) {
    // 添加坐标验证以防止超出范围的索引
    if (position.col < 0 ||
        position.col > 7 ||
        position.row < 0 ||
        position.row > 7) {
      // 如果坐标异常，返回一个错误指示，并记录详细信息用于调试
      print(
          '警告：getPositionName收到无效坐标: row=${position.row}, col=${position.col}');
      return '无效位置(${position.row},${position.col})';
    }

    // 添加额外的安全检查，防止String.fromCharCode出现异常
    try {
      final col = String.fromCharCode('A'.codeUnitAt(0) + position.col);
      final row = 8 - position.row;
      return '$col$row';
    } catch (e) {
      print(
          '错误：getPositionName计算失败: row=${position.row}, col=${position.col}, 错误: $e');
      return '计算错误(${position.row},${position.col})';
    }
  }

  static String getPieceTypeName(PieceType type) {
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

  static String buildDefaultMoveMessage(ChessMove move) {
    final from = getPositionName(move.from);
    final to = getPositionName(move.to);
    final pieceColor = move.piece.color == PieceColor.white ? "白方" : "黑方";
    final pieceName = getPieceTypeName(move.piece.type);

    if (move.isCastling) {
      return '$pieceColor${move.from.col > move.to.col ? "王后" : "王翼"}易位';
    } else if (move.isEnPassant) {
      return '$pieceColor兵吃过路兵：$from → $to';
    } else {
      final captureText = move.capturedPiece != null ? "吃" : "→";
      return '$pieceColor$pieceName：$from $captureText $to';
    }
  }

  static String buildMoveStateMessage(GameState state) {
    if (state.isCheckmate) {
      return ' 将死！${state.currentPlayer == PieceColor.white ? "黑方" : "白方"}获胜！';
    } else if (state.isCheck) {
      return ' 将军！';
    } else if (state.isStalemate) {
      return ' 和棋！';
    }
    return '';
  }

  static String getRowLabel(int row, {bool isFlipped = false}) {
    return '${isFlipped ? (row + 1) : (8 - row)}';
  }

  static String getColumnLabel(int col, {bool isFlipped = false}) {
    final colIndex = isFlipped ? (7 - col) : col;
    // 添加坐标验证以防止超出范围的索引
    if (colIndex < 0 || colIndex > 7) {
      return '?'; // 返回一个安全的默认值
    }
    return String.fromCharCode('A'.codeUnitAt(0) + colIndex);
  }
}
