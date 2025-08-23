import 'dart:async';
import 'package:stockfish_chess_engine/stockfish_chess_engine.dart';
import 'package:stockfish_chess_engine/stockfish_chess_engine_state.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../models/chess_models.dart';
import 'chess_adapter.dart';

/// 移动端Stockfish引擎适配器实现
class StockfishMobileAdapter {
  static Stockfish? _stockfish;
  static StreamSubscription<String>? _outputSubscription;
  static StreamSubscription<String>? _errorSubscription;
  static final Completer<void> _initCompleter = Completer<void>();
  static bool _isInitialized = false;
  static String _lastOutput = '';
  static final StreamController<String> _outputController =
      StreamController<String>.broadcast();

  /// 初始化Stockfish引擎
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _stockfish = Stockfish();

      // 监听输出
      _outputSubscription = _stockfish!.stdout.listen((output) {
        _lastOutput = output;
        _outputController.add(output);
      });

      // 监听错误
      _errorSubscription = _stockfish!.stderr.listen((error) {
        // 在测试环境中可能会有错误，这是正常的
      });

      // 等待引擎准备就绪
      await _waitForReady();

      // 初始化UCI协议
      _stockfish!.stdin = 'uci';
      await Future.delayed(const Duration(milliseconds: 500));
      _stockfish!.stdin = 'isready';
      await Future.delayed(const Duration(milliseconds: 500));

