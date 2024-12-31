import 'package:equatable/equatable.dart';
import '../screens/game_screen.dart';
import '../services/settings_service.dart';

enum PieceType {
  king,
  queen,
  bishop,
  knight,
  rook,
  pawn,
}

enum PieceColor {
  white,
  black,
}

class ChessPiece extends Equatable {
  final PieceType type;
  final PieceColor color;

  const ChessPiece({
    required this.type,
    required this.color,
  });

  @override
  List<Object?> get props => [type, color];
}

class Position extends Equatable {
  final int row;
  final int col;

  const Position({
    required this.row,
    required this.col,
  });

  @override
  List<Object?> get props => [row, col];
}

class ChessMove extends Equatable {
  final Position from;
  final Position to;
  final ChessPiece piece;
  final ChessPiece? capturedPiece;
  final bool isPromotion;
  final PieceType? promotionType;
  final bool isCastling;
  final bool isEnPassant;

  const ChessMove({
    required this.from,
    required this.to,
    required this.piece,
    this.capturedPiece,
    this.isPromotion = false,
    this.promotionType,
    this.isCastling = false,
    this.isEnPassant = false,
  });

  ChessMove copyWith({
    Position? from,
    Position? to,
    ChessPiece? piece,
    ChessPiece? capturedPiece,
    bool? isPromotion,
    PieceType? promotionType,
    bool? isCastling,
    bool? isEnPassant,
  }) {
    return ChessMove(
      from: from ?? this.from,
      to: to ?? this.to,
      piece: piece ?? this.piece,
      capturedPiece: capturedPiece ?? this.capturedPiece,
      isPromotion: isPromotion ?? this.isPromotion,
      promotionType: promotionType ?? this.promotionType,
      isCastling: isCastling ?? this.isCastling,
      isEnPassant: isEnPassant ?? this.isEnPassant,
    );
  }

  @override
  List<Object?> get props => [
    from,
    to,
    piece,
    capturedPiece,
    isPromotion,
    promotionType,
    isCastling,
    isEnPassant,
  ];

  Map<String, dynamic> toJson() {
    return {
      'from': {
        'row': from.row,
        'col': from.col,
      },
      'to': {
        'row': to.row,
        'col': to.col,
      },
      'piece': {
        'type': piece.type.toString(),
        'color': piece.color.toString(),
      },
      'capturedPiece': capturedPiece == null ? null : {
        'type': capturedPiece!.type.toString(),
        'color': capturedPiece!.color.toString(),
      },
      'isPromotion': isPromotion,
      'promotionType': promotionType?.toString(),
      'isCastling': isCastling,
      'isEnPassant': isEnPassant,
    };
  }

  factory ChessMove.fromJson(Map<String, dynamic> json) {
    return ChessMove(
      from: Position(
        row: json['from']['row'],
        col: json['from']['col'],
      ),
      to: Position(
        row: json['to']['row'],
        col: json['to']['col'],
      ),
      piece: ChessPiece(
        type: PieceType.values.firstWhere(
          (e) => e.toString() == json['piece']['type'],
        ),
        color: PieceColor.values.firstWhere(
          (e) => e.toString() == json['piece']['color'],
        ),
      ),
      capturedPiece: json['capturedPiece'] == null ? null : ChessPiece(
        type: PieceType.values.firstWhere(
          (e) => e.toString() == json['capturedPiece']['type'],
        ),
        color: PieceColor.values.firstWhere(
          (e) => e.toString() == json['capturedPiece']['color'],
        ),
      ),
      isPromotion: json['isPromotion'],
      promotionType: json['promotionType'] == null ? null : PieceType.values.firstWhere(
        (e) => e.toString() == json['promotionType'],
      ),
      isCastling: json['isCastling'],
      isEnPassant: json['isEnPassant'],
    );
  }
}

