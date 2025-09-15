import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/data/learning_lessons.dart';

void main() {
  group('Enhanced Tactics Learning Tests', () {
    late LearningLessons lessonsData;

    setUp(() {
      lessonsData = LearningLessons();
    });

    test('RED: should have comprehensive tactics steps', () {
      final tacticsLesson = lessonsData.tacticsLesson;
      
      // Should have multiple steps covering different tactics
      expect(tacticsLesson.steps.length, greaterThan(3), 
             reason: 'Tactics lesson should have multiple comprehensive steps');
      
      // Should cover key tactical patterns
      final stepTitles = tacticsLesson.steps.map((s) => s.title.toLowerCase()).toList();
      
      expect(stepTitles.any((title) => title.contains('牵制') || title.contains('pin')), 
             isTrue, reason: 'Should cover pin tactics');
      expect(stepTitles.any((title) => title.contains('叉') || title.contains('fork')), 
             isTrue, reason: 'Should cover fork tactics');
      expect(stepTitles.any((title) => title.contains('串') || title.contains('skewer')), 
             isTrue, reason: 'Should cover skewer tactics');
      expect(stepTitles.any((title) => title.contains('发现') || title.contains('discovery')), 
             isTrue, reason: 'Should cover discovered attacks');
    });

    test('RED: should have practical tactics demonstrations', () {
      final tacticsLesson = lessonsData.tacticsLesson;
      
      // Should have demonstration steps
      final demonstrationSteps = tacticsLesson.steps
          .where((step) => step.type == StepType.demonstration)
          .toList();
      
      expect(demonstrationSteps.length, greaterThan(0), 
             reason: 'Should have demonstration steps');
      
      // Demonstration steps should have moves
      for (final step in demonstrationSteps) {
        expect(step.demonstrationMoves, isNotNull, 
               reason: 'Demonstration steps should have moves');
        expect(step.demonstrationMoves!.isNotEmpty, isTrue, 
               reason: 'Demonstration moves should not be empty');
      }
    });

    test('RED: should have practice steps for tactical patterns', () {
      final tacticsLesson = lessonsData.tacticsLesson;
      
      // Should have practice steps
      final practiceSteps = tacticsLesson.steps
          .where((step) => step.type == StepType.practice)
          .toList();
      
      expect(practiceSteps.length, greaterThan(0), 
             reason: 'Should have practice steps');
      
      // Practice steps should have required moves
      for (final step in practiceSteps) {
        expect(step.requiredMoves, isNotNull, 
               reason: 'Practice steps should have required moves');
        expect(step.requiredMoves!.isNotEmpty, isTrue, 
               reason: 'Required moves should not be empty');
      }
    });

    test('RED: should cover basic tactical motifs', () {
      final tacticsLesson = lessonsData.tacticsLesson;
      
      // Should cover basic tactical patterns
      final stepDescriptions = tacticsLesson.steps
          .map((s) => s.description.toLowerCase())
          .join(' ');
      
      // Should mention common tactical motifs
      expect(stepDescriptions.contains('牵制') || 
             stepDescriptions.contains('pin') ||
             stepDescriptions.contains('叉') ||
             stepDescriptions.contains('fork') ||
             stepDescriptions.contains('串') ||
             stepDescriptions.contains('skewer') ||
             stepDescriptions.contains('战术') ||
             stepDescriptions.contains('tactic'), 
             isTrue, reason: 'Should cover basic tactical motifs');
    });

    test('RED: should have proper board states for each step', () {
      final tacticsLesson = lessonsData.tacticsLesson;
      
      for (final step in tacticsLesson.steps) {
        expect(step.boardState, isNotNull, 
               reason: 'Each step should have a board state');
        expect(step.boardState!.length, equals(8), 
               reason: 'Board should have 8 rows');
        expect(step.boardState!.every((row) => row.length == 8), isTrue, 
               reason: 'Each row should have 8 columns');
      }
    });

    test('RED: should have educational instructions for each step', () {
      final tacticsLesson = lessonsData.tacticsLesson;
      
      for (final step in tacticsLesson.steps) {
        expect(step.instructions.isNotEmpty, isTrue, 
               reason: 'Each step should have instructions');
        expect(step.instructions.every((instruction) => instruction.length > 5), isTrue, 
               reason: 'Instructions should be meaningful');
      }
    });

    test('RED: should have success and failure messages for practice steps', () {
      final tacticsLesson = lessonsData.tacticsLesson;
      
      final practiceSteps = tacticsLesson.steps
          .where((step) => step.type == StepType.practice)
          .toList();
      
      for (final step in practiceSteps) {
        expect(step.successMessage, isNotNull, 
               reason: 'Practice steps should have success messages');
        expect(step.failureMessage, isNotNull, 
               reason: 'Practice steps should have failure messages');
        expect(step.successMessage!.isNotEmpty, isTrue, 
               reason: 'Success message should not be empty');
        expect(step.failureMessage!.isNotEmpty, isTrue, 
               reason: 'Failure message should not be empty');
      }
    });

    test('RED: should have highlighted positions for tactical concepts', () {
      final tacticsLesson = lessonsData.tacticsLesson;
      
      // At least some steps should have highlighted positions
      final stepsWithHighlights = tacticsLesson.steps
          .where((step) => step.highlightPositions != null && step.highlightPositions!.isNotEmpty)
          .toList();
      
      expect(stepsWithHighlights.length, greaterThan(0), 
             reason: 'Should have steps with highlighted positions');
    });

    test('RED: should demonstrate tactical combinations', () {
      final tacticsLesson = lessonsData.tacticsLesson;
      
      // Should have steps that show tactical combinations
      final stepInstructions = tacticsLesson.steps
          .expand((s) => s.instructions)
          .map((instruction) => instruction.toLowerCase())
          .join(' ');
      
      expect(stepInstructions.contains('组合') || 
             stepInstructions.contains('combination') ||
             stepInstructions.contains('连击') ||
             stepInstructions.contains('连续') ||
             stepInstructions.contains('配合'), 
             isTrue, reason: 'Should demonstrate tactical combinations');
    });
  });
}
