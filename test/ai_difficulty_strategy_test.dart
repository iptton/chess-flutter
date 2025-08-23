import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/utils/ai_difficulty_strategy.dart';
import 'package:testflutter/services/chess_ai.dart';

void main() {
  group('AI Difficulty Strategy Tests', () {
    test('设备类型检测应该正确工作', () {
      // 这个测试在不同环境下可能有不同结果
      final deviceType = AIDifficultyStrategy.getCurrentDeviceType();
      expect(
          [DeviceType.web, DeviceType.desktop, DeviceType.mobile]
              .contains(deviceType),
          true);
    });

    test('所有难度等级都应该有有效的配置', () {
      for (final difficulty in AIDifficultyLevel.values) {
        for (final deviceType in DeviceType.values) {
          final config = AIDifficultyStrategy.getConfigForDifficulty(
              difficulty, deviceType);

          // 验证基本配置参数
          expect(config.thinkingTimeMs, greaterThan(0));
          expect(config.randomnessProbability, greaterThanOrEqualTo(0.0));
          expect(config.randomnessProbability, lessThanOrEqualTo(1.0));
          expect(config.searchDepth, greaterThanOrEqualTo(0));
          expect(config.evaluationWeight, greaterThanOrEqualTo(0.5));
          expect(config.evaluationWeight, lessThanOrEqualTo(1.0));
          expect(config.threads, greaterThan(0));
        }
      }
    });

    test('难度等级应该按预期递增', () {
      final deviceType = DeviceType.desktop;
      AIDifficultyConfig? previousConfig;

      for (final difficulty in AIDifficultyLevel.values) {
        final config =
            AIDifficultyStrategy.getConfigForDifficulty(difficulty, deviceType);

        if (previousConfig != null) {
          // 思考时间应该递增（除非是引擎级）
          if (difficulty != AIDifficultyLevel.engine) {
            expect(config.thinkingTimeMs,
                greaterThanOrEqualTo(previousConfig.thinkingTimeMs));
          }

          // 随机性应该递减
          expect(config.randomnessProbability,
              lessThanOrEqualTo(previousConfig.randomnessProbability));

          // 评估权重应该递增
          expect(config.evaluationWeight,
              greaterThanOrEqualTo(previousConfig.evaluationWeight));
        }

        previousConfig = config;
      }
    });

    test('移动端配置应该比桌面端更保守', () {
      final difficulty = AIDifficultyLevel.expert;

      final mobileConfig = AIDifficultyStrategy.getConfigForDifficulty(
          difficulty, DeviceType.mobile);
      final desktopConfig = AIDifficultyStrategy.getConfigForDifficulty(
          difficulty, DeviceType.desktop);

      // 移动端思考时间应该更短
      expect(
          mobileConfig.thinkingTimeMs, lessThan(desktopConfig.thinkingTimeMs));

      // 移动端线程数应该更少
      expect(mobileConfig.threads, lessThanOrEqualTo(desktopConfig.threads));
    });

    test('推荐难度应该根据设备类型调整', () {
      final mobileRecommended =
          AIDifficultyStrategy.getRecommendedDifficultiesForDevice(
              DeviceType.mobile);
      final desktopRecommended =
          AIDifficultyStrategy.getRecommendedDifficultiesForDevice(
              DeviceType.desktop);

      // 移动端推荐的难度数量应该少于桌面端
      expect(mobileRecommended.length,
          lessThanOrEqualTo(desktopRecommended.length));

      // 所有推荐的难度都应该存在于完整列表中
      expect(
          mobileRecommended.every((d) => AIDifficultyLevel.values.contains(d)),
          true);
      expect(
          desktopRecommended.every((d) => AIDifficultyLevel.values.contains(d)),
          true);
    });

    test('随机性决策应该按概率工作', () {
      // 测试极端情况
      expect(AIDifficultyStrategy.shouldUseRandomMove(0.0), false);

      // 测试多次调用的统计结果
      int randomCount = 0;
      const int iterations = 1000;
      const double probability = 0.3;

      for (int i = 0; i < iterations; i++) {
        if (AIDifficultyStrategy.shouldUseRandomMove(probability)) {
          randomCount++;
        }
      }

      // 结果应该接近期望概率（允许10%的误差）
      final actualProbability = randomCount / iterations;
      expect(actualProbability, closeTo(probability, 0.1));
    });

    test('评估权重应用应该正确工作', () {
      const double originalEval = 1.0;
      const double weight = 0.8;

      final adjustedEval =
          AIDifficultyStrategy.applyEvaluationWeight(originalEval, weight);

      // 调整后的评估值应该在合理范围内
      expect(adjustedEval, greaterThan(0.0));
      expect(adjustedEval, lessThan(2.0));
    });

    test('难度描述应该对所有等级都可用', () {
      for (final difficulty in AIDifficultyLevel.values) {
        final description =
            AIDifficultyStrategy.getDifficultyDescription(difficulty);
        expect(description.isNotEmpty, true);
        expect(description.length, greaterThan(10)); // 描述应该足够详细
      }
    });
  });

  group('ChessAI Integration Tests', () {
    test('ChessAI应该能够使用新的难度系统', () {
      for (final difficulty in [
        AIDifficultyLevel.beginner,
        AIDifficultyLevel.intermediate,
        AIDifficultyLevel.expert
      ]) {
        final ai = ChessAI.advanced(advancedDifficulty: difficulty);

        expect(ai.advancedDifficulty, equals(difficulty));
        expect(ai.config.thinkingTimeMs, greaterThan(0));

        // 验证难度信息
        final info = ai.getDifficultyInfo();
        expect(info['level'], equals(difficulty.level));
        expect(info['displayName'], equals(difficulty.displayName));
        expect(info['thinkingTimeMs'], equals(ai.config.thinkingTimeMs));
      }
    });

    test('向后兼容性应该正常工作', () {
      for (final oldDifficulty in AIDifficulty.values) {
        final ai = ChessAI(difficulty: oldDifficulty);

        // 应该能够正确映射到新的难度系统
        expect(ai.advancedDifficulty, isA<AIDifficultyLevel>());
        expect(ai.difficulty, equals(oldDifficulty));

        // 配置应该有效
        expect(ai.config.thinkingTimeMs, greaterThan(0));
      }
    });

    test('推荐难度应该根据当前设备返回', () {
      final recommendations = ChessAI.getRecommendedDifficulties();

      expect(recommendations.isNotEmpty, true);
      expect(recommendations.every((d) => AIDifficultyLevel.values.contains(d)),
          true);
    });

    test('难度等级映射应该正确', () {
      // 测试旧难度到新难度的映射
      expect(AIDifficulty.easy.toNewDifficultyLevel(),
          equals(AIDifficultyLevel.novice));
      expect(AIDifficulty.medium.toNewDifficultyLevel(),
          equals(AIDifficultyLevel.intermediate));
      expect(AIDifficulty.hard.toNewDifficultyLevel(),
          equals(AIDifficultyLevel.expert));
    });
  });

  group('Performance Tests', () {
    test('配置生成应该足够快', () {
      final stopwatch = Stopwatch()..start();

      // 生成大量配置
      for (int i = 0; i < 1000; i++) {
        for (final difficulty in AIDifficultyLevel.values) {
          AIDifficultyStrategy.getConfigForDifficulty(
              difficulty, DeviceType.mobile);
        }
      }

      stopwatch.stop();

      // 应该在合理时间内完成（小于100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Edge Cases', () {
    test('应该处理空值和边界情况', () {
      // 测试设备类型为null的情况
      expect(
          () => AIDifficultyStrategy.getConfigForDifficulty(
              AIDifficultyLevel.intermediate, null),
          returnsNormally);

      // 测试极端概率值
      expect(AIDifficultyStrategy.shouldUseRandomMove(0.0), false);
      expect(AIDifficultyStrategy.shouldUseRandomMove(1.0), true);
    });

    test('评估权重边界值应该正确处理', () {
      const double originalEval = 1.0;

      // 最小权重
      final minWeightResult =
          AIDifficultyStrategy.applyEvaluationWeight(originalEval, 0.5);
      expect(minWeightResult, isA<double>());

      // 最大权重
      final maxWeightResult =
          AIDifficultyStrategy.applyEvaluationWeight(originalEval, 1.0);
      expect(maxWeightResult, isA<double>());
    });
  });
}
