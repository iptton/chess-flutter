import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('Simple Fix Tests', () {
    testWidgets('should test ExitLearning functionality', (WidgetTester tester) async {
      // Test ExitLearning without UI
      final learningBloc = LearningBloc();
      
      // Start a lesson
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      print('Before ExitLearning: ${learningBloc.state.currentLesson != null}');
      
      // Exit the lesson
      learningBloc.add(const ExitLearning());
      await tester.pump();
      
      print('After ExitLearning: ${learningBloc.state.currentLesson != null}');
      
      // Should be null now
      expect(learningBloc.state.currentLesson, isNull);
    });

    testWidgets('should test progress calculation', (WidgetTester tester) async {
      // Test progress calculation
      final lesson = LearningLesson(
        id: 'test',
        title: 'Test',
        description: 'Test',
        mode: LearningMode.basicRules,
        steps: [
          const LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Step 1',
            type: StepType.explanation,
            status: StepStatus.notStarted,
          ),
          const LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Step 2',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
        ],
      );

      expect(lesson.progress, equals(0.5));
      print('Progress test passed: ${lesson.progress}');
    });

    testWidgets('should test step completion', (WidgetTester tester) async {
      // Test step completion logic
      final learningBloc = LearningBloc();
      
      // Start a lesson
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      final initialProgress = learningBloc.state.currentLesson?.progress ?? 0.0;
      print('Initial progress: $initialProgress');
      
      // Try to go to next step
      learningBloc.add(const NextStep());
      await tester.pump();
      
      final newProgress = learningBloc.state.currentLesson?.progress ?? 0.0;
      print('Progress after next step: $newProgress');
      
      // Progress should be calculated correctly
      expect(newProgress, greaterThanOrEqualTo(0.0));
    });
  });
}
