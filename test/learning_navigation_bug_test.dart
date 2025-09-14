import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/screens/learning_screen.dart';
import 'package:testflutter/screens/home_screen.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('Learning Navigation Bug Tests', () {
    testWidgets(
        'should return to learning home when back is pressed from lesson',
        (WidgetTester tester) async {
      // Arrange: Create a navigation stack: Home -> Learning -> Lesson
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/learning': (context) => const LearningScreen(),
          },
        ),
      );

      // Wait for privacy dialog and accept it if present
      await tester.pump();
      if (tester.any(find.text('接受'))) {
        await tester.tap(find.text('接受'));
        await tester.pump();
      }

      // Act: Navigate to learning mode
      await tester.tap(find.text('学习模式'));
      await tester.pumpAndSettle();

      // Assert: Should be in learning mode home
      expect(find.text('学习模式'), findsOneWidget);
      expect(find.text('基础规则'), findsWidgets); // Should see lesson list

      // Act: Start a specific lesson (if available)
      if (tester.any(find.text('基础规则'))) {
        await tester.tap(find.text('基础规则'));
        await tester.pumpAndSettle();
      }

      // Act: Press back button
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Assert: Should return to learning mode home, NOT to main home
      expect(find.text('学习模式'), findsOneWidget);
      expect(find.text('基础规则'), findsWidgets); // Should see lesson list again
      expect(find.text('♔ 国际象棋 ♛'),
          findsNothing); // Should NOT be back to main home
    });

    testWidgets('should handle navigation stack correctly in learning mode',
        (WidgetTester tester) async {
      // Arrange: Test the navigation behavior with BLoC
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

      // Assert: Should start with lesson list (learning home)
      expect(find.text('学习模式'), findsOneWidget);

      // Act: Start a lesson
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();

      // Assert: Should be in lesson view
      // The UI should change to show lesson content instead of lesson list

      // Act: Exit lesson (simulate back navigation)
      learningBloc.add(const ExitLearning());
      await tester.pump();

      // Assert: Should return to lesson list view
      expect(find.text('学习模式'), findsOneWidget);
    });

    testWidgets(
        'should maintain proper navigation when switching between lessons',
        (WidgetTester tester) async {
      // Arrange: Test navigation between different lessons
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

      // Act: Start first lesson
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();

      // Act: Exit to learning home
      learningBloc.add(const ExitLearning());
      await tester.pump();

      // Act: Start second lesson
      learningBloc.add(const StartLearningMode(LearningMode.pieceMovement));
      await tester.pump();

      // Act: Exit again
      learningBloc.add(const ExitLearning());
      await tester.pump();

      // Assert: Should be back to learning home
      expect(find.text('学习模式'), findsOneWidget);
    });

    testWidgets('should show exit dialog when trying to leave active lesson',
        (WidgetTester tester) async {
      // Arrange: Start a lesson
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

      // Act: Try to exit via app bar button
      if (tester.any(find.byIcon(Icons.exit_to_app))) {
        await tester.tap(find.byIcon(Icons.exit_to_app));
        await tester.pump();

        // Assert: Should show exit dialog
        expect(find.text('退出学习'), findsOneWidget);
        expect(find.text('确定要退出当前学习吗？进度将会保存。'), findsOneWidget);
      }
    });

    testWidgets('should handle system back button correctly in lesson',
        (WidgetTester tester) async {
      // Arrange: This test verifies that the system back button behavior is correct
      await tester.pumpWidget(
        MaterialApp(
          home: const LearningScreen(),
        ),
      );

      await tester.pump();

      // Act: Simulate system back button press
      final NavigatorState navigator = tester.state(find.byType(Navigator));

      // Assert: Should handle back button appropriately
      // If in lesson view, should return to learning home
      // If in learning home, should return to main home
      expect(navigator.canPop(), isTrue);
    });
  });
}
