@JS()
library stockfish_web;

import 'dart:async';
import 'dart:js_interop';
import 'package:js/js.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../models/chess_models.dart';
import 'chess_adapter.dart';

/// JavaScript interop for Stockfish WebAssembly
@JS('Module')
external JSObject get wasmModule;

@JS('window.Stockfish')
external JSFunction get stockfishConstructor;

@JS()
@anonymous
class StockfishInstance {
  external void postMessage(String message);
  external set onmessage(JSFunction callback);
  external void terminate();
}

@JS('Worker')
external StockfishInstance createWorker(String scriptPath);

/// Web端Stockfish WebAssembly适配器
class StockfishWebAdapter {
  static StockfishInstance? _stockfish;
  static bool _isInitialized = false;
  static final Completer<void> _initCompleter = Completer<void>();
  static final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  static String _lastOutput = '';

  /// 初始化Stockfish WebAssembly引擎
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 检查是否支持WebAssembly
      if (!_isWasmSupported()) {
        throw UnsupportedError('WebAssembly is not supported in this browser');
      }

      // 创建Stockfish Worker
      _stockfish = createWorker('stockfish/stockfish.js');

      // 设置消息监听器
      _stockfish!.onmessage = allowInterop((event) {
        final String message = (event as JSObject)['data'] as String;
        _lastOutput = message;
        _outputController.add(message);

        // 检查是否准备就绪
        if (message.contains('uciok') || message.contains('readyok')) {
          if (!_initCompleter.isCompleted) {
            _initCompleter.complete();
          }
        }
      });

      // 初始化UCI协议
      _stockfish!.postMessage('uci');
      await Future.delayed(const Duration(milliseconds: 500));
      _stockfish!.postMessage('isready');

      // 等待引擎准备就绪
      await _initCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Stockfish engine failed to initialize');
        },
      );

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      _stockfish?.terminate();
      _stockfish = null;
      rethrow;
    }
  }

  /// 检查浏览器是否支持WebAssembly
  static bool _isWasmSupported() {
    try {
      // 简单的WebAssembly支持检测
      return js_interop.globalContext.has('WebAssembly');
    } catch (e) {
      return false;
    }
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

      if (_stockfish == null) {
        throw StateError('Stockfish engine is not initialized');
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
      _stockfish!.postMessage('position fen $fen');
      await Future.delayed(const Duration(milliseconds: 100));

      // 请求最佳移动
      _stockfish!.postMessage('go movetime $thinkingTimeMs');

      // 等待结果
      final bestMoveUci = await _waitForBestMove();
      if (bestMoveUci == null || bestMoveUci == '(none)') return null;

      // 将UCI移动转换为ChessMove
      return _convertUciToChessMove(bestMoveUci, chess);
    } catch (e) {
      print('Stockfish WebAssembly error: $e');
      // 尝试重新初始化
      try {
        await dispose();
        await initialize();
      } catch (initError) {
        print('Failed to reinitialize Stockfish: $initError');
      }
      return null;
    }
  }

  /// 等待Stockfish返回最佳移动
  static Future<String?> _waitForBestMove() async {
    const maxWaitTime = Duration(seconds: 30);

    try {
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
      return null;
    } catch (e) {
      print('Error waiting for best move: $e');
      return null;
    }

    return null;
  }

  /// 将UCI格式的移动转换为ChessMove
  static ChessMove? _convertUciToChessMove(
      String uciMove, chess_lib.Chess chess) {
    if (uciMove.length < 4) return null;

    try {
      final fromSquare = uciMove.substring(0, 2);
      final toSquare = uciMove.substring(2, 4);
      final promotion = uciMove.length > 4 ? uciMove.substring(4) : null;

      final from = ChessAdapter.fromChessLibSquare(fromSquare);
      final to = ChessAdapter.fromChessLibSquare(toSquare);

      final fromIndex = chess_lib.Chess.SQUARES[fromSquare];
      final piece = chess.board[fromIndex!];
      if (piece == null) return null;

      final chessPiece = ChessAdapter.fromChessLibPiece(piece);

      final toIndex = chess_lib.Chess.SQUARES[toSquare];
      final capturedPiece = chess.board[toIndex!];
      final capturedChessPiece = capturedPiece != null
          ? ChessAdapter.fromChessLibPiece(capturedPiece)
          : null;

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

      final isPromotion = promotion != null;
      final fromPiece = chess.board[chess_lib.Chess.SQUARES[fromSquare]!];
      final isCastling = fromPiece?.type == chess_lib.Chess.KING &&
              (fromSquare == 'e1' && (toSquare == 'g1' || toSquare == 'c1')) ||
          (fromSquare == 'e8' && (toSquare == 'g8' || toSquare == 'c8'));

      final isEnPassant = fromPiece?.type == chess_lib.Chess.PAWN &&
          capturedPiece == null &&
          fromSquare[0] != toSquare[0];

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
      _stockfish!.terminate();
      _stockfish = null;
    }
    _isInitialized = false;
  }

  /// 检查引擎是否准备就绪
  static bool get isReady => _isInitialized && _stockfish != null;
}
