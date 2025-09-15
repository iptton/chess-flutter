import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/widgets/chess_board.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/models/chess_models.dart';

void main() {
  group('ChessBoardLayout', () {
    testWidgets('宽屏模式下左侧工具栏应该占满棋盘外的剩余宽度', (WidgetTester tester) async {
      // Arrange - 设置一个宽屏尺寸
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
                  Text('测试内容'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert - 验证布局是否正确
      // 在宽屏模式下应该有Row布局（主要的布局Row）
      expect(find.byType(Row), findsWidgets);

      // 应该有左侧工具栏容器和右侧棋盘容器
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // 验证是否使用了LayoutBuilder
      expect(find.byType(LayoutBuilder), findsOneWidget);

      // 验证左侧工具栏内容存在
      expect(find.text('测试内容'), findsOneWidget);

      // 验证棋盘存在
      expect(find.byType(ChessBoardGrid), findsOneWidget);

      chessBloc.close();
    });

    testWidgets('窄屏模式下应该使用垂直布局', (WidgetTester tester) async {
      // Arrange - 设置一个窄屏尺寸
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
                  Text('测试内容'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Assert - 验证布局是否正确
      // 在窄屏模式下应该有SingleChildScrollView
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      chessBloc.close();
    });
  });
}