      _isInitialized = true;
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      // 清理资源
      _stockfish = null;
      _isInitialized = false;

      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
      rethrow;
    }
  }

  /// 等待引擎准备就绪
  static Future<void> _waitForReady() async {
    const maxWaitTime = Duration(seconds: 10);
    const checkInterval = Duration(milliseconds: 100);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      if (_stockfish!.state.value == StockfishState.ready) {
        return;
      }
      await Future.delayed(checkInterval);
    }

    throw TimeoutException('Stockfish engine failed to start within timeout');
  }

  /// 获取AI的最佳移动
  static Future<ChessMove?> getBestMove(
    List<List<ChessPiece?>> board,
    PieceColor aiColor, {
    Map<PieceColor, bool>? hasKingMoved,
    Map<PieceColor, Map<String, bool>>? hasRookMoved,
    Position? enPassantTarget,
    int halfMoveClock = 0,
    int fullMoveNumber = 1,
    int thinkingTimeMs = 1000,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // 检查引擎状态
      if (_stockfish == null ||
          _stockfish!.state.value != StockfishState.ready) {
        // 重新初始化引擎
        await dispose();
        await initialize();
      }

      // 使用chess包创建FEN字符串
      final chess = ChessAdapter.createChessFromBoard(
        board,
        aiColor,
        hasKingMoved: hasKingMoved,
        hasRookMoved: hasRookMoved,
        enPassantTarget: enPassantTarget,
        halfMoveClock: halfMoveClock,
        fullMoveNumber: fullMoveNumber,
      );

      if (chess.game_over) return null;

      final fen = chess.fen;

      // 发送位置到Stockfish
      _stockfish!.stdin = 'position fen $fen';
      await Future.delayed(const Duration(milliseconds: 100));

      // 请求最佳移动
      _stockfish!.stdin = 'go movetime $thinkingTimeMs';

      // 等待结果
      final bestMoveUci = await _waitForBestMove();
      if (bestMoveUci == null || bestMoveUci == '(none)') return null;

      // 将UCI移动转换为ChessMove
      return _convertUciToChessMove(bestMoveUci, chess);
    } catch (e) {
      // 如果出错，尝试重新初始化引擎
      try {
        await dispose();
        await initialize();
      } catch (initError) {
        // 初始化失败，返回null
      }
      return null;
    }
  }

  /// 等待Stockfish返回最佳移动
  static Future<String?> _waitForBestMove() async {
    const maxWaitTime = Duration(seconds: 30);

    try {
      // 使用Stream监听来等待bestmove输出
      await for (final output
          in _outputController.stream.timeout(maxWaitTime)) {
        if (output.startsWith('bestmove')) {
          final parts = output.split(' ');
          if (parts.length >= 2) {
            return parts[1];
          }
        }
      }
    } on TimeoutException {
      // 超时，返回null
      return null;
    } catch (e) {
      // 其他错误，返回null
      return null;
    }

    return null;
  }

  /// 将UCI格式的移动转换为ChessMove
  static ChessMove? _convertUciToChessMove(
      String uciMove, chess_lib.Chess chess) {
    if (uciMove.length < 4) return null;

    try {
      // 解析UCI移动格式 (例如: "e2e4", "e7e8q")
      final fromSquare = uciMove.substring(0, 2);
      final toSquare = uciMove.substring(2, 4);
      final promotion = uciMove.length > 4 ? uciMove.substring(4) : null;

      final from = ChessAdapter.fromChessLibSquare(fromSquare);
      final to = ChessAdapter.fromChessLibSquare(toSquare);

      // 获取移动的棋子
      final fromIndex = chess_lib.Chess.SQUARES[fromSquare];
      final piece = chess.board[fromIndex!];
      if (piece == null) return null;

      final chessPiece = ChessAdapter.fromChessLibPiece(piece);

      // 获取被吃的棋子
      final toIndex = chess_lib.Chess.SQUARES[toSquare];
      final capturedPiece = chess.board[toIndex!];
      final capturedChessPiece = capturedPiece != null
          ? ChessAdapter.fromChessLibPiece(capturedPiece)
          : null;

      // 处理升变
      PieceType? promotionType;
      if (promotion != null) {
        switch (promotion.toLowerCase()) {
          case 'q':
            promotionType = PieceType.queen;
            break;
          case 'r':
            promotionType = PieceType.rook;
            break;
          case 'b':
            promotionType = PieceType.bishop;
            break;
          case 'n':
            promotionType = PieceType.knight;
            break;
        }
      }

      // 检查特殊移动
      // 由于chess包没有Move.fromUci方法，我们需要手动检查特殊移动
      final isPromotion = promotion != null;

      // 检查是否是易位
      final fromPiece = chess.board[chess_lib.Chess.SQUARES[fromSquare]!];
      final isCastling = fromPiece?.type == chess_lib.Chess.KING &&
              (fromSquare == 'e1' && (toSquare == 'g1' || toSquare == 'c1')) ||
          (fromSquare == 'e8' && (toSquare == 'g8' || toSquare == 'c8'));

      // 检查是否是吃过路兵
      final isEnPassant = fromPiece?.type == chess_lib.Chess.PAWN &&
          capturedPiece == null &&
          fromSquare[0] != toSquare[0]; // 斜向移动但没有吃子

      return ChessMove(
        from: from,
        to: to,
        piece: chessPiece,
        capturedPiece: capturedChessPiece,
        isPromotion: isPromotion,
        promotionType: promotionType,
        isCastling: isCastling,
        isEnPassant: isEnPassant,
      );
    } catch (e) {
      print('Error converting UCI move $uciMove: $e');
      return null;
    }
  }

  /// 释放资源
  static Future<void> dispose() async {
    if (_stockfish != null) {
      await _outputSubscription?.cancel();
      await _errorSubscription?.cancel();
      _stockfish!.dispose();
      _stockfish = null;
    }
    _outputSubscription = null;
    _errorSubscription = null;
    _isInitialized = false;
  }

  /// 检查引擎是否准备就绪
  static bool get isReady =>
      _isInitialized && _stockfish?.state.value == StockfishState.ready;
}

// 导出平台特定的API
Future<void> initialize() => StockfishMobileAdapter.initialize();
Future<ChessMove?> getBestMove(
  List<List<ChessPiece?>> board,
  PieceColor aiColor, {
  Map<PieceColor, bool>? hasKingMoved,
  Map<PieceColor, Map<String, bool>>? hasRookMoved,
  Position? enPassantTarget,
  int halfMoveClock = 0,
  int fullMoveNumber = 1,
  int thinkingTimeMs = 1000,
}) =>
    StockfishMobileAdapter.getBestMove(
      board,
      aiColor,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
      thinkingTimeMs: thinkingTimeMs,
    );
Future<void> dispose() => StockfishMobileAdapter.dispose();
bool get isReady => StockfishMobileAdapter.isReady;
