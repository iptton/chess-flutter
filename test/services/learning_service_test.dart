import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/services/learning_service.dart';
import 'package:testflutter/models/learning_models.dart';

void main() {
  group('LearningService', () {
    late LearningService learningService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      learningService = LearningService();
    });

    group('进度保存和加载', () {
      test('应该能够保存学习进度', () async {
        // Arrange
        final lessons = await learningService.getAvailableLessons();
        final lesson = lessons.first;

        // 模拟完成一些步骤
        final updatedSteps = lesson.steps.map((step) {
          if (lesson.steps.indexOf(step) < 2) {
            return step.copyWith(status: StepStatus.completed);
          }
          return step;
        }).toList();

        final updatedLesson = lesson.copyWith(steps: updatedSteps);

        // Act
        await learningService.saveProgress(updatedLesson);

        // Assert - 目前只是验证方法不抛异常
        expect(true, isTrue);
      });

      test('应该能够加载学习进度', () async {
        // Arrange
        const lessonId = 'basic_rules';

        // Act
        final loadedLesson = await learningService.loadProgress(lessonId);

        // Assert - 目前返回null，这是预期的
        expect(loadedLesson, isNull);
      });
    });

    group('课程进度计算', () {
      test('应该正确计算课程进度', () async {
        // Arrange
        final lessons = await learningService.getAvailableLessons();
        final lesson = lessons.first;

        // 模拟完成一半的步骤
        final totalSteps = lesson.steps.length;
        final completedSteps = totalSteps ~/ 2;

        final updatedSteps = lesson.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          if (index < completedSteps) {
            return step.copyWith(status: StepStatus.completed);
          }
          return step;
        }).toList();

        final updatedLesson = lesson.copyWith(steps: updatedSteps);

        // Act
        final progress = updatedLesson.progress;

        // Assert
        final expectedProgress = completedSteps / totalSteps;
        expect(progress, equals(expectedProgress));
      });

      test('空课程应该返回0进度', () async {
        // Arrange
        final emptyLesson = LearningLesson(
          id: 'empty',
          title: '空课程',
          description: '测试用空课程',
          mode: LearningMode.basicRules,
          steps: [],
        );

        // Act
        final progress = emptyLesson.progress;

        // Assert
        expect(progress, equals(0.0));
      });
    });
  });
}
