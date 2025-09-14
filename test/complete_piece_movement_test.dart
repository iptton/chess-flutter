import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/data/learning_lessons.dart';

void main() {
  group('Complete Piece Movement Learning Tests', () {
    late LearningLessons learningLessons;

    setUp(() {
      learningLessons = LearningLessons();
    });

    test('should have complete piece movement lesson with all 6 piece types', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;

      // Assert: Should have steps for all 6 piece types
      expect(lesson.steps.length, equals(6));
      
      // Check that all piece types are covered
      final stepIds = lesson.steps.map((step) => step.id).toList();
      expect(stepIds, contains('pawn_movement'));
      expect(stepIds, contains('rook_movement'));
      expect(stepIds, contains('knight_movement'));
      expect(stepIds, contains('bishop_movement'));
      expect(stepIds, contains('queen_movement'));
      expect(stepIds, contains('king_movement'));
    });

    test('pawn movement step should have correct rules and practice', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;
      final pawnStep = lesson.steps.firstWhere((step) => step.id == 'pawn_movement');

      // Assert
      expect(pawnStep.title, equals('兵的移动'));
      expect(pawnStep.type, equals(StepType.demonstration));
      expect(pawnStep.instructions.length, greaterThan(3));
      expect(pawnStep.instructions, contains('兵只能向前移动'));
      expect(pawnStep.instructions, contains('第一次移动可以走1格或2格'));
      expect(pawnStep.instructions, contains('斜向攻击敌方棋子'));
      expect(pawnStep.demonstrationMoves, isNotNull);
      expect(pawnStep.demonstrationMoves!.length, greaterThan(0));
    });

    test('rook movement step should have correct rules and practice', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;
      final rookStep = lesson.steps.firstWhere((step) => step.id == 'rook_movement');

      // Assert
      expect(rookStep.title, equals('车的移动'));
      expect(rookStep.type, equals(StepType.practice));
      expect(rookStep.instructions, contains('车可以水平或垂直移动任意格数'));
      expect(rookStep.instructions, contains('不能跳过其他棋子'));
      expect(rookStep.requiredMoves, isNotNull);
      expect(rookStep.requiredMoves!.length, greaterThan(0));
      expect(rookStep.successMessage, isNotNull);
      expect(rookStep.failureMessage, isNotNull);
    });

    test('knight movement step should have correct rules and practice', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;
      final knightStep = lesson.steps.firstWhere((step) => step.id == 'knight_movement');

      // Assert
      expect(knightStep.title, equals('马的移动'));
      expect(knightStep.type, equals(StepType.practice));
      expect(knightStep.instructions, contains('马走"L"形：2格直线+1格垂直'));
      expect(knightStep.instructions, contains('马是唯一可以跳过其他棋子的'));
      expect(knightStep.requiredMoves, isNotNull);
      expect(knightStep.requiredMoves!.length, greaterThan(0));
    });

    test('bishop movement step should have correct rules and practice', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;
      final bishopStep = lesson.steps.firstWhere((step) => step.id == 'bishop_movement');

      // Assert
      expect(bishopStep.title, equals('象的移动'));
      expect(bishopStep.type, equals(StepType.practice));
      expect(bishopStep.instructions, contains('象只能斜向移动'));
      expect(bishopStep.instructions, contains('可以移动任意格数'));
      expect(bishopStep.instructions, contains('不能跳过其他棋子'));
      expect(bishopStep.requiredMoves, isNotNull);
      expect(bishopStep.requiredMoves!.length, greaterThan(0));
      expect(bishopStep.successMessage, isNotNull);
      expect(bishopStep.failureMessage, isNotNull);
    });

    test('queen movement step should have correct rules and practice', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;
      final queenStep = lesson.steps.firstWhere((step) => step.id == 'queen_movement');

      // Assert
      expect(queenStep.title, equals('后的移动'));
      expect(queenStep.type, equals(StepType.practice));
      expect(queenStep.instructions, contains('后是最强大的棋子'));
      expect(queenStep.instructions, contains('可以水平、垂直或斜向移动'));
      expect(queenStep.instructions, contains('结合了车和象的移动方式'));
      expect(queenStep.requiredMoves, isNotNull);
      expect(queenStep.requiredMoves!.length, greaterThan(0));
      expect(queenStep.successMessage, isNotNull);
      expect(queenStep.failureMessage, isNotNull);
    });

    test('king movement step should have correct rules and practice', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;
      final kingStep = lesson.steps.firstWhere((step) => step.id == 'king_movement');

      // Assert
      expect(kingStep.title, equals('王的移动'));
      expect(kingStep.type, equals(StepType.practice));
      expect(kingStep.instructions, contains('王是最重要的棋子'));
      expect(kingStep.instructions, contains('只能移动一格'));
      expect(kingStep.instructions, contains('可以向任意方向移动'));
      expect(kingStep.instructions, contains('不能移动到被攻击的位置'));
      expect(kingStep.requiredMoves, isNotNull);
      expect(kingStep.requiredMoves!.length, greaterThan(0));
      expect(kingStep.successMessage, isNotNull);
      expect(kingStep.failureMessage, isNotNull);
    });

    test('all practice steps should have proper board states', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;
      final practiceSteps = lesson.steps.where((step) => step.type == StepType.practice);

      // Assert
      for (final step in practiceSteps) {
        expect(step.boardState, isNotNull, reason: 'Step ${step.id} should have board state');
        expect(step.boardState!.length, equals(8), reason: 'Board should be 8x8');
        expect(step.boardState![0].length, equals(8), reason: 'Board should be 8x8');
        expect(step.highlightPositions, isNotNull, reason: 'Step ${step.id} should have highlight positions');
        expect(step.highlightPositions!.length, greaterThan(0), reason: 'Step ${step.id} should highlight at least one position');
      }
    });

    test('all steps should have appropriate difficulty progression', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;

      // Assert: Should start with simpler pieces and progress to complex ones
      final stepIds = lesson.steps.map((step) => step.id).toList();
      
      // Pawn should be first (simplest)
      expect(stepIds.indexOf('pawn_movement'), equals(0));
      
      // King should be last (most important, needs understanding of other pieces)
      expect(stepIds.indexOf('king_movement'), equals(stepIds.length - 1));
      
      // Queen should be near the end (most complex)
      expect(stepIds.indexOf('queen_movement'), greaterThan(stepIds.indexOf('rook_movement')));
      expect(stepIds.indexOf('queen_movement'), greaterThan(stepIds.indexOf('bishop_movement')));
    });

    test('each piece should have realistic board setup for learning', () {
      // Act
      final lesson = learningLessons.pieceMovementLesson;

      // Assert: Each step should have a board that makes sense for learning that piece
      for (final step in lesson.steps) {
        if (step.boardState != null) {
          // Find the piece being taught
          ChessPiece? targetPiece;
          Position? targetPosition;
          
          for (int row = 0; row < 8; row++) {
            for (int col = 0; col < 8; col++) {
              final piece = step.boardState![row][col];
              if (piece != null && step.highlightPositions?.contains(Position(row: row, col: col)) == true) {
                targetPiece = piece;
                targetPosition = Position(row: row, col: col);
                break;
              }
            }
            if (targetPiece != null) break;
          }

          expect(targetPiece, isNotNull, reason: 'Step ${step.id} should have a highlighted piece to learn');
          expect(targetPosition, isNotNull, reason: 'Step ${step.id} should have a highlighted position');
          
          // Verify the piece type matches the step
          if (step.id.contains('pawn')) {
            expect(targetPiece!.type, equals(PieceType.pawn));
          } else if (step.id.contains('rook')) {
            expect(targetPiece!.type, equals(PieceType.rook));
          } else if (step.id.contains('knight')) {
            expect(targetPiece!.type, equals(PieceType.knight));
          } else if (step.id.contains('bishop')) {
            expect(targetPiece!.type, equals(PieceType.bishop));
          } else if (step.id.contains('queen')) {
            expect(targetPiece!.type, equals(PieceType.queen));
          } else if (step.id.contains('king')) {
            expect(targetPiece!.type, equals(PieceType.king));
          }
        }
      }
    });
  });
}
