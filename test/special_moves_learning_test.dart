import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/data/learning_lessons.dart';

void main() {
  group('Special Moves Learning Tests', () {
    late LearningLessons learningLessons;

    setUp(() {
      learningLessons = LearningLessons();
    });

    test('should have complete special moves lesson with all 3 special moves', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;

      // Assert: Should have steps for all 3 special moves
      expect(lesson.steps.length, equals(3));
      
      // Check that all special moves are covered
      final stepIds = lesson.steps.map((step) => step.id).toList();
      expect(stepIds, contains('castling'));
      expect(stepIds, contains('en_passant'));
      expect(stepIds, contains('pawn_promotion'));
    });

    test('castling step should have correct rules and conditions', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;
      final castlingStep = lesson.steps.firstWhere((step) => step.id == 'castling');

      // Assert
      expect(castlingStep.title, equals('王车易位'));
      expect(castlingStep.type, equals(StepType.explanation));
      expect(castlingStep.instructions.length, greaterThan(3));
      expect(castlingStep.instructions, contains('王车易位是王和车的联合移动'));
      expect(castlingStep.instructions, contains('王向车的方向移动2格'));
      expect(castlingStep.instructions, contains('车移动到王跨过的位置'));
      expect(castlingStep.instructions, contains('需要满足特定条件才能进行'));
      expect(castlingStep.boardState, isNotNull);
      expect(castlingStep.highlightPositions, isNotNull);
      expect(castlingStep.highlightPositions!.length, equals(2)); // King and rook
    });

    test('en passant step should have correct rules and practice', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;
      final enPassantStep = lesson.steps.firstWhere((step) => step.id == 'en_passant');

      // Assert
      expect(enPassantStep.title, equals('吃过路兵'));
      expect(enPassantStep.type, equals(StepType.practice));
      expect(enPassantStep.instructions, contains('吃过路兵是兵的特殊吃子方式'));
      expect(enPassantStep.instructions, contains('只能在对方兵刚走两格后立即进行'));
      expect(enPassantStep.instructions, contains('己方兵必须在第5行（白方）或第4行（黑方）'));
      expect(enPassantStep.instructions, contains('吃掉的是对方刚移动的兵'));
      expect(enPassantStep.boardState, isNotNull);
      expect(enPassantStep.requiredMoves, isNotNull);
      expect(enPassantStep.requiredMoves!.length, greaterThan(0));
      expect(enPassantStep.successMessage, isNotNull);
      expect(enPassantStep.failureMessage, isNotNull);
    });

    test('pawn promotion step should have correct rules and practice', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;
      final promotionStep = lesson.steps.firstWhere((step) => step.id == 'pawn_promotion');

      // Assert
      expect(promotionStep.title, equals('兵升变'));
      expect(promotionStep.type, equals(StepType.practice));
      expect(promotionStep.instructions, contains('兵到达对方底线时必须升变'));
      expect(promotionStep.instructions, contains('可以升变为后、车、象或马'));
      expect(promotionStep.instructions, contains('通常升变为后最有利'));
      expect(promotionStep.instructions, contains('升变是强制性的，不能保持兵'));
      expect(promotionStep.boardState, isNotNull);
      expect(promotionStep.requiredMoves, isNotNull);
      expect(promotionStep.requiredMoves!.length, greaterThan(0));
      expect(promotionStep.successMessage, isNotNull);
      expect(promotionStep.failureMessage, isNotNull);
    });

    test('castling step should have proper board setup', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;
      final castlingStep = lesson.steps.firstWhere((step) => step.id == 'castling');

      // Assert: Should have king and rook in starting positions
      final board = castlingStep.boardState!;
      
      // White king should be on e1 (row 7, col 4)
      expect(board[7][4]?.type, equals(PieceType.king));
      expect(board[7][4]?.color, equals(PieceColor.white));
      
      // White rook should be on h1 (row 7, col 7) for kingside castling
      expect(board[7][7]?.type, equals(PieceType.rook));
      expect(board[7][7]?.color, equals(PieceColor.white));
      
      // Path between king and rook should be clear
      expect(board[7][5], isNull); // f1
      expect(board[7][6], isNull); // g1
    });

    test('en passant step should have proper board setup', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;
      final enPassantStep = lesson.steps.firstWhere((step) => step.id == 'en_passant');

      // Assert: Should have pawns in en passant position
      final board = enPassantStep.boardState!;
      
      // Should have white pawn on 5th rank
      bool hasWhitePawnOn5thRank = false;
      for (int col = 0; col < 8; col++) {
        if (board[3][col]?.type == PieceType.pawn && board[3][col]?.color == PieceColor.white) {
          hasWhitePawnOn5thRank = true;
          break;
        }
      }
      expect(hasWhitePawnOn5thRank, isTrue);
      
      // Should have black pawn adjacent to white pawn
      bool hasAdjacentBlackPawn = false;
      for (int col = 0; col < 8; col++) {
        if (board[3][col]?.type == PieceType.pawn && board[3][col]?.color == PieceColor.black) {
          hasAdjacentBlackPawn = true;
          break;
        }
      }
      expect(hasAdjacentBlackPawn, isTrue);
    });

    test('pawn promotion step should have proper board setup', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;
      final promotionStep = lesson.steps.firstWhere((step) => step.id == 'pawn_promotion');

      // Assert: Should have pawn near promotion
      final board = promotionStep.boardState!;
      
      // Should have white pawn on 7th rank (row 1) ready to promote
      bool hasPromotionReadyPawn = false;
      for (int col = 0; col < 8; col++) {
        if (board[1][col]?.type == PieceType.pawn && board[1][col]?.color == PieceColor.white) {
          hasPromotionReadyPawn = true;
          break;
        }
      }
      expect(hasPromotionReadyPawn, isTrue);
    });

    test('all special move steps should have appropriate difficulty progression', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;

      // Assert: Should progress from explanation to practice
      final stepTypes = lesson.steps.map((step) => step.type).toList();
      
      // Castling should be explanation (most complex to understand)
      expect(lesson.steps[0].type, equals(StepType.explanation));
      
      // En passant and promotion should be practice
      expect(lesson.steps[1].type, equals(StepType.practice));
      expect(lesson.steps[2].type, equals(StepType.practice));
    });

    test('practice steps should have realistic required moves', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;
      final practiceSteps = lesson.steps.where((step) => step.type == StepType.practice);

      // Assert
      for (final step in practiceSteps) {
        expect(step.requiredMoves, isNotNull, reason: 'Step ${step.id} should have required moves');
        expect(step.requiredMoves!.length, greaterThan(0), reason: 'Step ${step.id} should have at least one required move');
        
        // Each required move should have valid positions
        for (final move in step.requiredMoves!) {
          expect(move.from.row, inInclusiveRange(0, 7));
          expect(move.from.col, inInclusiveRange(0, 7));
          expect(move.to.row, inInclusiveRange(0, 7));
          expect(move.to.col, inInclusiveRange(0, 7));
          expect(move.piece, isNotNull);
        }
      }
    });

    test('all steps should have proper feedback messages', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;
      final practiceSteps = lesson.steps.where((step) => step.type == StepType.practice);

      // Assert
      for (final step in practiceSteps) {
        expect(step.successMessage, isNotNull, reason: 'Step ${step.id} should have success message');
        expect(step.successMessage!.length, greaterThan(5), reason: 'Step ${step.id} success message should be meaningful');
        expect(step.failureMessage, isNotNull, reason: 'Step ${step.id} should have failure message');
        expect(step.failureMessage!.length, greaterThan(5), reason: 'Step ${step.id} failure message should be meaningful');
      }
    });

    test('special moves should cover all important chess rules', () {
      // Act
      final lesson = learningLessons.specialMovesLesson;

      // Assert: Should cover the three main special moves in chess
      final descriptions = lesson.steps.map((step) => step.description.toLowerCase()).join(' ');
      
      expect(descriptions, contains('王车易位'));
      expect(descriptions, contains('吃过路兵'));
      expect(descriptions, contains('兵升变'));
    });
  });
}
