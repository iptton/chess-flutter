# 王车易位UI显示问题修复

## 问题描述

用户反馈："选中王时，当前应允许进行王车易位（长易位或短易位）的情况下，并没有办法进行易位"。

## 问题根源

经过深入调试发现，问题出现在 `ChessAdapter._setCastlingRights` 方法中使用了错误的易位权限常量：

### 错误的实现 ❌
```dart
chess.castling[chess_lib.Color.WHITE] |= 1; // 王翼易位 - 错误！
chess.castling[chess_lib.Color.WHITE] |= 2; // 后翼易位 - 错误！
```

### 正确的实现 ✅
```dart
chess.castling[chess_lib.Color.WHITE] |= chess_lib.Chess.BITS_KSIDE_CASTLE; // 王翼易位 = 32
chess.castling[chess_lib.Color.WHITE] |= chess_lib.Chess.BITS_QSIDE_CASTLE; // 后翼易位 = 64
```

## 技术分析

### 调试过程发现

1. **基本条件都满足**：
   - 王和车都在正确位置 ✅
   - 王和车都没有移动过 ✅
   - 易位路径清空 ✅

2. **Chess包测试对比**：
   - **手动设置**：使用错误常量 1+2=3，无易位移动生成
   - **FEN加载**：使用正确常量 32+64=96，成功生成易位移动

3. **移动生成流程**：
   ```
   UI选中王 → ChessRules.getValidMoves() → ChessAdapter.getLegalMoves() 
   → createChessFromBoard() → _setCastlingRights() → chess.generate_moves()
   ```

### 问题影响

- UI中选中王时，不会显示易位的可选移动位置
- 玩家无法通过UI进行王车易位操作
- 影响游戏的完整性和规则准确性

## 修复内容

### 文件：`/Users/zxnap/testflutter/lib/utils/chess_adapter.dart`

在 `_setCastlingRights` 方法中更正易位权限常量：

```dart
// 白方易位权限
if (!(hasKingMoved[PieceColor.white] ?? true)) {
  if (!(hasRookMoved[PieceColor.white]?['kingside'] ?? true)) {
    chess.castling[chess_lib.Color.WHITE] |= chess_lib.Chess.BITS_KSIDE_CASTLE; // 32
  }
  if (!(hasRookMoved[PieceColor.white]?['queenside'] ?? true)) {
    chess.castling[chess_lib.Color.WHITE] |= chess_lib.Chess.BITS_QSIDE_CASTLE; // 64
  }
}

// 黑方易位权限
if (!(hasKingMoved[PieceColor.black] ?? true)) {
  if (!(hasRookMoved[PieceColor.black]?['kingside'] ?? true)) {
    chess.castling[chess_lib.Color.BLACK] |= chess_lib.Chess.BITS_KSIDE_CASTLE; // 32
  }
  if (!(hasRookMoved[PieceColor.black]?['queenside'] ?? true)) {
    chess.castling[chess_lib.Color.BLACK] |= chess_lib.Chess.BITS_QSIDE_CASTLE; // 64
  }
}
```

## 验证方法

1. **启动游戏**：运行 Flutter Web 应用
2. **设置易位条件**：
   - 确保王和车都在初始位置
   - 清空王和车之间的棋子
   - 确保王和车都没有移动过
3. **测试易位**：
   - 选中王（应该看到 g1 和 c1 位置高亮）
   - 点击 g1 进行王翼易位
   - 点击 c1 进行后翼易位

## 预期结果

修复后，玩家应该能够：
- ✅ 选中王时看到易位移动选项（g1、c1高亮显示）
- ✅ 成功执行王翼易位（e1→g1，h1→f1）
- ✅ 成功执行后翼易位（e1→c1，a1→d1）
- ✅ 与AI对战时，AI也能正确执行王车易位

## 技术要点

### Chess包易位常量
- `BITS_KSIDE_CASTLE = 32`：王翼易位标志
- `BITS_QSIDE_CASTLE = 64`：后翼易位标志
- 权限值是按位或操作的结果，双向易位 = 32 | 64 = 96

### 调试技巧
当易位不工作时，可以检查：
1. `ChessRules.getValidMoves()` 返回的移动列表
2. `chess.generate_moves()` 生成的原始移动
3. `chess.castling` 权限值是否正确
4. FEN字符串中的易位权限字段

## 相关文件

- **主要修复**：`lib/utils/chess_adapter.dart`
- **相关逻辑**：`lib/utils/chess_rules.dart`
- **UI处理**：`lib/blocs/chess_bloc.dart`

这个修复确保了王车易位功能在UI中的正确显示和操作，完善了国际象棋游戏的规则实现。