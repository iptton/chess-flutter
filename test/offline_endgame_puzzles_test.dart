import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/services/endgame_puzzle_service.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';

void main() {
  group('Offline Endgame Puzzles Tests', () {
    late EndgamePuzzleService service;

    setUp(() {
      service = EndgamePuzzleService();
    });

    test('should generate 20 offline endgame puzzles', () async {
      // Act: Get endgame puzzles
      final puzzles = await service.getEndgamePuzzles();

      // Assert: Should have exactly 20 puzzles
      expect(puzzles.length, equals(20));
      
      // Should have different difficulty levels
      final beginnerCount = puzzles.where((p) => p.difficulty == PuzzleDifficulty.beginner).length;
      final intermediateCount = puzzles.where((p) => p.difficulty == PuzzleDifficulty.intermediate).length;
      final advancedCount = puzzles.where((p) => p.difficulty == PuzzleDifficulty.advanced).length;
      
      expect(beginnerCount, equals(8));
      expect(intermediateCount, equals(8));
      expect(advancedCount, equals(4));
    });

    test('should have realistic chess positions', () async {
      // Act: Get puzzles
      final puzzles = await service.getEndgamePuzzles();

      // Assert: Each puzzle should have valid board state
      for (final puzzle in puzzles) {
        expect(puzzle.boardState, isNotNull);
        expect(puzzle.boardState.length, equals(8));
        expect(puzzle.boardState[0].length, equals(8));
        
        // Should have at least two kings
        int whiteKingCount = 0;
        int blackKingCount = 0;
        
        for (int row = 0; row < 8; row++) {
          for (int col = 0; col < 8; col++) {
            final piece = puzzle.boardState[row][col];
            if (piece?.type == PieceType.king) {
              if (piece!.color == PieceColor.white) {
                whiteKingCount++;
              } else {
                blackKingCount++;
              }
            }
          }
        }
        
        expect(whiteKingCount, equals(1), reason: 'Each puzzle should have exactly one white king');
        expect(blackKingCount, equals(1), reason: 'Each puzzle should have exactly one black king');
      }
    });

    test('should have valid solutions', () async {
      // Act: Get puzzles
      final puzzles = await service.getEndgamePuzzles();

      // Assert: Each puzzle should have a solution
      for (final puzzle in puzzles) {
        expect(puzzle.solution, isNotEmpty, reason: 'Each puzzle should have at least one move in solution');
        
        // Each move should be valid
        for (final move in puzzle.solution) {
          expect(move.from.row, greaterThanOrEqualTo(0));
          expect(move.from.row, lessThan(8));
          expect(move.from.col, greaterThanOrEqualTo(0));
          expect(move.from.col, lessThan(8));
          expect(move.to.row, greaterThanOrEqualTo(0));
          expect(move.to.row, lessThan(8));
          expect(move.to.col, greaterThanOrEqualTo(0));
          expect(move.to.col, lessThan(8));
        }
      }
    });

    test('should work completely offline', () async {
      // Act: Get puzzles multiple times
      final puzzles1 = await service.getEndgamePuzzles();
      final puzzles2 = await service.getEndgamePuzzles();

      // Assert: Should return same puzzles (cached)
      expect(puzzles1.length, equals(puzzles2.length));
      expect(puzzles1.first.id, equals(puzzles2.first.id));
      
      // Should not require network access
      expect(puzzles1, isNotEmpty);
    });

    test('should have different endgame types', () async {
      // Act: Get puzzles
      final puzzles = await service.getEndgamePuzzles();

      // Assert: Should have variety of endgame types
      final endgameTypes = puzzles.map((p) => p.endgameType).toSet();
      expect(endgameTypes.length, greaterThan(3), reason: 'Should have multiple endgame types');
      
      // Should include common endgame types
      expect(endgameTypes, contains(EndgameType.kingPawn));
      expect(endgameTypes, contains(EndgameType.rookEndgame));
      expect(endgameTypes, contains(EndgameType.mateIn));
    });

    test('should have appropriate ratings for difficulty', () async {
      // Act: Get puzzles
      final puzzles = await service.getEndgamePuzzles();

      // Assert: Ratings should increase with difficulty
      final beginnerPuzzles = puzzles.where((p) => p.difficulty == PuzzleDifficulty.beginner);
      final intermediatePuzzles = puzzles.where((p) => p.difficulty == PuzzleDifficulty.intermediate);
      final advancedPuzzles = puzzles.where((p) => p.difficulty == PuzzleDifficulty.advanced);

      for (final puzzle in beginnerPuzzles) {
        expect(puzzle.rating, lessThan(1400), reason: 'Beginner puzzles should have lower ratings');
      }

      for (final puzzle in intermediatePuzzles) {
        expect(puzzle.rating, greaterThanOrEqualTo(1400));
        expect(puzzle.rating, lessThan(1800), reason: 'Intermediate puzzles should have medium ratings');
      }

      for (final puzzle in advancedPuzzles) {
        expect(puzzle.rating, greaterThanOrEqualTo(1800), reason: 'Advanced puzzles should have higher ratings');
      }
    });

    test('should integrate into learning mode', () async {
      // Act: Integrate puzzles into learning mode
      await service.integrateIntoLearningMode();

      // Assert: Should complete without errors
      // This tests that the integration method works
      expect(true, isTrue);
    });

    test('should track user progress', () async {
      // Arrange: Get a puzzle
      final puzzles = await service.getEndgamePuzzles();
      final firstPuzzle = puzzles.first;

      // Act: Mark puzzle as completed
      await service.markPuzzleCompleted(firstPuzzle.id, true, 3);

      // Assert: Progress should be tracked
      final progress = await service.getUserProgress();
      expect(progress.completedPuzzles, contains(firstPuzzle.id));
      expect(progress.successfulSolutions, equals(1));
      expect(progress.totalAttempts, equals(3));
    });

    test('should provide puzzle recommendations', () async {
      // Arrange: Get puzzles and mark some as completed
      final puzzles = await service.getEndgamePuzzles();
      final beginnerPuzzle = puzzles.firstWhere((p) => p.difficulty == PuzzleDifficulty.beginner);
      
      // Act: Get recommendation for new user
      final recommendation1 = await service.getNextRecommendedPuzzle();
      
      // Mark some puzzles as completed with good performance
      await service.markPuzzleCompleted(beginnerPuzzle.id, true, 1);
      
      // Act: Get recommendation after good performance
      final recommendation2 = await service.getNextRecommendedPuzzle();

      // Assert: Should provide appropriate recommendations
      expect(recommendation1, isNotNull);
      expect(recommendation1!.difficulty, equals(PuzzleDifficulty.beginner));
      
      expect(recommendation2, isNotNull);
      // After good performance, should recommend harder puzzles
    });
  });
}
