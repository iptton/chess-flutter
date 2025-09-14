import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('Learning Completion Bug Tests', () {
    late LearningBloc bloc;

    setUp(() {
      bloc = LearningBloc();
    });

    tearDown(() {
      bloc.close();
    });

    test('should enable completion button on last step', () async {
      // Arrange: Create a simple lesson with 2 steps
      final lesson = LearningLesson(
        id: 'test-lesson',
        title: 'Test Lesson',
        description: 'A test lesson',
        mode: LearningMode.basicRules,
        steps: const [
          LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'First step',
            type: StepType.explanation,
            instructions: ['Learn the basics'],
            status: StepStatus.completed,
          ),
          LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Second step',
            type: StepType.explanation,
            instructions: ['Complete the lesson'],
            status: StepStatus.notStarted,
          ),
        ],
        currentStepIndex: 1, // On the last step
      );

      // Act: Set the lesson in the bloc
      bloc.emit(LearningState(
        currentLesson: lesson,
        isLoading: false,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Check that we're on the last step
      expect(bloc.state.currentLesson?.currentStepIndex, equals(1));
      expect(bloc.state.currentLesson?.steps.length, equals(2));
      
      // The completion button should be enabled (isLastStep should be true)
      final isLastStep = bloc.state.currentLesson!.currentStepIndex == 
                        bloc.state.currentLesson!.steps.length - 1;
      expect(isLastStep, isTrue);
    });

    test('should complete lesson when CompleteLesson event is triggered', () async {
      // Arrange: Create a lesson
      final lesson = LearningLesson(
        id: 'test-lesson',
        title: 'Test Lesson',
        description: 'A test lesson',
        mode: LearningMode.basicRules,
        steps: const [
          LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'First step',
            type: StepType.explanation,
            instructions: ['Learn the basics'],
            status: StepStatus.completed,
          ),
        ],
        currentStepIndex: 0,
      );

      bloc.emit(LearningState(
        currentLesson: lesson,
        isLoading: false,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Act: Trigger lesson completion
      bloc.add(const CompleteLesson());

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Lesson should be marked as completed
      // Note: This will fail initially because _onCompleteLesson is not implemented
      expect(bloc.state.currentLesson?.isCompleted, isTrue);
    });

    test('should save progress when SaveProgress event is triggered', () async {
      // Arrange: Create a lesson with some progress
      final lesson = LearningLesson(
        id: 'test-lesson',
        title: 'Test Lesson',
        description: 'A test lesson',
        mode: LearningMode.basicRules,
        steps: const [
          LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'First step',
            type: StepType.explanation,
            instructions: ['Learn the basics'],
            status: StepStatus.completed,
          ),
        ],
        currentStepIndex: 0,
      );

      bloc.emit(LearningState(
        currentLesson: lesson,
        isLoading: false,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Act: Trigger save progress
      bloc.add(const SaveProgress());

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Progress should be saved (this will initially fail)
      // We can't easily test the actual saving without mocking, but we can test
      // that the event doesn't cause errors
      expect(bloc.state.error, isNull);
    });

    test('should handle NextStep correctly when reaching last step', () async {
      // Arrange: Create a lesson with 2 steps, currently on first step
      final lesson = LearningLesson(
        id: 'test-lesson',
        title: 'Test Lesson',
        description: 'A test lesson',
        mode: LearningMode.basicRules,
        steps: const [
          LearningStep(
            id: 'step1',
            title: 'Step 1',
            description: 'First step',
            type: StepType.explanation,
            instructions: ['Learn the basics'],
            status: StepStatus.completed,
          ),
          LearningStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Second step',
            type: StepType.explanation,
            instructions: ['Complete the lesson'],
            status: StepStatus.notStarted,
          ),
        ],
        currentStepIndex: 0, // On the first step
      );

      bloc.emit(LearningState(
        currentLesson: lesson,
        isLoading: false,
      ));

      await Future.delayed(const Duration(milliseconds: 100));

      // Act: Go to next step
      bloc.add(const NextStep());

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Should be on the last step now
      expect(bloc.state.currentLesson?.currentStepIndex, equals(1));

      // Act: Try to go to next step again (should trigger completion)
      bloc.add(const NextStep());

      await Future.delayed(const Duration(milliseconds: 100));

      // Assert: Should have triggered lesson completion
      // This will depend on the implementation of _onCompleteLesson
    });
  });
}
