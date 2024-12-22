import '../models/chess_models.dart';
import '../screens/game_screen.dart';

class ChessLocalizations {
  final String locale;

  ChessLocalizations(this.locale);

  static final Map<String, ChessLocalizations> _cache = {};

  factory ChessLocalizations.of(String locale) {
    return _cache.putIfAbsent(locale, () => ChessLocalizations(locale));
  }

  String getGameModeTitle(GameMode gameMode) {
    switch (locale) {
      case 'zh':
        switch (gameMode) {
          case GameMode.offline:
            return '单机对战';
          case GameMode.online:
            return '联网对战';
          case GameMode.faceToFace:
            return '面对面对战';
        }
      case 'en':
        switch (gameMode) {
          case GameMode.offline:
            return 'Offline Game';
          case GameMode.online:
            return 'Online Game';
          case GameMode.faceToFace:
            return 'Face to Face';
        }
      default:
        return getGameModeTitle(gameMode); // 默认使用中文
    }
  }

  String getPieceTypeName(PieceType type) {
    switch (locale) {
      case 'zh':
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
      case 'en':
        switch (type) {
          case PieceType.king:
            return "King";
          case PieceType.queen:
            return "Queen";
          case PieceType.bishop:
            return "Bishop";
          case PieceType.knight:
            return "Knight";
          case PieceType.rook:
            return "Rook";
          case PieceType.pawn:
            return "Pawn";
        }
      default:
        return getPieceTypeName(type); // 默认使用中文
    }
  }

  String get currentTurn => locale == 'en' ? 'Current Turn' : '当前回合';
  String get white => locale == 'en' ? 'White' : '白方';
  String get black => locale == 'en' ? 'Black' : '黑方';
  String get undo => locale == 'en' ? 'Undo' : '前一步';
  String get redo => locale == 'en' ? 'Redo' : '后一步';
  String get hintOn => locale == 'en' ? 'Hide Hints' : '关闭提示';
  String get hintOff => locale == 'en' ? 'Show Hints' : '开启提示';
  String get choosePromotion => locale == 'en' ? 'Choose Promotion' : '选择升变棋子';

  String buildMoveMessage(ChessMove move) {
    final pieceColor = move.piece.color == PieceColor.white ? white : black;
    final pieceType = getPieceTypeName(move.piece.type);

    if (move.capturedPiece != null) {
      final capturedColor = move.capturedPiece!.color == PieceColor.white ? white : black;
      final capturedType = getPieceTypeName(move.capturedPiece!.type);

      return locale == 'en'
          ? '$pieceColor $pieceType captures $capturedColor $capturedType'
          : '$pieceColor$pieceType吃掉$capturedColor$capturedType';
    } else {
      return locale == 'en'
          ? '$pieceColor $pieceType moves'
          : '$pieceColor$pieceType移动';
    }
  }

  String buildPromotionMessage(ChessMove move) {
    final pieceColor = move.piece.color == PieceColor.white ? white : black;

    return locale == 'en'
        ? '$pieceColor Pawn promotes to ${getPieceTypeName(move.promotionType!)}'
        : '$pieceColor兵升变为${getPieceTypeName(move.promotionType!)}';
  }
}