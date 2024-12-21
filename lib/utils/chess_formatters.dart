import '../models/chess_models.dart';
import '../screens/game_screen.dart';

class ChessFormatters {
  static String getGameModeTitle(GameMode gameMode) {
    switch (gameMode) {
      case GameMode.offline:
        return '单机对战';
      case GameMode.online:
        return '联网对战';
      case GameMode.faceToFace:
        return '面对面对战';
    }
  }

  static String getPieceImage(ChessPiece piece) {
    final color = piece.color == PieceColor.white ? 'white' : 'black';
    final type = piece.type.toString().split('.').last;
    return 'assets/images/${color}_$type.png';
  }

  static String getPositionName(Position position) {
    final col = String.fromCharCode('A'.codeUnitAt(0) + position.col);
    final row = 8 - position.row;
    return '$col$row';
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
    final pieceColor = move.piece.color == PieceColor.white ? "白方" : "黑方";
    final pieceType = getPieceTypeName(move.piece.type);
    final from = getPositionName(move.from);
    final to = getPositionName(move.to);

    if (move.capturedPiece != null) {
      final capturedColor = move.capturedPiece!.color == PieceColor.white ? "白方" : "黑方";
      final capturedType = getPieceTypeName(move.capturedPiece!.type);
      return '$pieceColor$pieceType($from)吃掉$capturedColor$capturedType($to)';
    } else {
      return '$pieceColor$pieceType从$from移动到$to';
    }
  }
} 