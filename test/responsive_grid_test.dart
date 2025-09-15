import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Responsive Grid Logic Tests', () {
    test(
        'RED: Should calculate correct cross axis count for different screen widths',
        () {
      // 移动端 (< 600)
      expect(calculateCrossAxisCount(360), equals(2));
      expect(calculateCrossAxisCount(500), equals(2));

      // 平板 (600-900)
      expect(calculateCrossAxisCount(600), equals(3));
      expect(calculateCrossAxisCount(768), equals(3));
      expect(calculateCrossAxisCount(899), equals(3));

      // 桌面 (900-1400)
      expect(calculateCrossAxisCount(900), equals(4));
      expect(calculateCrossAxisCount(1200), equals(4));
      expect(calculateCrossAxisCount(1399), equals(4));

      // 大桌面 (>= 1400)
      expect(calculateCrossAxisCount(1400), equals(5));
      expect(calculateCrossAxisCount(1920), equals(5));
    });

    test(
        'RED: Should calculate correct aspect ratio for different screen widths',
        () {
      // 移动端应该更高一些
      expect(calculateAspectRatio(360), closeTo(1.2, 0.1));

      // 平板应该稍微方一些
      expect(calculateAspectRatio(768), closeTo(1.1, 0.1));

      // 桌面应该更方一些
      expect(calculateAspectRatio(1200), closeTo(1.0, 0.1));

      // 大桌面应该稍微宽一些
      expect(calculateAspectRatio(1920), closeTo(0.9, 0.1));
    });

    test(
        'RED: Should calculate appropriate spacing for different screen widths',
        () {
      // 移动端
      expect(calculateSpacing(360), equals(16.0));

      // 平板
      expect(calculateSpacing(768), equals(20.0));

      // 桌面
      expect(calculateSpacing(1200), equals(24.0));

      // 大桌面
      expect(calculateSpacing(1920), equals(28.0));
    });

    test('RED: Edge cases should be handled correctly', () {
      // 边界值测试
      expect(calculateCrossAxisCount(599), equals(2)); // 移动端边界
      expect(calculateCrossAxisCount(600), equals(3)); // 平板开始
      expect(calculateCrossAxisCount(899), equals(3)); // 平板边界
      expect(calculateCrossAxisCount(900), equals(4)); // 桌面开始
      expect(calculateCrossAxisCount(1399), equals(4)); // 桌面边界
      expect(calculateCrossAxisCount(1400), equals(5)); // 大桌面开始
    });

    test('RED: Very small and very large screens should be handled', () {
      // 极小屏幕
      expect(calculateCrossAxisCount(200), equals(2));

      // 极大屏幕
      expect(calculateCrossAxisCount(3000), equals(5));
    });
  });
}

// 辅助函数，模拟学习屏幕中的响应式逻辑
int calculateCrossAxisCount(double screenWidth) {
  if (screenWidth < 600) {
    return 2; // 移动端
  } else if (screenWidth < 900) {
    return 3; // 平板
  } else if (screenWidth < 1400) {
    return 4; // 桌面
  } else {
    return 5; // 大桌面
  }
}

double calculateAspectRatio(double screenWidth) {
  if (screenWidth < 600) {
    return 1.2; // 移动端，稍微高一些
  } else if (screenWidth < 900) {
    return 1.1; // 平板，稍微方一些
  } else if (screenWidth < 1400) {
    return 1.0; // 桌面，正方形
  } else {
    return 0.9; // 大桌面，稍微宽一些
  }
}

double calculateSpacing(double screenWidth) {
  if (screenWidth < 600) {
    return 16.0; // 移动端
  } else if (screenWidth < 900) {
    return 20.0; // 平板
  } else if (screenWidth < 1400) {
    return 24.0; // 桌面
  } else {
    return 28.0; // 大桌面
  }
}
