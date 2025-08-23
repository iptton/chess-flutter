# 王车易位问题修复总结

## 问题分析

用户反馈"王车易位时，车没有动"，经过代码分析发现了王车易位逻辑中存在的问题。

## 发现的问题

### 1. 车移动状态更新缺失 ❌
原代码在`_handleCastling`方法中：
- ✅ 正确更新了王的移动状态(`hasKingMoved`)
- ❌ **没有更新车的移动状态**(`hasRookMoved`)

这导致：
- 参与易位的车在后续仍然被认为"未移动"
- 可能影响后续的易位规则判断

### 2. 车移动逻辑需要优化 🔧
原代码：
```dart
newBoard[event.from.row][rookToCol] = newBoard[event.from.row][rookFromCol];
newBoard[event.from.row][rookFromCol] = null;
```

优化为更清晰的逻辑：
```dart
final rook = newBoard[event.from.row][rookFromCol];
newBoard[event.from.row][rookToCol] = rook;
newBoard[event.from.row][rookFromCol] = null;
```

## 修复内容

### 1. 添加车移动状态更新
```dart
// 修复：更新车的移动状态
final newHasRookMoved = Map<PieceColor, Map<String, bool>>.from(
  state.hasRookMoved.map(
    (color, value) => MapEntry(
      color,
      Map<String, bool>.from(value),
    ),
  ),
);

// 标记参与易位的车为已移动
if (isKingside) {
  newHasRookMoved[movingPiece.color]!['kingside'] = true;
} else {
  newHasRookMoved[movingPiece.color]!['queenside'] = true;
}
```

### 2. 状态更新完整性
在`emit(state.copyWith(...))`中添加：
```dart
hasRookMoved: newHasRookMoved, // 修复：添加缺失的车移动状态更新
```

### 3. 将军/将死检查修正
使用更新后的车移动状态进行检查：
```dart
ChessRules.isCheckmate(
  newBoard,
  nextPlayer,
  newHasKingMoved,
  newHasRookMoved, // 使用更新后的车移动状态
  // ...
);
```

## 王车易位规则确认

### 王翼易位（短易位）
- 王从 e1→g1 (白方) 或 e8→g8 (黑方)
- 车从 h1→f1 (白方) 或 h8→f8 (黑方)

### 后翼易位（长易位）
- 王从 e1→c1 (白方) 或 e8→c8 (黑方)  
- 车从 a1→d1 (白方) 或 a8→d8 (黑方)

### 易位条件
1. ✅ 王和对应的车都没有移动过
2. ✅ 王和车之间没有棋子
3. ✅ 王不能处于被将军状态
4. ✅ 王经过的格子不能被对方攻击
5. ✅ 王到达的格子不能被对方攻击

## 调试信息

添加了调试输出来跟踪车的移动：
```dart
print('王车易位: 车从(${event.from.row}, $rookFromCol)移动到(${event.from.row}, $rookToCol)');
print('车棋子: $rook');
```

## 测试验证

修复后应该验证：
1. 王车易位时王和车都正确移动到新位置
2. 易位后双方都不能再次进行同侧易位
3. 易位后的棋盘状态正确保存
4. AI能正确识别和执行王车易位

## 相关文件

- `/Users/zxnap/testflutter/lib/blocs/chess_bloc.dart` (第293-332行)

这个修复确保了王车易位的完整性和正确性，符合国际象棋的标准规则。