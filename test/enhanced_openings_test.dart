import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/data/learning_lessons.dart';

void main() {
  group('Enhanced Openings Learning Tests', () {
    late LearningLessons lessonsData;

    setUp(() {
      lessonsData = LearningLessons();
    });

    test('RED: should have comprehensive opening principles steps', () {
      final openingsLesson = lessonsData.openingsLesson;
      
      // Should have multiple steps covering different opening principles
      expect(openingsLesson.steps.length, greaterThan(1), 
             reason: 'Opening lesson should have multiple comprehensive steps');
      
      // Should cover key opening principles
      final stepTitles = openingsLesson.steps.map((s) => s.title.toLowerCase()).toList();
      
      expect(stepTitles.any((title) => title.contains('中心') || title.contains('center')), 
             isTrue, reason: 'Should cover center control');
      expect(stepTitles.any((title) => title.contains('出子') || title.contains('development')), 
             isTrue, reason: 'Should cover piece development');
      expect(stepTitles.any((title) => title.contains('王') || title.contains('king') || title.contains('安全')), 
             isTrue, reason: 'Should cover king safety');
    });

    test('RED: should have practical opening demonstrations', () {
      final openingsLesson = lessonsData.openingsLesson;
      
      // Should have demonstration steps
      final demonstrationSteps = openingsLesson.steps
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

    test('RED: should have practice steps for opening moves', () {
      final openingsLesson = lessonsData.openingsLesson;
      
      // Should have practice steps
      final practiceSteps = openingsLesson.steps
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

    test('RED: should cover common opening systems', () {
      final openingsLesson = lessonsData.openingsLesson;
      
      // Should cover common openings like Italian Game, Ruy Lopez, etc.
      final stepDescriptions = openingsLesson.steps
          .map((s) => s.description.toLowerCase())
          .join(' ');
      
      // Should mention common openings or opening principles
      expect(stepDescriptions.contains('意大利') || 
             stepDescriptions.contains('italian') ||
             stepDescriptions.contains('西班牙') ||
             stepDescriptions.contains('ruy') ||
             stepDescriptions.contains('开局') ||
             stepDescriptions.contains('opening'), 
             isTrue, reason: 'Should cover common opening systems');
    });

    test('RED: should have proper board states for each step', () {
      final openingsLesson = lessonsData.openingsLesson;
      
      for (final step in openingsLesson.steps) {
        expect(step.boardState, isNotNull, 
               reason: 'Each step should have a board state');
        expect(step.boardState!.length, equals(8), 
               reason: 'Board should have 8 rows');
        expect(step.boardState!.every((row) => row.length == 8), isTrue, 
               reason: 'Each row should have 8 columns');
      }
    });

    test('RED: should have educational instructions for each step', () {
      final openingsLesson = lessonsData.openingsLesson;
      
      for (final step in openingsLesson.steps) {
        expect(step.instructions.isNotEmpty, isTrue, 
               reason: 'Each step should have instructions');
        expect(step.instructions.every((instruction) => instruction.length > 5), isTrue, 
               reason: 'Instructions should be meaningful');
      }
    });

    test('RED: should have success and failure messages for practice steps', () {
      final openingsLesson = lessonsData.openingsLesson;
      
      final practiceSteps = openingsLesson.steps
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

    test('RED: should have highlighted positions for key concepts', () {
      final openingsLesson = lessonsData.openingsLesson;
      
      // At least some steps should have highlighted positions
      final stepsWithHighlights = openingsLesson.steps
          .where((step) => step.highlightPositions != null && step.highlightPositions!.isNotEmpty)
          .toList();
      
      expect(stepsWithHighlights.length, greaterThan(0), 
             reason: 'Should have steps with highlighted positions');
    });
  });
}
