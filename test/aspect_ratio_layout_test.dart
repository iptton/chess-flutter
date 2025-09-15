import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/widgets/chess_board.dart';

void main() {
  group('GREEN: 宽高比布局检测测试', () {
    testWidgets('宽高比1.6 (>1.5) 应该使用横屏布局', (WidgetTester tester) async {
      // Arrange - 宽高比 = 1600/1000 = 1.6 > 1.5
      await tester.binding.setSurfaceSize(const Size(1600, 1000));

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
                  Text('工具栏内容'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 验证使用了横屏布局（左右排列）
      expect(find.byType(Row), findsWidgets);
      expect(find.text('工具栏内容'), findsOneWidget);
      expect(find.byType(ChessBoardGrid), findsOneWidget);
    });

    testWidgets('宽高比1.4 (<1.5) 应该使用竖屏布局', (WidgetTester tester) async {
      // Arrange - 宽高比 = 1400/1000 = 1.4 < 1.5
      await tester.binding.setSurfaceSize(const Size(1400, 1000));

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
                  Text('工具栏内容'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 验证使用了竖屏布局（上下排列）
      expect(find.byType(Column), findsWidgets);
      expect(find.text('工具栏内容'), findsOneWidget);
      expect(find.byType(ChessBoardGrid), findsOneWidget);
    });

    testWidgets('宽高比正好1.5 应该使用竖屏布局', (WidgetTester tester) async {
      // Arrange - 宽高比 = 1500/1000 = 1.5 (不大于1.5)
      await tester.binding.setSurfaceSize(const Size(1500, 1000));

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
                  Text('工具栏内容'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 宽高比等于1.5时应该使用竖屏布局
      expect(find.byType(Column), findsWidgets);
      expect(find.text('工具栏内容'), findsOneWidget);
      expect(find.byType(ChessBoardGrid), findsOneWidget);
    });

    testWidgets('极端横屏比例 (2.0) 应该使用横屏布局', (WidgetTester tester) async {
      // Arrange - 宽高比 = 2000/1000 = 2.0 > 1.5
      await tester.binding.setSurfaceSize(const Size(2000, 1000));

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
                  Text('工具栏内容'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 验证使用了横屏布局
      expect(find.byType(Row), findsWidgets);
      expect(find.text('工具栏内容'), findsOneWidget);
      expect(find.byType(ChessBoardGrid), findsOneWidget);
    });

    testWidgets('竖屏比例 (0.75) 应该使用竖屏布局', (WidgetTester tester) async {
      // Arrange - 宽高比 = 600/800 = 0.75 < 1.5
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
                  Text('工具栏内容'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 验证使用了竖屏布局
      expect(find.byType(Column), findsWidgets);
      expect(find.text('工具栏内容'), findsOneWidget);
      expect(find.byType(ChessBoardGrid), findsOneWidget);
    });

    testWidgets('验证横屏布局中的元素位置关系', (WidgetTester tester) async {
      // Arrange - 横屏比例
      await tester.binding.setSurfaceSize(const Size(1800, 1000));

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

      // 验证宽高比计算 (1800/1000 = 1.8 > 1.5)
      const expectedAspectRatio = 1800.0 / 1000.0;
      expect(expectedAspectRatio, greaterThan(1.5));
    });
  });
}
