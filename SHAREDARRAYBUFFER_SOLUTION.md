# SharedArrayBuffer 回退方案实现

## 问题描述

在Web环境中使用Stockfish WebAssembly时遇到：
```
StockfishWebAdapter: 初始化失败: ReferenceError: SharedArrayBuffer is not defined
```

这是因为现代浏览器出于安全考虑默认禁用了SharedArrayBuffer。

## 解决方案

### 1. 检测SharedArrayBuffer支持

```dart
static bool _checkSharedArrayBufferSupport() {
  try {
    return js_util.hasProperty(js_util.globalThis, 'SharedArrayBuffer');
  } catch (e) {
    return false;
  }
}
```

### 2. 回退AI引擎

当SharedArrayBuffer不可用时，使用自定义的简化AI引擎：

#### 核心特性：
- **合法移动生成**：使用chess包分析当前棋盘状态，生成合法移动
- **UCI协议兼容**：完全兼容UCI命令，包括`uci`、`isready`、`position`、`go`
- **FEN解析**：能够解析position命令中的FEN字符串
- **智能选择**：从所有合法移动中随机选择

#### 关键实现：

```dart
// 创建回退引擎
static dynamic _createFallbackEngine() {
  return {
    'postMessage': allowInterop((String command) {
      _handleFallbackCommand(command);
    }),
    'addMessageListener': allowInterop((Function callback) {
      // 存储消息监听器
    }),
    'terminate': allowInterop(() {
      // 清理资源
    })
  };
}

// 生成合法移动
static String _generateLegalMove(String positionCommand) {
  final fenMatch = RegExp(r'fen (.+?)(?:\s|$)').firstMatch(positionCommand);
  final fen = fenMatch.group(1)!;
  
  final chess = chess_lib.Chess.fromFEN(fen);
  final moves = chess.moves({'verbose': true}) as List;
  
  if (moves.isEmpty) return '(none)';
  
  final selectedMove = moves[random % moves.length];
  String uciMove = selectedMove['from'] + selectedMove['to'];
  if (selectedMove['promotion'] != null) {
    uciMove += selectedMove['promotion'];
  }
  
  return uciMove;
}
```

### 3. 完整的初始化流程

```dart
static Future<void> initialize() async {
  try {
    // 首先检查SharedArrayBuffer支持
    final hasSharedArrayBuffer = _checkSharedArrayBufferSupport();
    
    if (!hasSharedArrayBuffer) {
      print('SharedArrayBuffer不可用，使用回退方案');
      await _initializeFallback();
      return;
    }
    
    // 尝试使用官方Stockfish WebAssembly
    final stockfishPromise = stockfish();
    _stockfish = await _promiseToFuture(stockfishPromise);
    
    // 设置消息监听器和UCI初始化...
    
  } catch (e) {
    print('官方Stockfish初始化失败，使用回退方案');
    await _initializeFallback();
  }
}
```

## 优势

1. **兼容性**：在不支持SharedArrayBuffer的环境中仍能提供AI功能
2. **合法性**：生成的移动都是基于当前棋盘状态的合法移动
3. **透明性**：对上层代码完全透明，API保持一致
4. **稳定性**：即使官方Stockfish失败，也有可靠的回退方案

## 测试方法

1. 在不支持SharedArrayBuffer的浏览器中测试
2. 故意禁用SharedArrayBuffer后测试回退机制
3. 验证回退AI生成的移动是否合法
4. 确认UI响应正常

## 局限性

- 回退AI的棋力较弱，主要是随机选择合法移动
- 没有深度分析和评估
- 适合作为最后的备选方案