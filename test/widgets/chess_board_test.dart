import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:testflutter/widgets/chess_board.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/screens/game_screen.dart';
import 'package:testflutter/utils/chess_theme.dart';
import 'package:testflutter/l10n/chess_localizations.dart';

import 'chess_board_test.mocks.dart';

@GenerateMocks([ChessBloc])
void main() {
  late MockChessBloc mockChessBloc;

  setUp(() {
    mockChessBloc = MockChessBloc();
  });

  Widget createWidgetUnderTest({GameMode gameMode = GameMode.offline}) {
    return MaterialApp(
      home: BlocProvider<ChessBloc>.value(
        value: mockChessBloc,
        child: ChessBoard(gameMode: gameMode),
      ),
    );
  }

  group('ChessBoard Widget Tests', () {
    testWidgets('renders correctly with initial state', (tester) async {
      // ���备
      when(mockChessBloc.state).thenReturn(GameState.initial());
      when(mockChessBloc.stream).thenAnswer((_) => Stream.empty());

      // 执行
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 验证
      expect(find.byType(ChessBoard), findsOneWidget);
      expect(find.byType(ChessBoardSquares), findsOneWidget);
      expect(find.byType(TurnIndicator), findsOneWidget);
      expect(find.byType(ControlButtons), findsOneWidget);
    });

    testWidgets('shows correct turn indicator', (tester) async {
      // 准备
      when(mockChessBloc.state).thenReturn(GameState.initial());
      when(mockChessBloc.stream).thenAnswer((_) => Stream.empty());

      // 执行
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 验证
      expect(find.text('当前回合: 白方'), findsOneWidget);
    });

    testWidgets('control buttons work correctly', (tester) async {
      // 准备
      final gameState = GameState.initial().copyWith(
        undoStates: [GameState.initial()],
        redoStates: [GameState.initial()],
      );
      when(mockChessBloc.state).thenReturn(gameState);
      when(mockChessBloc.stream).thenAnswer((_) => Stream.empty());

      // 执行
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 点击撤销按钮
      await tester.tap(find.text('前一步'));
      verify(mockChessBloc.add(const UndoMove())).called(1);

      // 点击重做按钮
      await tester.tap(find.text('后一步'));
      verify(mockChessBloc.add(const RedoMove())).called(1);

      // 点击提示按钮
      await tester.tap(find.text('开启提示'));
      verify(mockChessBloc.add(ToggleHintMode())).called(1);
    });
  });

  group('ChessSquare Widget Tests', () {
    testWidgets('shows correct piece image', (tester) async {
      // 准备
      final piece = ChessPiece(type: PieceType.king, color: PieceColor.white);
      final board = List.generate(8, (_) => List.filled(8, null));
      board[0][0] = piece;
      
      final gameState = GameState.initial().copyWith(board: board);
      when(mockChessBloc.state).thenReturn(gameState);
      when(mockChessBloc.stream).thenAnswer((_) => Stream.empty());

      // 执行
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 验证
      expect(find.byType(ChessPieceImage), findsOneWidget);
    });

    testWidgets('handles tap correctly', (tester) async {
      // 准备
      final piece = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
      final board = List.generate(8, (_) => List.filled(8, null));
      board[6][0] = piece;
      
      final gameState = GameState.initial().copyWith(
        board: board,
        currentPlayer: PieceColor.white,
      );
      when(mockChessBloc.state).thenReturn(gameState);
      when(mockChessBloc.stream).thenAnswer((_) => Stream.empty());

      // 执行
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 点击棋子
      await tester.tap(find.byType(ChessSquare).first);
      verify(mockChessBloc.add(any)).called(1);
    });
  });

  group('Theme Tests', () {
    testWidgets('applies theme correctly', (tester) async {
      // 准备
      when(mockChessBloc.state).thenReturn(GameState.initial());
      when(mockChessBloc.stream).thenAnswer((_) => Stream.empty());

      final theme = ChessTheme.dark;
      
      // 执行
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          extensions: [theme],
        ),
        home: BlocProvider<ChessBloc>.value(
          value: mockChessBloc,
          child: const ChessBoard(gameMode: GameMode.offline),
        ),
      ));
      await tester.pumpAndSettle();

      // 验证主题是否正确应用
      final context = tester.element(find.byType(ChessBoard));
      final appliedTheme = Theme.of(context).extension<ChessTheme>();
      expect(appliedTheme, theme);
    });
  });

  group('Localization Tests', () {
    testWidgets('shows correct translations', (tester) async {
      // 准备
      when(mockChessBloc.state).thenReturn(GameState.initial());
      when(mockChessBloc.stream).thenAnswer((_) => Stream.empty());

      final l10n = ChessLocalizations.of('en');
      
      // 执行
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        home: BlocProvider<ChessBloc>.value(
          value: mockChessBloc,
          child: const ChessBoard(gameMode: GameMode.offline),
        ),
      ));
      await tester.pumpAndSettle();

      // 验证文本是否正确翻译
      expect(find.text(l10n.currentTurn + ': ' + l10n.white), findsOneWidget);
      expect(find.text(l10n.undo), findsOneWidget);
      expect(find.text(l10n.redo), findsOneWidget);
      expect(find.text(l10n.hintOff), findsOneWidget);
    });
  });
} 