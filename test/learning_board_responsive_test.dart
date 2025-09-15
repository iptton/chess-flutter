import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/widgets/learning_board.dart';
import 'package:testflutter/models/chess_models.dart';

void main() {
  group('学习模式棋盘响应式测试', () {
    testWidgets('RED: 棋子大小应该根据棋盘大小动态调整', (WidgetTester tester) async {
      // 创建一个简单的棋盘状态
      final boardState = List.generate(
        8,
        (row) => List.generate(8, (col) {
          if (row == 0 && col == 4) {
            return const ChessPiece(type: PieceType.king, color: PieceColor.white);
          }
          return null;
        }),
      );

      // 测试小尺寸棋盘
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 200,
              child: LearningBoard(
                boardState: boardState,
                isInteractive: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找棋子文本
      final kingFinder = find.text('♔');
      expect(kingFinder, findsOneWidget);

      // 获取棋子的文本样式
      final kingWidget = tester.widget<Text>(kingFinder);
      final smallBoardFontSize = kingWidget.style?.fontSize ?? 0;

      // 测试大尺寸棋盘
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: LearningBoard(
                boardState: boardState,
                isInteractive: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 再次查找棋子文本
      final kingFinder2 = find.text('♔');
      expect(kingFinder2, findsOneWidget);

      // 获取棋子的文本样式
      final kingWidget2 = tester.widget<Text>(kingFinder2);
      final largeBoardFontSize = kingWidget2.style?.fontSize ?? 0;

      // 大棋盘的棋子应该比小棋盘的棋子大
      expect(largeBoardFontSize, greaterThan(smallBoardFontSize));
    });

    testWidgets('RED: 极小棋盘时棋子应该有最小尺寸限制', (WidgetTester tester) async {
      // 创建一个简单的棋盘状态
      final boardState = List.generate(
        8,
        (row) => List.generate(8, (col) {
          if (row == 0 && col == 4) {
            return const ChessPiece(type: PieceType.king, color: PieceColor.white);
          }
          return null;
        }),
      );

      // 测试极小尺寸棋盘
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: LearningBoard(
                boardState: boardState,
                isInteractive: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 查找棋子文本
      final kingFinder = find.text('♔');
      expect(kingFinder, findsOneWidget);

      // 获取棋子的文本样式
      final kingWidget = tester.widget<Text>(kingFinder);
      final fontSize = kingWidget.style?.fontSize ?? 0;

      // 棋子应该有最小尺寸限制（比如不小于12）
      expect(fontSize, greaterThanOrEqualTo(12));
    });
  });
}
