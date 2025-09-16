# AI 兵升变 Bug 修复

## 问题描述

在 AI 对战中，当 AI 的兵到达升变位置（即到了底线）时，程序会停住，无法继续游戏。

## 问题分析

通过代码分析和测试，发现问题的根本原因是：

1. **升变流程分为两步**：
   - `_handlePawnPromotion`: 处理兵移动到升变位置
   - `_onPromotePawn`: 处理用户选择升变类型

2. **AI 升变卡住的原因**：
   - 当 AI 的兵到达升变位置时，`_handlePawnPromotion` 被调用
   - 该方法只是移动兵到目标位置，然后等待用户选择升变类型
   - 但对于 AI 来说，没有用户界面来选择升变类型
   - 因此程序就停在这里，等待永远不会到来的用户输入

3. **测试验证**：
   - 创建了详细的调试测试来重现问题
   - 确认了 AI 升变时程序确实停住了
   - 验证了修复后的行为

## 修复方案

在 `_handlePawnPromotion` 方法中添加 AI 自动升变逻辑：

```dart
// 检查是否是AI移动
final isAIMove = state.gameMode == GameMode.offline &&
    state.aiColor == state.currentPlayer;

// 修复：如果是AI移动，自动选择升变为皇后
if (isAIMove) {
  print('AI升变：自动选择升变为皇后');
  // 直接处理AI升变，不使用Future.microtask
  _onPromotePawn(PromotePawn(event.to, PieceType.queen), emit);
}
// 对于人类玩家，等待UI选择升变类型
```

## 修复内容

1. **自动升变检测**：
   - 检查当前移动是否为 AI 移动
   - 通过 `state.gameMode == GameMode.offline && state.aiColor == state.currentPlayer` 判断

2. **自动升变处理**：
   - AI 自动选择升变为皇后（最常见的选择）
   - 直接调用 `_onPromotePawn` 方法处理升变
   - 避免使用 `Future.microtask` 以确保同步处理

3. **状态管理**：
   - 确保升变后正确切换玩家
   - 更新移动历史和游戏状态
   - 触发后续的 AI 移动检查

## 测试验证

创建了专门的测试来验证修复：

### 测试用例 1：AI 兵升变应该自动完成并切换玩家
- **场景**：AI（白方）的兵在第7行，移动到第8行升变
- **验证**：
  - AI 自动将兵升变为皇后
  - 玩家正确切换到黑方
  - 游戏状态正常，不会卡住

### 测试用例 2：人类升变后AI应该能正常响应
- **场景**：人类升变后，轮到 AI 移动
- **验证**：
  - 人类升变正常完成
  - AI 能够正常响应，不会卡住

## 修复效果

1. **✅ 解决了 AI 升变卡住的问题**
2. **✅ AI 自动选择升变为皇后**
3. **✅ 升变后正确切换玩家**
4. **✅ 游戏流程正常继续**
5. **✅ 不影响人类玩家的升变体验**

## 相关文件

- `lib/blocs/chess_bloc.dart`: 主要修复文件
- `test/ai_promotion_fix_test.dart`: 验证测试
- `test/ai_promotion_debug_test.dart`: 调试测试

## 技术细节

### 修复前的问题流程：
1. AI 移动兵到升变位置
2. `_handlePawnPromotion` 被调用
3. 程序等待用户选择升变类型
4. **卡住** - AI 没有用户界面

### 修复后的流程：
1. AI 移动兵到升变位置
2. `_handlePawnPromotion` 被调用
3. 检测到是 AI 移动
4. **自动调用** `_onPromotePawn(PieceType.queen)`
5. 升变完成，切换玩家
6. 游戏正常继续

这个修复确保了 AI 对战中的兵升变能够自动完成，解决了程序停住的问题，同时保持了游戏的流畅性和正确性。