class GameState extends Equatable {
  static ChessPiece? _getInitialPiece(int row, int col) {
    if (row == 1) {
      return const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    } else if (row == 6) {
      return const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    } else if (row == 0 || row == 7) {
      final color = row == 0 ? PieceColor.black : PieceColor.white;
      if (col == 0 || col == 7) {
        return ChessPiece(type: PieceType.rook, color: color);
      } else if (col == 1 || col == 6) {
        return ChessPiece(type: PieceType.knight, color: color);
      } else if (col == 2 || col == 5) {
        return ChessPiece(type: PieceType.bishop, color: color);
      } else if (col == 3) {
        return ChessPiece(type: PieceType.queen, color: color);
      } else if (col == 4) {
        return ChessPiece(type: PieceType.king, color: color);
      }
    }
    return null;
  }

  final List<List<ChessPiece?>> board;
  final PieceColor currentPlayer;
  final Position? selectedPosition;
  final List<Position> validMoves;
  final Map<PieceColor, bool> hasKingMoved;
  final Map<PieceColor, Map<String, bool>> hasRookMoved;
  final Map<PieceColor, Position?> lastPawnDoubleMoved;
  final Map<PieceColor, int> lastPawnDoubleMovedNumber;
  final int currentMoveNumber;
  final List<ChessMove> moveHistory;
  final String? specialMoveMessage;
  final ChessMove? lastMove;
  final bool isCheck;
  final bool isCheckmate;
  final bool isStalemate;
  final List<GameState> undoStates;
  final List<GameState> redoStates;
  final bool hintMode;
  final bool isInteractive;
  final PieceColor? allowedPlayer;
  final GameMode gameMode;

  const GameState({
    required this.board,
    required this.currentPlayer,
    this.selectedPosition,
    this.validMoves = const [],
    required this.hasKingMoved,
    required this.hasRookMoved,
    required this.lastPawnDoubleMoved,
    required this.lastPawnDoubleMovedNumber,
    this.currentMoveNumber = 0,
    this.moveHistory = const [],
    this.specialMoveMessage,
    this.lastMove,
    this.isCheck = false,
    this.isCheckmate = false,
    this.isStalemate = false,
    this.undoStates = const [],
    this.redoStates = const [],
    this.hintMode = false,
    this.isInteractive = true,
    this.allowedPlayer,
    this.gameMode = GameMode.offline,
  });

