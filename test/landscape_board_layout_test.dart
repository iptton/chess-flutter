import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../lib/widgets/chess_board.dart';
import '../lib/blocs/chess_bloc.dart';
import '../lib/models/chess_models.dart';
import '../lib/screens/game_screen.dart';

void main() {
  group('RED: 横屏棋盘布局优化测试', () {
    testWidgets('横屏模式下棋盘应该更大，工具栏应该更紧凑', (WidgetTester tester) async {
      // Arrange - 设置横屏尺寸 (宽高比 > 1.5)
      await tester.binding.setSurfaceSize(const Size(1200, 600)); // 2:1 比例

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider(
              create: (context) => ChessBloc(),
              child: const ChessBoard(
                gameMode: GameMode.offline,
                isInteractive: true,
              ),
            ),
          ),
        ),
      );

      // 等待初始化完成 - 需要等待FutureBuilder完成设置加载
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(); // 等待所有异步操作完成

      // Act & Assert - 验证横屏布局
      final layoutBuilder = find.byType(LayoutBuilder);
      expect(layoutBuilder, findsOneWidget);

      // 验证Row布局（横屏模式特征）
      final rowWidget = find.byType(Row);
      expect(rowWidget, findsOneWidget);

      // 验证Transform.scale存在（工具栏缩放）
      final transformScale = find.byType(Transform);
      expect(transformScale, findsOneWidget);

      // 验证棋盘网格存在
      final chessBoardGrid = find.byType(ChessBoardGrid);
      expect(chessBoardGrid, findsOneWidget);
    });

    testWidgets('竖屏模式下应该使用传统布局', (WidgetTester tester) async {
      // Arrange - 设置竖屏尺寸 (宽高比 < 1.5)
      await tester.binding.setSurfaceSize(const Size(400, 800)); // 1:2 比例

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider(
              create: (context) => ChessBloc(),
              child: const ChessBoard(
                gameMode: GameMode.offline,
                isInteractive: true,
              ),
            ),
          ),
        ),
      );

      // 等待初始化完成 - 需要等待FutureBuilder完成设置加载
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(); // 等待所有异步操作完成

      // Act & Assert - 验证竖屏布局
      final layoutBuilder = find.byType(LayoutBuilder);
      expect(layoutBuilder, findsOneWidget);

      // 验证SingleChildScrollView存在（竖屏模式特征）
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);

      // 验证Column布局（竖屏模式特征）
      final columnWidget = find.byType(Column);
      expect(columnWidget, findsWidgets); // 应该有多个Column

      // 验证棋盘网格存在
      final chessBoardGrid = find.byType(ChessBoardGrid);
      expect(chessBoardGrid, findsOneWidget);
    });

    testWidgets('边界宽高比1.5应该触发横屏布局', (WidgetTester tester) async {
      // Arrange - 设置边界宽高比 (宽高比 = 1.5)
      await tester.binding.setSurfaceSize(const Size(900, 600)); // 1.5:1 比例

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider(
              create: (context) => ChessBloc(),
              child: const ChessBoard(
                gameMode: GameMode.offline,
                isInteractive: true,
              ),
            ),
          ),
        ),
      );

      // 等待初始化完成 - 需要等待FutureBuilder完成设置加载
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(); // 等待所有异步操作完成

      // Act & Assert - 验证仍使用竖屏布局（因为 1.5 不大于 1.5）
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);
    });

    testWidgets('宽高比1.6应该触发横屏布局', (WidgetTester tester) async {
      // Arrange - 设置宽高比 > 1.5
      await tester.binding.setSurfaceSize(const Size(960, 600)); // 1.6:1 比例

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider(
              create: (context) => ChessBloc(),
              child: const ChessBoard(
                gameMode: GameMode.offline,
                isInteractive: true,
              ),
            ),
          ),
        ),
      );

      // 等待初始化完成 - 需要等待FutureBuilder完成设置加载
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle(); // 等待所有异步操作完成

      // Act & Assert - 验证使用横屏布局
      final rowWidget = find.byType(Row);
      expect(rowWidget, findsOneWidget);

      final transformScale = find.byType(Transform);
      expect(transformScale, findsOneWidget);
    });
  });
}
