import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/screens/learning_screen.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('Learning Navigation and Progress Bug Tests', () {
    testWidgets('RED: should allow back navigation from lesson to learning home', (WidgetTester tester) async {
      // Arrange: Create a learning bloc
      final learningBloc = LearningBloc();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: const LearningScreen(),
          ),
        ),
      );

      await tester.pump();

      // Act: Start a lesson
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should be in lesson view now
      expect(learningBloc.state.currentLesson, isNotNull);

      // Try to go back using the back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget, reason: 'Should have custom back button when in lesson');

      await tester.tap(backButton);
      await tester.pump();

      // Assert: Should return to learning home (currentLesson should be null)
      expect(learningBloc.state.currentLesson, isNull, reason: 'Should return to learning home');
    });

    testWidgets('RED: should show correct progress percentage for lesson', (WidgetTester tester) async {
      // Arrange: Create a learning bloc
      final learningBloc = LearningBloc();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: const LearningScreen(),
          ),
        ),
      );

      await tester.pump();

      // Act: Start a lesson
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert: Should show progress greater than 0% if lesson has steps
      final lesson = learningBloc.state.currentLesson;
      expect(lesson, isNotNull);
      expect(lesson!.steps.isNotEmpty, isTrue, reason: 'Lesson should have steps');
      
      // Progress should be calculated correctly
      final expectedProgress = lesson.progress;
      expect(expectedProgress, greaterThanOrEqualTo(0.0), reason: 'Progress should be non-negative');
      
      // Check if progress is displayed in UI
      final progressText = find.textContaining('% 完成');
      expect(progressText, findsAtLeastNWidgets(1), reason: 'Should display progress percentage');
    });

    testWidgets('RED: should update progress when completing steps', (WidgetTester tester) async {
      // Arrange: Create a learning bloc
      final learningBloc = LearningBloc();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: const LearningScreen(),
          ),
        ),
      );

      await tester.pump();

      // Act: Start a lesson
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final initialProgress = learningBloc.state.currentLesson?.progress ?? 0.0;

      // Complete a step (simulate)
      learningBloc.add(const NextStep());
      await tester.pump();

      final updatedProgress = learningBloc.state.currentLesson?.progress ?? 0.0;

      // Assert: Progress should increase or stay the same
      expect(updatedProgress, greaterThanOrEqualTo(initialProgress), 
             reason: 'Progress should not decrease when completing steps');
    });

    testWidgets('RED: should handle ExitLearning event correctly', (WidgetTester tester) async {
      // Arrange: Create a learning bloc
      final learningBloc = LearningBloc();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: const LearningScreen(),
          ),
        ),
      );

      await tester.pump();

      // Act: Start a lesson then exit
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(learningBloc.state.currentLesson, isNotNull, reason: 'Should be in lesson');

      learningBloc.add(const ExitLearning());
      await tester.pump();

      // Assert: Should exit to learning home
      expect(learningBloc.state.currentLesson, isNull, reason: 'Should exit to learning home');
    });

    testWidgets('RED: should show lesson list when not in lesson', (WidgetTester tester) async {
      // Arrange: Simple test to verify lesson list display
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Assert: Should show lesson selection interface
      expect(find.byType(LearningScreen), findsOneWidget);
      // Should not be in lesson mode initially
      expect(find.byIcon(Icons.arrow_back), findsNothing, reason: 'Should not have custom back button in lesson list');
    });
  });
}
