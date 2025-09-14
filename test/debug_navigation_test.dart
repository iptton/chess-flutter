import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/screens/learning_screen.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('Debug Navigation Tests', () {
    testWidgets('should debug learning screen state', (WidgetTester tester) async {
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
      print('Initial state: ${learningBloc.state}');

      // Act: Start a lesson
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      print('After StartLearningMode: ${learningBloc.state}');
      print('Current lesson: ${learningBloc.state.currentLesson}');
      print('Is loading: ${learningBloc.state.isLoading}');
      print('Error: ${learningBloc.state.error}');

      // Check what widgets are actually present
      final allWidgets = find.byType(Widget);
      print('Total widgets found: ${allWidgets.evaluate().length}');

      final appBars = find.byType(AppBar);
      print('AppBars found: ${appBars.evaluate().length}');

      final iconButtons = find.byType(IconButton);
      print('IconButtons found: ${iconButtons.evaluate().length}');

      final backIcons = find.byIcon(Icons.arrow_back);
      print('Back icons found: ${backIcons.evaluate().length}');

      // Print all icon buttons
      for (final element in iconButtons.evaluate()) {
        final widget = element.widget as IconButton;
        print('IconButton found with icon: ${widget.icon}');
      }

      // Test ExitLearning
      if (learningBloc.state.currentLesson != null) {
        learningBloc.add(const ExitLearning());
        await tester.pump();
        print('After ExitLearning: ${learningBloc.state}');
        print('Current lesson after exit: ${learningBloc.state.currentLesson}');
      }
    });

    testWidgets('should test lesson progress calculation', (WidgetTester tester) async {
      // Create a mock lesson with steps
      final lesson = LearningLesson(
        id: 'test',
        title: 'Test Lesson',
        description: 'Test Description',
        mode: LearningMode.basicRules,
        steps: [
          const LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'First step',
            type: StepType.explanation,
            status: StepStatus.notStarted,
          ),
          const LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Second step',
            type: StepType.explanation,
            status: StepStatus.completed,
          ),
          const LearningStep(
            id: 'step3',
            title: 'Step 3',
            description: 'Third step',
            type: StepType.explanation,
            status: StepStatus.notStarted,
          ),
        ],
      );

      print('Lesson progress: ${lesson.progress}');
      print('Expected progress: ${1/3}');
      print('Steps: ${lesson.steps.map((s) => '${s.title}: ${s.status}').join(', ')}');

      expect(lesson.progress, equals(1/3));
    });
  });
}
