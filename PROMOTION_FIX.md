# 升变玩家切换问题修复

## 问题描述

在AI对战中，当一方的兵升变后，应该轮到另一方移动，但当前逻辑依然把轮次给了升变的一方。

## 问题分析

通过代码检查发现，升变处理分为两个步骤：

1. **`_handlePawnPromotion`方法**（第541行）：处理兵移动到升变位置，**正确切换了玩家**
2. **`_onPromotePawn`方法**（第720行）：处理用户选择升变类型，**没有切换玩家！**

### 问题根源

在`_onPromotePawn`方法中，当用户选择了升变类型后，该方法会：
- 正确计算`nextPlayer`变量
- 正确检查对手是否被将军/将死
- 但在`emit(state.copyWith(...))`时**缺少了**`currentPlayer: nextPlayer`

## 修复方案

在`_onPromotePawn`方法的`emit`调用中添加缺失的玩家切换：

```dart
emit(state.copyWith(
  board: newBoard,
  currentPlayer: nextPlayer,  // 修复：添加缺失的玩家切换
  moveHistory: [
    ...state.moveHistory.sublist(0, state.moveHistory.length - 1),
    lastMove,
  ],
  // ... 其他字段
));

// 检查是否需要AI移动
_checkForAIMove(emit);
```

## 修复内容

1. **添加玩家切换**：在`_onPromotePawn`方法中添加`currentPlayer: nextPlayer`
2. **添加AI检查**：在升变完成后调用`_checkForAIMove(emit)`，确保轮到AI时能正确触发AI移动

## 验证方法

1. 在游戏中将兵推进到对方底线触发升变
2. 选择升变类型（如皇后）
3. 确认升变后轮到对方移动，而不是继续当前玩家的回合
4. 如果是AI对战，确认升变后AI能正确响应

## 相关文件

- `/Users/zxnap/testflutter/lib/blocs/chess_bloc.dart` (第770-780行)

这个修复确保了国际象棋规则的正确性：升变是一个完整的移动，完成后应该轮到对方移动。