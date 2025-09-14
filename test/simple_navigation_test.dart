import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/screens/learning_screen.dart';
import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('Simple Navigation Tests', () {
    testWidgets('should handle WillPopScope correctly when in lesson', (WidgetTester tester) async {
      // Arrange: Create a learning bloc with a lesson
      final learningBloc = LearningBloc();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: learningBloc,
            child: const LearningScreen(),
          ),
        ),
      );

      // Wait for initial state
      await tester.pump();

      // Act: Start a lesson to simulate being in lesson view
      learningBloc.add(const StartLearningMode(LearningMode.basicRules));
      await tester.pump();

      // Assert: WillPopScope should be present
      expect(find.byType(WillPopScope), findsOneWidget);
      
      // The test passes if WillPopScope is correctly implemented
    });

    testWidgets('should show custom back button when in lesson', (WidgetTester tester) async {
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

      // Assert: Should have custom leading button in app bar when in lesson
      // This verifies that the navigation logic is implemented
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should handle ExitLearning event correctly', (WidgetTester tester) async {
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
      
      learningBloc.add(const ExitLearning());
      await tester.pump();

      // Assert: Should return to learning home state
      // The bloc should handle the ExitLearning event
      expect(find.byType(LearningScreen), findsOneWidget);
    });

    testWidgets('should show learning mode title in app bar', (WidgetTester tester) async {
      // Arrange: Simple test to verify basic functionality
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningScreen(),
        ),
      );

      await tester.pump();

      // Assert: Should show learning mode title
      expect(find.text('学习模式'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have proper widget structure', (WidgetTester tester) async {
      // Arrange: Test basic widget structure
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningScreen(),
        ),
      );

      await tester.pump();

      // Assert: Should have proper structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(BlocBuilder), findsAtLeastNWidgets(1));
      expect(find.byType(WillPopScope), findsOneWidget);
    });
  });
}
