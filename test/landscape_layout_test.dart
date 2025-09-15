import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/widgets/chess_board.dart';

void main() {
  group('RED: 横屏布局检测测试', () {
    testWidgets('宽高比大于1.5时应该使用左右布局', (WidgetTester tester) async {
      // Arrange - 设置横屏尺寸 (宽高比 = 1.75 > 1.5)
      await tester.binding.setSurfaceSize(const Size(1400, 800));

      final chessBloc = ChessBloc();
      chessBloc.add(const InitializeGame(false));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: chessBloc,
            child: const Scaffold(
              body: ChessBoardLayout(
                topContent: [
                  Text('测试工具栏'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 验证使用了左右布局
      // 在横屏模式下，应该能找到Row布局（左右排列）
      expect(find.byType(Row), findsWidgets);

      // 验证工具栏和棋盘都存在
      expect(find.text('测试工具栏'), findsOneWidget);
      expect(find.byType(ChessBoardGrid), findsOneWidget);
    });

    testWidgets('宽高比小于等于1.5时应该使用上下布局', (WidgetTester tester) async {
      // Arrange - 设置竖屏尺寸 (宽高比 = 0.75 < 1.5)
      await tester.binding.setSurfaceSize(const Size(600, 800));

      final chessBloc = ChessBloc();
      chessBloc.add(const InitializeGame(false));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: chessBloc,
            child: const Scaffold(
              body: ChessBoardLayout(
                topContent: [
                  Text('测试工具栏'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 验证使用了上下布局
      // 在竖屏模式下，应该能找到Column布局（上下排列）
      expect(find.byType(Column), findsWidgets);

      // 验证工具栏和棋盘都存在
      expect(find.text('测试工具栏'), findsOneWidget);
      expect(find.byType(ChessBoardGrid), findsOneWidget);
    });

    testWidgets('边界值测试：宽高比正好等于1.5', (WidgetTester tester) async {
      // Arrange - 设置宽高比正好为1.5的尺寸
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final chessBloc = ChessBloc();
      chessBloc.add(const InitializeGame(false));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: chessBloc,
            child: const Scaffold(
              body: ChessBoardLayout(
                topContent: [
                  Text('测试工具栏'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 宽高比等于1.5时应该使用上下布局（不是横屏）
      expect(find.byType(Column), findsWidgets);
      expect(find.text('测试工具栏'), findsOneWidget);
      expect(find.byType(ChessBoardGrid), findsOneWidget);
    });

    testWidgets('动态切换：从竖屏切换到横屏', (WidgetTester tester) async {
      final chessBloc = ChessBloc();
      chessBloc.add(const InitializeGame(false));

      // 初始竖屏
      await tester.binding.setSurfaceSize(const Size(600, 800));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: chessBloc,
            child: const Scaffold(
              body: ChessBoardLayout(
                topContent: [
                  Text('测试工具栏'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证初始为上下布局
      expect(find.byType(Column), findsWidgets);

      // 切换到横屏
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      await tester.pumpAndSettle();

      // 验证切换为左右布局
      expect(find.byType(Row), findsWidgets);
      expect(find.text('测试工具栏'), findsOneWidget);
      expect(find.byType(ChessBoardGrid), findsOneWidget);
    });

    testWidgets('验证横屏布局中工具栏和棋盘的位置关系', (WidgetTester tester) async {
      // Arrange - 横屏尺寸
      await tester.binding.setSurfaceSize(const Size(1600, 900));

      final chessBloc = ChessBloc();
      chessBloc.add(const InitializeGame(false));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: chessBloc,
            child: const Scaffold(
              body: ChessBoardLayout(
                topContent: [
                  Text('左侧工具栏'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 获取工具栏和棋盘的位置
      final toolbarFinder = find.text('左侧工具栏');
      final boardFinder = find.byType(ChessBoardGrid);

      expect(toolbarFinder, findsOneWidget);
      expect(boardFinder, findsOneWidget);

      final toolbarRect = tester.getRect(toolbarFinder);
      final boardRect = tester.getRect(boardFinder);

      // 在横屏布局中，工具栏应该在棋盘左侧
      expect(toolbarRect.left, lessThan(boardRect.left));
    });
  });
}
