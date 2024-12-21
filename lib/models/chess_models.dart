import 'package:equatable/equatable.dart';

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
}

class GameState extends Equatable {
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
      specialMoveMessage: specialMoveMessage,
      lastMove: lastMove,
    );
  }

  static GameState initial() {
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
      hasKingMoved: {
        PieceColor.white: false,
        PieceColor.black: false,
      },
      hasRookMoved: {
        PieceColor.white: {'kingside': false, 'queenside': false},
        PieceColor.black: {'kingside': false, 'queenside': false},
      },
      lastPawnDoubleMoved: {
        PieceColor.white: null,
        PieceColor.black: null,
      },
      lastPawnDoubleMovedNumber: {
        PieceColor.white: -1,
        PieceColor.black: -1,
      },
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
  ];
} 