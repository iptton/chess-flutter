import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Debug responsive logic', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(600, 800)),
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final screenSize = MediaQuery.of(context).size;
                final isSmallScreen = screenSize.width < 768;

                print('Screen width: ${screenSize.width}');
                print('Is small screen: $isSmallScreen');

                return Container(
                  decoration: isSmallScreen
                      ? null
                      : const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.red],
                          ),
                        ),
                  child: const Text('Test'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final container = tester.widget<Container>(find.byType(Container));
    print('Container decoration: ${container.decoration}');

    expect(container.decoration, isNull);
  });
}
