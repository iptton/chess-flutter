import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/widgets/learning_step_controls.dart';

void main() {
  group('Responsive Learning Controls Tests', () {
    testWidgets('should display compact layout on narrow screens', (WidgetTester tester) async {
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
      // On narrow screens, buttons should be stacked or have smaller text
      expect(find.text('上一步'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);
      expect(find.text('重新开始'), findsOneWidget);
      expect(find.text('提示'), findsOneWidget);
      expect(find.text('跳过'), findsOneWidget);
      
      // Should have proper spacing for mobile
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.padding, equals(const EdgeInsets.all(16)));
    });

    testWidgets('should display expanded layout on wide screens', (WidgetTester tester) async {
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
      // On wide screens, buttons should have more space and possibly different arrangement
      expect(find.text('上一步'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);
      expect(find.text('重新开始'), findsOneWidget);
      expect(find.text('提示'), findsOneWidget);
      expect(find.text('跳过'), findsOneWidget);
    });

    testWidgets('should adapt button sizes based on screen width', (WidgetTester tester) async {
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

    testWidgets('should handle very narrow screens gracefully', (WidgetTester tester) async {
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
      expect(find.text('上一步'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);
    });

    testWidgets('should use appropriate button text for different screen sizes', (WidgetTester tester) async {
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

    testWidgets('should arrange buttons in single row on wide screens', (WidgetTester tester) async {
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

    testWidgets('should maintain accessibility on all screen sizes', (WidgetTester tester) async {
      // Test different screen sizes for accessibility
      final screenSizes = [
        const Size(320, 600),  // Small mobile
        const Size(375, 812),  // iPhone
        const Size(768, 1024), // Tablet
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

        // Assert: Buttons should be tappable and have minimum size
        final buttons = find.byType(ElevatedButton);
        expect(buttons, findsAtLeastNWidgets(1));
        
        // Check that buttons have adequate touch targets
        for (int i = 0; i < tester.widgetList(buttons).length; i++) {
          final buttonSize = tester.getSize(buttons.at(i));
          expect(buttonSize.height, greaterThanOrEqualTo(44.0), 
                 reason: 'Button should meet minimum touch target size on ${size.width}x${size.height}');
        }
      }
    });
  });
}
