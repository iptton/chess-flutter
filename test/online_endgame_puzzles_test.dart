import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/services/endgame_puzzle_service.dart';
import 'package:testflutter/data/learning_lessons.dart';

void main() {
  group('Online Endgame Puzzles Tests', () {
    late EndgamePuzzleService puzzleService;
    late LearningLessons learningLessons;

    setUp(() {
      puzzleService = EndgamePuzzleService();
      learningLessons = LearningLessons();
    });

    test('should have 20 endgame puzzles with different difficulties',
        () async {
      // Act
      final puzzles = await puzzleService.getEndgamePuzzles();

      // Assert
      expect(puzzles.length, equals(20));

      // Should have puzzles of different difficulties
      final difficulties = puzzles.map((p) => p.difficulty).toSet();
      expect(difficulties.length, greaterThan(1));
      expect(difficulties, contains(PuzzleDifficulty.beginner));
      expect(difficulties, contains(PuzzleDifficulty.intermediate));
      expect(difficulties, contains(PuzzleDifficulty.advanced));
    });

    test('should have puzzles with proper endgame characteristics', () async {
      // Act
      final puzzles = await puzzleService.getEndgamePuzzles();

      // Assert
      for (final puzzle in puzzles) {
        // Each puzzle should have valid properties
        expect(puzzle.id, isNotEmpty);
        expect(puzzle.title, isNotEmpty);
        expect(puzzle.description, isNotEmpty);
        expect(puzzle.boardState, isNotNull);
        expect(puzzle.solution, isNotNull);
        expect(puzzle.solution!.length, greaterThan(0));

        // Should be endgame positions (limited pieces)
        final pieceCount = _countPieces(puzzle.boardState!);
        expect(pieceCount,
            lessThanOrEqualTo(10)); // Endgame typically has ≤10 pieces

        // Should have both kings
        expect(_hasKing(puzzle.boardState!, PieceColor.white), isTrue);
        expect(_hasKing(puzzle.boardState!, PieceColor.black), isTrue);
      }
    });

    test('should integrate puzzles into endgame lesson', () async {
      // Act
      await puzzleService.integrateIntoLearningMode();
      final endgameLesson = learningLessons.endgameLesson;

      // Assert
      expect(endgameLesson.steps.length, greaterThan(1)); // Original + puzzles

      // Should have puzzle steps (both classic_ and puzzle_ prefixed)
      final puzzleSteps = endgameLesson.steps
          .where((step) =>
              step.id.startsWith('puzzle_') || step.id.startsWith('classic_'))
          .toList();
      expect(puzzleSteps.length, equals(20));

      // Each puzzle step should be properly formatted
      for (final step in puzzleSteps) {
        expect(step.type, equals(StepType.practice));
        expect(step.boardState, isNotNull);
        expect(step.requiredMoves, isNotNull);
        expect(step.requiredMoves!.length, greaterThan(0));
        expect(step.successMessage, isNotNull);
        expect(step.failureMessage, isNotNull);
      }
    });

    test('should sort puzzles by difficulty progression', () async {
      // Act
      final puzzles = await puzzleService.getEndgamePuzzles();

      // Assert: Should be sorted by difficulty (beginner -> intermediate -> advanced)
      var currentDifficultyIndex = -1;
      for (final puzzle in puzzles) {
        final difficultyIndex = puzzle.difficulty.index;
        expect(difficultyIndex, greaterThanOrEqualTo(currentDifficultyIndex));
        currentDifficultyIndex = difficultyIndex;
      }
    });

    test('should have diverse endgame types', () async {
      // Act
      final puzzles = await puzzleService.getEndgamePuzzles();

      // Assert: Should cover different endgame types
      final endgameTypes = puzzles.map((p) => p.endgameType).toSet();
      expect(endgameTypes.length, greaterThan(3));
      expect(endgameTypes, contains(EndgameType.kingPawn));
      expect(endgameTypes, contains(EndgameType.rookEndgame));
      expect(endgameTypes, contains(EndgameType.queenEndgame));
      expect(endgameTypes, contains(EndgameType.minorPiece));
    });

    test('should provide hints for difficult puzzles', () async {
      // Act
      final puzzles = await puzzleService.getEndgamePuzzles();
      final difficultPuzzles = puzzles
          .where((p) => p.difficulty == PuzzleDifficulty.advanced)
          .toList();

      // Assert
      expect(difficultPuzzles.length, greaterThan(0));

      for (final puzzle in difficultPuzzles) {
        expect(puzzle.hints, isNotNull);
        expect(puzzle.hints!.length, greaterThan(0));

        // Each hint should be meaningful
        for (final hint in puzzle.hints!) {
          expect(hint.length, greaterThan(10));
        }
      }
    });

    test('should have proper move validation for puzzles', () async {
      // Act
      final puzzles = await puzzleService.getEndgamePuzzles();

      // Assert
      for (final puzzle in puzzles) {
        // Solution moves should be valid
        for (final move in puzzle.solution!) {
          expect(move.from.row, inInclusiveRange(0, 7));
          expect(move.from.col, inInclusiveRange(0, 7));
          expect(move.to.row, inInclusiveRange(0, 7));
          expect(move.to.col, inInclusiveRange(0, 7));
          expect(move.piece, isNotNull);
        }

        // Should have evaluation after solution
        expect(puzzle.evaluation, isNotNull);
        expect(puzzle.evaluation!.length, greaterThan(5));
      }
    });

    test('should cache puzzles for offline use', () async {
      // Act
      await puzzleService.getEndgamePuzzles(); // First call
      final cachedPuzzles = await puzzleService.getCachedPuzzles();

      // Assert
      expect(cachedPuzzles, isNotNull);
      expect(cachedPuzzles!.length, equals(20));

      // Should be able to get puzzles without network
      final offlinePuzzles = await puzzleService.getEndgamePuzzles();
      expect(offlinePuzzles.length, equals(20));
    });

    test('should track puzzle completion and progress', () async {
      // Arrange
      final puzzles = await puzzleService.getEndgamePuzzles();
      final firstPuzzle = puzzles.first;

      // Act
      await puzzleService.markPuzzleCompleted(
          firstPuzzle.id, true, 3); // 3 attempts
      final progress = await puzzleService.getUserProgress();

      // Assert
      expect(progress.completedPuzzles, contains(firstPuzzle.id));
      expect(progress.totalAttempts, equals(3));
      expect(progress.successfulSolutions, equals(1));
      expect(progress.averageAttempts, equals(3.0));
    });

    test('should recommend next puzzle based on performance', () async {
      // Arrange
      final puzzles = await puzzleService.getEndgamePuzzles();

      // Act: Complete some beginner puzzles successfully
      for (int i = 0; i < 3; i++) {
        await puzzleService.markPuzzleCompleted(puzzles[i].id, true, 1);
      }

      final recommendation = await puzzleService.getNextRecommendedPuzzle();

      // Assert: Should recommend intermediate puzzle
      expect(recommendation, isNotNull);
      expect(recommendation!.difficulty,
          anyOf([PuzzleDifficulty.intermediate, PuzzleDifficulty.advanced]));
    });

    test('should provide puzzle statistics and analytics', () async {
      // Arrange
      final puzzles = await puzzleService.getEndgamePuzzles();

      // Act: Complete various puzzles with different results
      await puzzleService.markPuzzleCompleted(puzzles[0].id, true, 1);
      await puzzleService.markPuzzleCompleted(puzzles[1].id, false, 5);
      await puzzleService.markPuzzleCompleted(puzzles[2].id, true, 2);

      final stats = await puzzleService.getPuzzleStatistics();

      // Assert
      expect(stats.totalPuzzlesAttempted, equals(3));
      expect(stats.totalPuzzlesSolved, equals(2));
      expect(stats.successRate, equals(2 / 3));
      expect(stats.averageAttemptsPerPuzzle, equals((1 + 5 + 2) / 3));
      expect(stats.difficultyBreakdown, isNotNull);
      expect(stats.endgameTypeBreakdown, isNotNull);
    });

    test('should handle network errors gracefully', () async {
      // Act & Assert: Should not throw when network is unavailable
      expect(() => puzzleService.getEndgamePuzzles(), returnsNormally);

      // Should return cached puzzles or empty list
      final puzzles = await puzzleService.getEndgamePuzzles();
      expect(puzzles, isNotNull);
    });
  });
}

// Helper functions
int _countPieces(List<List<ChessPiece?>> board) {
  int count = 0;
  for (int row = 0; row < 8; row++) {
    for (int col = 0; col < 8; col++) {
      if (board[row][col] != null) {
        count++;
      }
    }
  }
  return count;
}

bool _hasKing(List<List<ChessPiece?>> board, PieceColor color) {
  for (int row = 0; row < 8; row++) {
    for (int col = 0; col < 8; col++) {
      final piece = board[row][col];
      if (piece != null &&
          piece.type == PieceType.king &&
          piece.color == color) {
        return true;
      }
    }
  }
  return false;
}
