import 'dart:async';
import 'dart:js_util' as js_util;
import 'package:js/js.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../models/chess_models.dart';
import 'chess_adapter.dart';

/// JavaScript interop for Stockfish WebAssembly
@JS('Stockfish')
external dynamic stockfish;

/// Web端Stockfish WebAssembly适配器实现
class StockfishWebAdapter {
  static dynamic _stockfish;
  static bool _isInitialized = false;
  static final Completer<void> _initCompleter = Completer<void>();
  static final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  static String _lastOutput = '';

  /// 初始化Stockfish WebAssembly引擎
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('StockfishWebAdapter: 引擎已初始化');
      return;
    }

    try {
      print('StockfishWebAdapter: 开始初始化...');

      // 检查SharedArrayBuffer支持
      final hasSharedArrayBuffer = _checkSharedArrayBufferSupport();
      print('StockfishWebAdapter: SharedArrayBuffer支持: $hasSharedArrayBuffer');

      if (!hasSharedArrayBuffer) {
        print('StockfishWebAdapter: SharedArrayBuffer不可用，使用回退方案');
        await _initializeFallback();
        return;
      }

      // 检查是否支持WebAssembly
      if (stockfish == null) {
        throw UnsupportedError('Stockfish WebAssembly is not available');
      }

      // 调用官方Stockfish()构造函数，它返回一个Promise
      print('StockfishWebAdapter: 调用Stockfish()构造函数...');
      final stockfishPromise = stockfish();

      // 等待Promise解析
      print('StockfishWebAdapter: 等待Stockfish实例初始化...');
      _stockfish = await _promiseToFuture(stockfishPromise);
      print('StockfishWebAdapter: Stockfish实例创建成功');

      // 设置消息监听器
      js_util.callMethod(_stockfish, 'addMessageListener', [
        allowInterop((String message) {
          print('Stockfish: $message');
          _lastOutput = message;
          _outputController.add(message);

          // 检查是否准备就绪
          if (message.contains('uciok') || message.contains('readyok')) {
            if (!_initCompleter.isCompleted) {
              print('StockfishWebAdapter: 引擎准备就绪');
              _initCompleter.complete();
            }
          }
        })
      ]);

      // 初始化UCI协议
      print('StockfishWebAdapter: 发送UCI命令...');
      js_util.callMethod(_stockfish, 'postMessage', ['uci']);
      await Future.delayed(const Duration(milliseconds: 500));
      js_util.callMethod(_stockfish, 'postMessage', ['isready']);

      // 等待引擎准备就绪
      await _initCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Stockfish WebAssembly engine failed to initialize');
        },
      );

      _isInitialized = true;
      print('StockfishWebAdapter: 初始化完成');
    } catch (e) {
      print('StockfishWebAdapter: 初始化失败: $e');
      print('StockfishWebAdapter: 尝试使用回退方案...');
      try {
        await _initializeFallback();
      } catch (fallbackError) {
        print('StockfishWebAdapter: 回退方案也失败: $fallbackError');
        _isInitialized = false;
        if (_stockfish != null) {
          try {
            js_util.callMethod(_stockfish, 'terminate', []);
          } catch (_) {}
          _stockfish = null;
        }
        rethrow;
      }
    }
  }

  /// 将JavaScript Promise转换为Dart Future
  static Future<dynamic> _promiseToFuture(dynamic promise) {
    final completer = Completer<dynamic>();

    // 设置then回调
    js_util.callMethod(promise, 'then', [
      allowInterop((result) {
        print('StockfishWebAdapter: Promise resolved with result');
        completer.complete(result);
      })
    ]);

    // 设置catch回调
    js_util.callMethod(promise, 'catch', [
      allowInterop((error) {
        print('StockfishWebAdapter: Promise rejected with error: $error');
        completer.completeError(error);
      })
    ]);

    return completer.future;
  }

  /// 检查SharedArrayBuffer支持
  static bool _checkSharedArrayBufferSupport() {
    try {
      return js_util.hasProperty(js_util.globalThis, 'SharedArrayBuffer');
    } catch (e) {
      return false;
    }
  }

  /// 回退初始化（使用简化的AI引擎）
  static Future<void> _initializeFallback() async {
    print('StockfishWebAdapter: 使用回退AI引擎');

    // 创建一个简化的AI引擎模拟器
    _stockfish = _createFallbackEngine();

    // 模拟初始化过程
    await Future.delayed(const Duration(milliseconds: 500));

    _isInitialized = true;
    print('StockfishWebAdapter: 回退AI引擎初始化完成');

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  /// 创建回退AI引擎
  static dynamic _createFallbackEngine() {
    return {
      'postMessage': allowInterop((String command) {
        print('FallbackAI: 收到命令: $command');
        _handleFallbackCommand(command);
      }),
      'addMessageListener': allowInterop((Function callback) {
        // 存储回调以便后续使用
        print('FallbackAI: 添加消息监听器');
      }),
      'terminate': allowInterop(() {
        print('FallbackAI: 终止');
      })
    };
  }

  /// 处理回退引擎命令
  static String? _currentPosition;

  static void _handleFallbackCommand(String command) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (command == 'uci') {
        _outputController.add('id name Fallback Chess AI');
        _outputController.add('id author Flutter Chess App');
        _outputController.add('uciok');
      } else if (command == 'isready') {
        _outputController.add('readyok');
      } else if (command.startsWith('position')) {
        // 存储位置信息用于生成合法移动
        _currentPosition = command;
        print('FallbackAI: 设置位置: $command');
      } else if (command.startsWith('go movetime')) {
        // 根据当前位置生成合法移动
        final move = _generateFallbackMove(_currentPosition);
        Future.delayed(const Duration(milliseconds: 800), () {
          _outputController.add('bestmove $move');
        });
      }
    });
  }

  /// 生成回退移动
  static String _generateFallbackMove(String? positionCommand) {
    try {
      // 尝试解析当前位置并生成合法移动
      if (positionCommand != null && positionCommand.contains('fen')) {
        return _generateLegalMove(positionCommand);
      }
    } catch (e) {
      print('FallbackAI: 无法解析位置，使用默认移动: $e');
    }

    // 基本的开局移动列表
    final commonMoves = [
      'e2e4',
      'd2d4',
      'g1f3',
      'c2c4',
      'e7e5',
      'd7d5',
      'g8f6',
      'c7c5',
      'b1c3',
      'f1c4',
      'f8c5',
      'b8c6',
      'e1g1',
      'e8g8',
      'a2a3',
      'a7a6'
    ];

    // 随机选择一个移动
    final random = DateTime.now().millisecondsSinceEpoch % commonMoves.length;
    return commonMoves[random];
  }

  /// 根据FEN位置生成合法移动
  static String _generateLegalMove(String positionCommand) {
    try {
      // 提取FEN字符串 - 修复正则表达式以获取完整的FEN
      final fenMatch = RegExp(r'fen (.+)$').firstMatch(positionCommand);
      if (fenMatch == null) {
        throw Exception('No FEN found in position command');
      }

      final fen = fenMatch.group(1)!.trim();
      print('FallbackAI: 解析FEN: $fen');

      // 验证FEN格式（应该有至少6个字段）
      final fenParts = fen.split(' ');
      if (fenParts.length < 6) {
        print('FallbackAI: 不完整的FEN格式，字段数: ${fenParts.length}');
        // 尝试使用基本的默认格式
        final basicFen = fenParts[0] + ' b - - 0 1'; // 默认为黑方移动
        print('FallbackAI: 使用补全的FEN: $basicFen');
        return _generateMoveFromFen(basicFen);
      }

      return _generateMoveFromFen(fen);
    } catch (e) {
      print('FallbackAI: 生成合法移动失败: $e');
      // 返回一个基本的移动
      return _getRandomBasicMove();
    }
  }

  /// 从完整的FEN字符串生成移动
  static String _generateMoveFromFen(String fen) {
    try {
      // 使用chess包生成合法移动
      final chess = chess_lib.Chess.fromFEN(fen);
      final moves = chess.moves({'verbose': true}) as List;

      if (moves.isEmpty) {
        print('FallbackAI: 没有合法移动，游戏结束');
        return '(none)';
      }

      // 选择一个随机的合法移动
      final random = DateTime.now().millisecondsSinceEpoch % moves.length;
      final selectedMove = moves[random];

      // 构造UCI格式的移动
      String uciMove = selectedMove['from'] + selectedMove['to'];
      if (selectedMove['promotion'] != null) {
        uciMove += selectedMove['promotion'];
      }

      print('FallbackAI: 生成合法移动: $uciMove');
      return uciMove;
    } catch (e) {
      print('FallbackAI: FEN解析失败: $e');
      return _getRandomBasicMove();
    }
  }

  /// 获取随机基本移加
  static String _getRandomBasicMove() {
    // 基本的开局移动列表
    final commonMoves = [
      'e7e5',
      'd7d5',
      'g8f6',
      'c7c5',
      'b8c6',
      'f8c5',
      'e8g8',
      'a7a6',
      'h7h6',
      'b7b6',
      'f7f6',
      'g7g6',
      'h7h5',
      'a7a5'
    ];

    final random = DateTime.now().millisecondsSinceEpoch % commonMoves.length;
    final move = commonMoves[random];
    print('FallbackAI: 使用默认移动: $move');
    return move;
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
      print('StockfishWebAdapter: 开始获取最佳移动...');

      if (!_isInitialized) {
        print('StockfishWebAdapter: 引擎未初始化，正在初始化...');
        await initialize();
      }

      if (_stockfish == null) {
        throw StateError('Stockfish WebAssembly engine is not initialized');
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

      if (chess.game_over) {
        print('StockfishWebAdapter: 游戏已结束');
        return null;
      }

      final fen = chess.fen;
      print('StockfishWebAdapter: FEN位置: $fen');

      // 发送位置到Stockfish
      print('StockfishWebAdapter: 发送位置到Stockfish...');
      if (_stockfish is Map) {
        // 回退引擎是一个Dart Map
        final postMessage = _stockfish['postMessage'] as Function;
        postMessage('position fen $fen');
      } else {
        // 官方Stockfish WebAssembly
        js_util.callMethod(_stockfish, 'postMessage', ['position fen $fen']);
      }
      await Future.delayed(const Duration(milliseconds: 100));

      // 请求最佳移动
      print('StockfishWebAdapter: 请求最佳移动，思考时间: ${thinkingTimeMs}ms');
      if (_stockfish is Map) {
        // 回退引擎是一个Dart Map
        final postMessage = _stockfish['postMessage'] as Function;
        postMessage('go movetime $thinkingTimeMs');
      } else {
        // 官方Stockfish WebAssembly
        js_util.callMethod(
            _stockfish, 'postMessage', ['go movetime $thinkingTimeMs']);
      }

      // 等待结果
      final bestMoveUci = await _waitForBestMove();
      print('StockfishWebAdapter: 收到UCI移动: $bestMoveUci');

      if (bestMoveUci == null || bestMoveUci == '(none)') {
        print('StockfishWebAdapter: 没有找到有效移动');
        return null;
      }

      // 将UCI移动转换为ChessMove
      final chessMove = _convertUciToChessMove(bestMoveUci, chess);
      print('StockfishWebAdapter: 转换后的移动: $chessMove');
      return chessMove;
    } catch (e) {
      print('StockfishWebAdapter: 获取最佳移动错误: $e');
      // 尝试重新初始化
      try {
        print('StockfishWebAdapter: 尝试重新初始化...');
        await dispose();
        await initialize();
      } catch (initError) {
        print('Failed to reinitialize Stockfish WebAssembly: $initError');
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
      try {
        if (_stockfish is Map) {
          // 回退引擎是一个Dart Map
          final terminate = _stockfish['terminate'] as Function;
          terminate();
        } else {
          // 官方Stockfish WebAssembly
          js_util.callMethod(_stockfish, 'terminate', []);
        }
      } catch (e) {
        print('Error terminating Stockfish: $e');
      }
      _stockfish = null;
    }
    _isInitialized = false;
  }

  /// 检查引擎是否准备就绪
  static bool get isReady => _isInitialized && _stockfish != null;
}

// 导出平台特定的API
Future<void> initialize() => StockfishWebAdapter.initialize();
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
    StockfishWebAdapter.getBestMove(
      board,
      aiColor,
      hasKingMoved: hasKingMoved,
      hasRookMoved: hasRookMoved,
      enPassantTarget: enPassantTarget,
      halfMoveClock: halfMoveClock,
      fullMoveNumber: fullMoveNumber,
      thinkingTimeMs: thinkingTimeMs,
    );
Future<void> dispose() => StockfishWebAdapter.dispose();
bool get isReady => StockfishWebAdapter.isReady;
