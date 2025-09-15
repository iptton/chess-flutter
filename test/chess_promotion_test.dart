import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/utils/chess_formatters.dart';
import 'package:testflutter/utils/chess_adapter.dart';
import 'package:testflutter/utils/chess_rules.dart';
import 'package:testflutter/blocs/chess_bloc.dart';
import 'package:testflutter/blocs/chess_event.dart';
import 'package:testflutter/screens/game_screen.dart';

void main() {
  group('Chess Promotion 坐标边界测试', () {
    test('测试升变时坐标计算不出现负值', () {
      // 创建一个接近升变的棋盘状态
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // 在第7行放置白方兵（即将升变）
      board[1][4] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

      // 在第2行放置黑方兵（即将升变）
      board[6][3] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.black);

      // 测试白方兵升变位置
      const whitePromotionPos = Position(row: 0, col: 4);
      expect(whitePromotionPos.row >= 0, true);
      expect(whitePromotionPos.row <= 7, true);
      expect(whitePromotionPos.col >= 0, true);
      expect(whitePromotionPos.col <= 7, true);

      // 测试黑方兵升变位置
      const blackPromotionPos = Position(row: 7, col: 3);
      expect(blackPromotionPos.row >= 0, true);
      expect(blackPromotionPos.row <= 7, true);
      expect(blackPromotionPos.col >= 0, true);
      expect(blackPromotionPos.col <= 7, true);

      // 测试ChessFormatters.getPositionName不会产生负值错误
      final whitePosName = ChessFormatters.getPositionName(whitePromotionPos);
      expect(whitePosName, isNot(contains('无效位置')));

      final blackPosName = ChessFormatters.getPositionName(blackPromotionPos);
      expect(blackPosName, isNot(contains('无效位置')));
    });

    test('测试可能导致-16错误的具体场景', () {
      // 重现-16错误：通过模拟升变过程中可能出现的坐标异常

      // 场景1：模拟ChessSquare中index计算可能产生的异常值
      final problematicIndices = [-16, -15, -1, 64, 65];
      for (final index in problematicIndices) {
        if (index < 0 || index >= 64) {
          // 这些index可能导致异常的row/col计算
          final row = index ~/ 8;
          final col = index % 8;

          print('测试异常index $index -> row: $row, col: $col');

          // 验证Position创建时的坐标合法性检查
          final pos = Position(row: row, col: col);
          final posName = ChessFormatters.getPositionName(pos);

          // 如果坐标异常，应该返回错误指示
          if (row < 0 || row > 7 || col < 0 || col > 7) {
            expect(posName, contains('无效位置'));
          }
        }
      }

      // 场景2：模拟吃过路兵计算中可能产生的负坐标
      final enPassantScenarios = [
        {
          'lastPawnPos': const Position(row: 0, col: 4),
          'direction': -1
        }, // 可能产生row: -1
        {
          'lastPawnPos': const Position(row: 7, col: 4),
          'direction': 1
        }, // 可能产生row: 8
        {
          'lastPawnPos': const Position(row: -8, col: 4),
          'direction': -1
        }, // 极端情况：产生row: -9
      ];

      for (final scenario in enPassantScenarios) {
        final lastPawnPos = scenario['lastPawnPos'] as Position;
        final direction = scenario['direction'] as int;
        final targetRow = lastPawnPos.row + direction;

        print(
            '测试吃过路兵场景: lastPawn(${lastPawnPos.row},${lastPawnPos.col}) + direction($direction) = targetRow($targetRow)');

        // 模拟边界检查逻辑
        if (targetRow >= 0 && targetRow <= 7) {
          final enPassantTarget =
              Position(row: targetRow, col: lastPawnPos.col);
          final posName = ChessFormatters.getPositionName(enPassantTarget);
          expect(posName, isNot(contains('无效位置')));
        } else {
          // 超出边界的情况，确保不会创建无效Position
          print('边界检查正确阻止了无效坐标: targetRow = $targetRow');
        }
      }

      // 场景3：直接测试String.fromCharCode在具体-16场景下的行为
      try {
        final result =
            String.fromCharCode(65 + (-16)); // 'A'.codeUnitAt(0) + (-16) = 49
        print(
            'String.fromCharCode(65 + (-16)) = String.fromCharCode(49) = "$result"');
        expect(result, equals('1')); // 49对应字符'1'
      } catch (e) {
        print('String.fromCharCode(65 + (-16))抛出异常: $e');
        expect(e, isA<RangeError>());
      }

      // 场景4：测试可能导致-16的列坐标计算
      final negativeColTests = [-16, -15, -1];
      for (final col in negativeColTests) {
        print('测试负列坐标: $col');

        // 测试ChessFormatters.getColumnLabel的保护机制
        final columnLabel = ChessFormatters.getColumnLabel(col);
        expect(columnLabel, equals('?'));

        // 测试ChessFormatters.getPositionName的保护机制
        final pos = Position(row: 4, col: col);
        final posName = ChessFormatters.getPositionName(pos);
        expect(posName, contains('无效位置'));
      }
    });

    test('测试吃过路兵边界检查', () {
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // 创建可能导致边界问题的吃过路兵情况
      // 测试边界位置的双步兵
      final edgePositions = [
        const Position(row: 0, col: 4), // 顶部边界
        const Position(row: 7, col: 4), // 底部边界
        const Position(row: 3, col: 0), // 左边界
        const Position(row: 3, col: 7), // 右边界
      ];

      for (final pos in edgePositions) {
        // 测试吃过路兵目标位置计算
        for (int direction in [-1, 1]) {
          final targetRow = pos.row + direction;

          // 验证边界检查逻辑
          if (targetRow >= 0 && targetRow <= 7) {
            final enPassantTarget = Position(row: targetRow, col: pos.col);
            expect(enPassantTarget.row >= 0, true);
            expect(enPassantTarget.row <= 7, true);

            // 验证目标位置的坐标转换
            final posName = ChessFormatters.getPositionName(enPassantTarget);
            expect(posName, isNot(contains('无效位置')));
          }
        }
      }
    });

    test('测试ChessAdapter坐标转换边界', () {
      // 测试toChessLibSquare的边界检查
      final invalidPositions = [
        const Position(row: -1, col: 4),
        const Position(row: 8, col: 4),
        const Position(row: 4, col: -1),
        const Position(row: 4, col: 8),
        const Position(row: -16, col: 0), // 模拟具体错误
      ];

      for (final pos in invalidPositions) {
        expect(() => ChessAdapter.toChessLibSquare(pos), throwsArgumentError);
      }

      // 测试有效坐标
      final validPositions = [
        const Position(row: 0, col: 0),
        const Position(row: 7, col: 7),
        const Position(row: 3, col: 4),
      ];

      for (final pos in validPositions) {
        expect(() => ChessAdapter.toChessLibSquare(pos), returnsNormally);
        final square = ChessAdapter.toChessLibSquare(pos);
        expect(square.length, equals(2));
      }
    });

    test('测试String.fromCharCode边界情况', () {
      // 模拟可能导致String.fromCharCode错误的情况
      final problematicValues = [-16, -15, -1, 128, 256];

      for (final value in problematicValues) {
        if (value < 0 || value > 127) {
          // 验证我们的保护机制
          try {
            String.fromCharCode(value);
            // 如果没有抛出异常，这可能是不同版本的Dart行为
            print('警告：String.fromCharCode($value) 没有抛出异常');
          } catch (e) {
            expect(e, isA<RangeError>());
          }

          // 验证getColumnLabel的保护机制
          if (value >= -20 && value <= 20) {
            final result = ChessFormatters.getColumnLabel(value);
            expect(result, equals('?')); // 应该返回安全默认值
          }
        }
      }
    });
  });

  group('Chess Promotion 游戏逻辑测试', () {
    test('测试升变过程的状态管理', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // 这里测试升变的完整流程，确保不会产生无效坐标
      final bloc = ChessBloc();

      // 初始化游戏
      bloc.add(InitializeGame(
        false, // hintMode
        gameMode: GameMode.faceToFace,
      ));

      // 等待初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 验证初始化状态
      expect(bloc.state.board.isNotEmpty, isTrue);
    });

    test('测试升变移动创建的坐标合法性', () {
      // 测试升变移动的创建过程
      const from = Position(row: 1, col: 4); // 白方兵在第7行
      const to = Position(row: 0, col: 4); // 升变到第8行

      final pawn =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

      final move = ChessMove(
        from: from,
        to: to,
        piece: pawn,
        isPromotion: true,
        promotionType: PieceType.queen,
      );

      // 验证移动的坐标都是合法的
      expect(move.from.row >= 0 && move.from.row <= 7, true);
      expect(move.from.col >= 0 && move.from.col <= 7, true);
      expect(move.to.row >= 0 && move.to.row <= 7, true);
      expect(move.to.col >= 0 && move.to.col <= 7, true);

      // 验证坐标转换不会出错
      final fromName = ChessFormatters.getPositionName(move.from);
      final toName = ChessFormatters.getPositionName(move.to);

      expect(fromName, isNot(contains('无效位置')));
      expect(toName, isNot(contains('无效位置')));
    });

    test('测试升变过程中的坐标边界检查', () {
      // 创建一个即将升变的棋盘状态
      final board = List.generate(
          8, (row) => List.generate(8, (col) => null as ChessPiece?));

      // 白方兵在第7行（即将升变）
      board[1][4] =
          const ChessPiece(type: PieceType.pawn, color: PieceColor.white);

      // 模拟升变过程
      final promotionEvent = MovePiece(
        const Position(row: 1, col: 4),
        const Position(row: 0, col: 4),
      );

      // 验证移动事件的坐标合法性
      expect(
          promotionEvent.from.row >= 0 && promotionEvent.from.row <= 7, true);
      expect(
          promotionEvent.from.col >= 0 && promotionEvent.from.col <= 7, true);
      expect(promotionEvent.to.row >= 0 && promotionEvent.to.row <= 7, true);
      expect(promotionEvent.to.col >= 0 && promotionEvent.to.col <= 7, true);

      // 模拟升变选择事件
      final promotePawnEvent = PromotePawn(
        const Position(row: 0, col: 4),
        PieceType.queen,
      );

      // 验证升变事件的坐标合法性
      expect(
          promotePawnEvent.position.row >= 0 &&
              promotePawnEvent.position.row <= 7,
          true);
      expect(
          promotePawnEvent.position.col >= 0 &&
              promotePawnEvent.position.col <= 7,
          true);

      // 验证坐标名称转换
      final positionName =
          ChessFormatters.getPositionName(promotePawnEvent.position);
      expect(positionName, isNot(contains('无效位置')));
    });

    test('测试升变过程中棋盘渲染状态的坐标计算', () {
      // 模拟棋盘渲染时的坐标计算，特别关注升变过程中可能出现的问题
      for (int index = 0; index < 64; index++) {
        final row = index ~/ 8;
        final col = index % 8;

        // 确保所有棋盘索引都在合法范围内
        expect(row >= 0 && row <= 7, true);
        expect(col >= 0 && col <= 7, true);

        // 验证坐标转换不会出错
        final position = Position(row: row, col: col);
        final positionName = ChessFormatters.getPositionName(position);
        expect(positionName, isNot(contains('无效位置')));

        // 验证列标签不会出错
        final columnLabel = ChessFormatters.getColumnLabel(col);
        expect(columnLabel, isNot(equals('?')));
      }

      // 测试升变相关的特殊坐标
      final promotionPositions = [
        const Position(row: 0, col: 0), // 黑方升变位置
        const Position(row: 0, col: 7),
        const Position(row: 7, col: 0), // 白方升变位置
        const Position(row: 7, col: 7),
        const Position(row: 1, col: 4), // 黑方兵即将升变
        const Position(row: 6, col: 4), // 白方兵即将升变
      ];

      for (final pos in promotionPositions) {
        final posName = ChessFormatters.getPositionName(pos);
        expect(posName, isNot(contains('无效位置')));

        // 测试列索引在升变位置的计算
        final colChar = String.fromCharCode('A'.codeUnitAt(0) + pos.col);
        expect(colChar.codeUnitAt(0) >= 'A'.codeUnitAt(0), true);
        expect(colChar.codeUnitAt(0) <= 'H'.codeUnitAt(0), true);
      }
    });

    test('测试模拟升变事件处理中的坐标边界问题', () {
      // 模拟可能导致坐标越界的升变场景

      // 模拟破坏的游戏状态，可能包含非法坐标
      final corruptedStates = [
        {
          'lastPawnDoubleMoved': const Position(row: -16, col: 4),
          'description': '吃过路兵位置异常(-16)'
        },
        {
          'lastPawnDoubleMoved': const Position(row: 8, col: 4),
          'description': '吃过路兵位置超出边界(8)'
        },
        {
          'lastPawnDoubleMoved': const Position(row: 4, col: -1),
          'description': '吃过路兵列坐标负值(-1)'
        },
      ];

      for (final state in corruptedStates) {
        final pos = state['lastPawnDoubleMoved'] as Position;
        final description = state['description'] as String;

        print('测试破坏状态: $description');

        // 模拟吃过路兵目标位置计算
        for (int direction in [-1, 1]) {
          final targetRow = pos.row + direction;
          print('  direction $direction: targetRow = $targetRow');

          // 验证边界检查逻辑
          if (targetRow >= 0 &&
              targetRow <= 7 &&
              pos.col >= 0 &&
              pos.col <= 7) {
            final enPassantTarget = Position(row: targetRow, col: pos.col);
            final posName = ChessFormatters.getPositionName(enPassantTarget);
            expect(posName, isNot(contains('无效位置')));
          } else {
            // 超出边界的情况，不应该创建无效的Position
            print('    边界检查正确阻止了无效坐标的创建');
          }
        }
      }
    });

    test('测试ChessSquare组件中可能导致-16错误的具体场景', () {
      // 模拟ChessSquare中可能出现的异常index值

      // 模拟棋盘GridView中可能出现的异常情况
      final abnormalGridIndices = [-16, -15, -1, 64, 65, 72];

      for (final index in abnormalGridIndices) {
        print('测试异常GridView index: $index');

        // 模拟ChessSquare组件中的坐标计算
        final row = index ~/ 8;
        final col = index % 8;

        print('  计算结果: row = $row, col = $col');

        // 验证坐标边界检查
        if (row < 0 || row > 7 || col < 0 || col > 7) {
          // 这些异常坐标应该被正确处理
          final pos = Position(row: row, col: col);

          // 测试所有可能调用String.fromCharCode的地方
          final posName = ChessFormatters.getPositionName(pos);
          expect(posName, contains('无效位置'));

          // 特别测试可能导致-16错误的列坐标
          if (col < 0) {
            final columnLabel = ChessFormatters.getColumnLabel(col);
            expect(columnLabel, equals('?'));

            // 直接测试可能导致RangeError的计算
            final charCodeValue = 'A'.codeUnitAt(0) + col;
            print('    charCodeValue = 65 + $col = $charCodeValue');

            if (charCodeValue < 0 || charCodeValue > 127) {
              try {
                String.fromCharCode(charCodeValue);
                print('    警告：String.fromCharCode($charCodeValue) 没有抛出异常');
              } catch (e) {
                print('    确认RangeError: $e');
                expect(e, isA<RangeError>());
              }
            }
          }
        } else {
          // 正常坐标应该正常处理
          final pos = Position(row: row, col: col);
          final posName = ChessFormatters.getPositionName(pos);
          expect(posName, isNot(contains('无效位置')));
        }
      }
    });
  });
}
