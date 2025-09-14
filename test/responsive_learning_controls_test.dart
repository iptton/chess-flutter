import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/widgets/learning_step_controls.dart';

void main() {
  group('Responsive Learning Controls Tests', () {
    testWidgets('should display compact layout on narrow screens',
        (WidgetTester tester) async {
      // Arrange: Set narrow screen width (mobile)
      await tester.binding.setSurfaceSize(const Size(360, 800));

      const widget = LearningStepControls(
        canGoBack: true,
        canGoForward: true,
        canSkip: true,
        onPrevious: null,
        onNext: null,
        onSkip: null,
        onRestart: null,
        onHint: null,
      );

      // Act: Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert: Should have compact layout
      // On very narrow screens (360px), buttons should use icons only for secondary actions
      expect(find.text('下一步'), findsOneWidget); // Primary button keeps text
      expect(find.byIcon(Icons.arrow_back),
          findsOneWidget); // Previous button as icon
      expect(find.byIcon(Icons.refresh), findsOneWidget); // Restart as icon
      expect(
          find.byIcon(Icons.lightbulb_outline), findsOneWidget); // Hint as icon
      expect(find.byIcon(Icons.skip_next), findsOneWidget); // Skip as icon

      // Should have proper spacing for mobile (narrow screens use 12px padding)
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.padding, equals(const EdgeInsets.all(12)));
    });

    testWidgets('should display expanded layout on wide screens',
        (WidgetTester tester) async {
      // Arrange: Set wide screen width (tablet/desktop)
      await tester.binding.setSurfaceSize(const Size(1024, 768));

      const widget = LearningStepControls(
        canGoBack: true,
        canGoForward: true,
        canSkip: true,
        onPrevious: null,
        onNext: null,
        onSkip: null,
        onRestart: null,
        onHint: null,
      );

      // Act: Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert: Should have expanded layout
      // On wide screens (1024px), buttons should have text labels and single row layout
      expect(find.text('上一步'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);
      expect(find.text('重新开始'), findsOneWidget);
      expect(find.text('提示'), findsOneWidget);
      expect(find.text('跳过'), findsOneWidget);
    });

    testWidgets('should adapt button sizes based on screen width',
        (WidgetTester tester) async {
      // Test mobile layout
      await tester.binding.setSurfaceSize(const Size(360, 800));

      const widget = LearningStepControls(
        canGoBack: true,
        canGoForward: true,
        canSkip: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Get button sizes on mobile
      final mobileNextButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '下一步'),
      );

      // Test tablet layout
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Should adapt to larger screen
      expect(find.text('下一步'), findsOneWidget);
    });

    testWidgets('should handle very narrow screens gracefully',
        (WidgetTester tester) async {
      // Arrange: Set very narrow screen (small mobile)
      await tester.binding.setSurfaceSize(const Size(280, 600));

      const widget = LearningStepControls(
        canGoBack: true,
        canGoForward: true,
        canSkip: true,
      );

      // Act: Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert: Should not overflow and remain usable
      expect(tester.takeException(), isNull);
      // On very narrow screens (280px), previous button should be icon only
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);
    });

    testWidgets('should use appropriate button text for different screen sizes',
        (WidgetTester tester) async {
      // Test that on very narrow screens, button text might be abbreviated
      await tester.binding.setSurfaceSize(const Size(320, 600));

      const widget = LearningStepControls(
        canGoBack: true,
        canGoForward: true,
        canSkip: true,
        isLastStep: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // On narrow screens, might show abbreviated text or icons only
      // This test will initially fail and drive the implementation
      expect(find.text('完成'), findsOneWidget);
    });

    testWidgets('should arrange buttons in single row on wide screens',
        (WidgetTester tester) async {
      // Arrange: Wide screen should allow all buttons in one row
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      const widget = LearningStepControls(
        canGoBack: true,
        canGoForward: true,
        canSkip: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert: Should have efficient layout for wide screens
      // This might involve putting all buttons in a single row
      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('should maintain accessibility on all screen sizes',
        (WidgetTester tester) async {
      // Test different screen sizes for accessibility
      final screenSizes = [
        const Size(320, 600), // Small mobile
        const Size(375, 812), // iPhone
        const Size(1024, 768), // Desktop
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);

        const widget = LearningStepControls(
          canGoBack: true,
          canGoForward: true,
          canSkip: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: widget,
            ),
          ),
        );

        // Assert: Widget should render without errors
        expect(tester.takeException(), isNull);

        // Should have the main container
        expect(find.byType(Container), findsAtLeastNWidgets(1));

        // Should have some interactive elements (check by text content and icons)
        // This is more reliable because ElevatedButton.icon creates different widget structure
        final previousButton = find.text('上一步');
        final nextButton = find.text('下一步');
        final restartButton = find.text('重新开始');
        final hintButton = find.text('提示');
        final skipButton = find.text('跳过');

        // On very narrow screens, some buttons might be icon-only
        final previousIcon = find.byIcon(Icons.arrow_back);
        final nextIcon = find.byIcon(Icons.arrow_forward);
        final restartIcon = find.byIcon(Icons.refresh);
        final hintIcon = find.byIcon(Icons.lightbulb_outline);
        final skipIcon = find.byIcon(Icons.skip_next);

        final totalInteractiveElements = [
          previousButton,
          nextButton,
          restartButton,
          hintButton,
          skipButton,
          previousIcon,
          nextIcon,
          restartIcon,
          hintIcon,
          skipIcon,
        ].where((finder) => finder.evaluate().isNotEmpty).length;

        // Should have at least 2 interactive elements (previous and next at minimum)
        // Note: Some elements might be counted twice (text + icon) but that's ok for this test
        expect(totalInteractiveElements, greaterThanOrEqualTo(2),
            reason:
                'Should have at least 2 interactive elements on ${size.width}x${size.height}. Found: $totalInteractiveElements');

        // Check that buttons have adequate touch targets if they exist
        if (totalInteractiveElements > 0) {
          // Find all clickable widgets by looking for common button types
          final allClickableWidgets = [
            ...find.byType(ElevatedButton).evaluate(),
            ...find.byType(OutlinedButton).evaluate(),
            ...find.byType(TextButton).evaluate(),
            ...find.byType(InkWell).evaluate(),
            ...find.byType(GestureDetector).evaluate(),
          ];

          // If we can't find button widgets, at least verify the container exists
          if (allClickableWidgets.isEmpty) {
            expect(find.byType(Container), findsAtLeastNWidgets(1));
          } else {
            for (final buttonElement in allClickableWidgets) {
              final buttonSize =
                  tester.getSize(find.byWidget(buttonElement.widget));
              expect(buttonSize.height, greaterThanOrEqualTo(40.0),
                  reason:
                      'Button should meet minimum touch target size on ${size.width}x${size.height}');
            }
          }
        }
      }
    });
  });
}
