# 升变位置显示错误修复总结

## 问题描述

用户报告了一个升变功能的错误：当一方发生升变时，弹出升变选择框时升变方的棋子位置显示错误信息"Index out of range: index must not be negative: -16"，选中升变为什么后才恢复。

## 问题根源分析

经过深入分析，发现问题出现在两个地方：

### 1. ChessBloc中的升变位置计算错误

在`_onPromotePawn`方法中，当没有历史记录时，代码尝试创建一个默认的起始位置，但是计算有误：

```dart
// 错误的计算：
final fromRow = isWhite ? 1 : 6; // 白方从第7行升变，黑方从第2行升变
```

这导致了错误的位置计算，可能产生负数索引。

### 2. 升变对话框显示问题

在`PromotionOption`组件中，升变选择框总是显示白色棋子的图片，没有根据当前升变的棋子颜色来动态选择：

```dart
// 错误的硬编码：
child: Image.asset(
  'assets/images/white_${pieceType.toString().split('.').last}.png',
  fit: BoxFit.contain,
),
```

## 修复方案

### 1. 修复ChessBloc中的位置计算

更正了`_onPromotePawn`方法中的起始位置计算：

```dart
// 修复后的正确计算：
final fromRow = isWhite ? 6 : 1; // 白方从第6行升变到第0行，黑方从第1行升变到第7行
```

这确保了升变移动的起始位置坐标是合理的（不为负）。

### 2. 修复升变对话框显示

#### 2.1 修改showPromotionDialog函数

添加了获取当前升变棋子颜色的逻辑：

```dart
Future<void> showPromotionDialog(BuildContext context, Position position) async {
  final bloc = context.read<ChessBloc>();
  final currentState = bloc.state;
  final piece = currentState.board[position.row][position.col];
  final pieceColor = piece?.color ?? currentState.currentPlayer;
  
  final promotedPiece = await showDialog<PieceType>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return PromotionDialog(pieceColor: pieceColor);
    },
  );
  // ...
}
```

#### 2.2 修改PromotionDialog组件

添加了棋子颜色参数：

```dart
class PromotionDialog extends StatelessWidget {
  final PieceColor pieceColor;

  const PromotionDialog({super.key, required this.pieceColor});
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择升变棋子', ...),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PromotionOption(pieceType: PieceType.queen, pieceColor: pieceColor),
                  const SizedBox(width: 8),
                  PromotionOption(pieceType: PieceType.rook, pieceColor: pieceColor),
                  const SizedBox(width: 8),
                  PromotionOption(pieceType: PieceType.bishop, pieceColor: pieceColor),
                  const SizedBox(width: 8),
                  PromotionOption(pieceType: PieceType.knight, pieceColor: pieceColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 2.3 修改PromotionOption组件

添加了棋子颜色参数并使用正确的棋子图片：

```dart
class PromotionOption extends StatelessWidget {
  final PieceType pieceType;
  final PieceColor pieceColor;

  const PromotionOption({
    super.key,
    required this.pieceType,
    required this.pieceColor,
  });

  @override
  Widget build(BuildContext context) {
    final piece = ChessPiece(type: pieceType, color: pieceColor);
    
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(pieceType),
      child: Container(
        width: 60,
        height: 60,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ChessPieceImage(piece: piece),
      ),
    );
  }
}
```

## 修复效果

经过这些修复：

1. **消除了负索引错误**：升变过程中不再出现"Index out of range: index must not be negative: -16"的错误
2. **正确显示棋子颜色**：升变选择框现在会显示正确颜色的棋子图片（白方升变显示白色棋子，黑方升变显示黑色棋子）
3. **改善用户体验**：升变过程更加直观和用户友好

## 测试验证

创建了专门的测试文件`chess_promotion_position_fix_test.dart`来验证修复：

- 测试白方升变过程中位置显示正确
- 测试黑方升变过程中位置显示正确
- 测试极端边界情况下的升变处理

所有测试确认修复有效，升变功能现在工作正常。

## 相关文件

- `lib/blocs/chess_bloc.dart`: 修复了`_onPromotePawn`方法中的位置计算
- `lib/widgets/chess_board.dart`: 修复了升变对话框的显示逻辑
- `test/chess_promotion_position_fix_test.dart`: 添加的验证测试

这个修复确保了升变功能的稳定性和用户体验的一致性。