  GameState copyWith({
    List<List<ChessPiece?>>? board,
    PieceColor? currentPlayer,
    Position? selectedPosition,
    List<Position>? validMoves,
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Map<PieceColor, Position?>? lastPawnDoubleMoved,
    Map<PieceColor, int>? lastPawnDoubleMovedNumber,
    int? currentMoveNumber,
    List<ChessMove>? moveHistory,
    String? specialMoveMessage,
    ChessMove? lastMove,
    bool? isCheck,
    bool? isCheckmate,
    bool? isStalemate,
    List<GameState>? undoStates,
    List<GameState>? redoStates,
    bool? hintMode,
    bool? isInteractive,
    PieceColor? allowedPlayer,
    GameMode? gameMode,
  }) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      selectedPosition: selectedPosition,
      validMoves: validMoves ?? this.validMoves,
      hasKingMoved: hasKingMoved ?? this.hasKingMoved,
      hasRookMoved: hasRookMoved ?? this.hasRookMoved,
      lastPawnDoubleMoved: lastPawnDoubleMoved ?? this.lastPawnDoubleMoved,
      lastPawnDoubleMovedNumber: lastPawnDoubleMovedNumber ?? this.lastPawnDoubleMovedNumber,
      currentMoveNumber: currentMoveNumber ?? this.currentMoveNumber,
      moveHistory: moveHistory ?? this.moveHistory,
      specialMoveMessage: specialMoveMessage ?? this.specialMoveMessage,
      lastMove: lastMove ?? this.lastMove,
      isCheck: isCheck ?? this.isCheck,
      isCheckmate: isCheckmate ?? this.isCheckmate,
      isStalemate: isStalemate ?? this.isStalemate,
      undoStates: undoStates ?? this.undoStates,
      redoStates: redoStates ?? this.redoStates,
      hintMode: hintMode ?? this.hintMode,
      isInteractive: isInteractive ?? this.isInteractive,
      allowedPlayer: allowedPlayer ?? this.allowedPlayer,
      gameMode: gameMode ?? this.gameMode,
    );
  }

  static Future<GameState> initialFromPrefs({
    bool hintMode = false,
    bool isInteractive = true,
    PieceColor? allowedPlayer,
    GameMode gameMode = GameMode.offline,
  }) async {
    final board = List.generate(8, (row) {
      return List.generate(8, (col) {
        return _getInitialPiece(row, col);
      });
    });

    return GameState(
      board: board,
      currentPlayer: PieceColor.white,
      hasKingMoved: const {
        PieceColor.white: false,
        PieceColor.black: false,
      },
      hasRookMoved: const {
        PieceColor.white: const {'kingside': false, 'queenside': false},
        PieceColor.black: const {'kingside': false, 'queenside': false},
      },
      lastPawnDoubleMoved: const {
        PieceColor.white: null,
        PieceColor.black: null,
      },
      lastPawnDoubleMovedNumber: const {
        PieceColor.white: -1,
        PieceColor.black: -1,
      },
      hintMode: hintMode,
      isInteractive: isInteractive,
      allowedPlayer: allowedPlayer,
      gameMode: gameMode,
    );
  }

  static GameState initial({bool hintMode = false}) {
    final board = List.generate(
      8,
      (i) => List.generate(8, (j) => null as ChessPiece?),
    );

    // 初始化白方棋子
    board[7][0] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
    board[7][1] = const ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[7][2] = const ChessPiece(type: PieceType.bishop, color: PieceColor.white);
    board[7][3] = const ChessPiece(type: PieceType.queen, color: PieceColor.white);
    board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
    board[7][5] = const ChessPiece(type: PieceType.bishop, color: PieceColor.white);
    board[7][6] = const ChessPiece(type: PieceType.knight, color: PieceColor.white);
    board[7][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.white);
    for (int i = 0; i < 8; i++) {
      board[6][i] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    }

    // 初始化黑方棋子
    board[0][0] = const ChessPiece(type: PieceType.rook, color: PieceColor.black);
    board[0][1] = const ChessPiece(type: PieceType.knight, color: PieceColor.black);
    board[0][2] = const ChessPiece(type: PieceType.bishop, color: PieceColor.black);
    board[0][3] = const ChessPiece(type: PieceType.queen, color: PieceColor.black);
    board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);
    board[0][5] = const ChessPiece(type: PieceType.bishop, color: PieceColor.black);
    board[0][6] = const ChessPiece(type: PieceType.knight, color: PieceColor.black);
    board[0][7] = const ChessPiece(type: PieceType.rook, color: PieceColor.black);
    for (int i = 0; i < 8; i++) {
      board[1][i] = const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    }

    return GameState(
      board: board,
      currentPlayer: PieceColor.white,
      hasKingMoved: const {
        PieceColor.white: false,
        PieceColor.black: false,
      },
      hasRookMoved: const {
        PieceColor.white: const {'kingside': false, 'queenside': false},
        PieceColor.black: const {'kingside': false, 'queenside': false},
      },
      lastPawnDoubleMoved: const {
        PieceColor.white: null,
        PieceColor.black: null,
      },
      lastPawnDoubleMovedNumber: const {
        PieceColor.white: -1,
        PieceColor.black: -1,
      },
      hintMode: hintMode,
    );
  }

  @override
  List<Object?> get props => [
    board,
    currentPlayer,
    selectedPosition,
    validMoves,
    hasKingMoved,
    hasRookMoved,
    lastPawnDoubleMoved,
    lastPawnDoubleMovedNumber,
    currentMoveNumber,
    moveHistory,
    specialMoveMessage,
    lastMove,
    isCheck,
    isCheckmate,
    isStalemate,
    undoStates,
    redoStates,
    hintMode,
    isInteractive,
    allowedPlayer,
    gameMode,
  ];
}