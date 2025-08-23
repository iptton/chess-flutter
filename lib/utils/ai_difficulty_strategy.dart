import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 设备类型枚举
enum DeviceType {
  /// Web浏览器 - 高性能
  web,

  /// 桌面设备 (Windows/macOS/Linux) - 高性能
  desktop,

  /// 移动设备 (Android/iOS/HarmonyOS) - 中等性能
  mobile,
}

/// AI难度等级枚举 - 扩展为9个等级
enum AIDifficultyLevel {
  /// 初学者 - 非常简单
  beginner('初学者', 1),

  /// 新手 - 简单
  novice('新手', 2),

  /// 入门 - 较简单
  casual('入门', 3),

  /// 中等 - 标准难度
  intermediate('中等', 4),

  /// 进阶 - 较难
  advanced('进阶', 5),

  /// 专家 - 困难
  expert('专家', 6),

  /// 大师 - 很困难
  master('大师', 7),

  /// 超级大师 - 极难
  grandmaster('超级大师', 8),

  /// 引擎级 - 最高难度
  engine('引擎级', 9);

  const AIDifficultyLevel(this.displayName, this.level);

  final String displayName;
  final int level;
}

/// AI难度配置类
class AIDifficultyConfig {
  /// 思考时间（毫秒）
  final int thinkingTimeMs;

  /// 随机性概率 (0.0-1.0)
  final double randomnessProbability;

  /// 搜索深度限制 (0表示无限制)
  final int searchDepth;

  /// 是否启用开局库
  final bool useOpeningBook;

  /// 是否启用残局库
  final bool useEndgameTablebase;

  /// 评估函数权重调整 (0.5-1.0，越低AI越弱)
  final double evaluationWeight;

  /// 时间管理策略：是否使用动态时间分配
  final bool useDynamicTiming;

  /// 多线程数量
  final int threads;

  const AIDifficultyConfig({
    required this.thinkingTimeMs,
    required this.randomnessProbability,
    required this.searchDepth,
    required this.useOpeningBook,
    required this.useEndgameTablebase,
    required this.evaluationWeight,
    required this.useDynamicTiming,
    required this.threads,
  });
}

/// AI难度策略管理器
class AIDifficultyStrategy {
  static final Random _random = Random();

  /// 获取当前设备类型
  static DeviceType getCurrentDeviceType() {
    if (kIsWeb) {
      return DeviceType.web;
    }

    try {
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        return DeviceType.desktop;
      } else if (Platform.isAndroid || Platform.isIOS) {
        return DeviceType.mobile;
      }
    } catch (e) {
      // 对于HarmonyOS或其他平台，默认作为移动设备处理
      return DeviceType.mobile;
    }

    return DeviceType.mobile;
  }

  /// 根据设备类型和难度等级获取AI配置
  static AIDifficultyConfig getConfigForDifficulty(
    AIDifficultyLevel difficulty,
    DeviceType? deviceType,
  ) {
    deviceType ??= getCurrentDeviceType();

    // 基础配置
    final baseConfig = _getBaseDifficultyConfig(difficulty);

    // 根据设备类型调整配置
    return _adjustConfigForDevice(baseConfig, deviceType, difficulty);
  }

  /// 获取基础难度配置
  static AIDifficultyConfig _getBaseDifficultyConfig(
      AIDifficultyLevel difficulty) {
    switch (difficulty) {
      case AIDifficultyLevel.beginner:
        return const AIDifficultyConfig(
          thinkingTimeMs: 300,
          randomnessProbability: 0.4, // 40% 随机性
          searchDepth: 2,
          useOpeningBook: false,
          useEndgameTablebase: false,
          evaluationWeight: 0.5, // 评估函数权重减半
          useDynamicTiming: false,
          threads: 1,
        );

      case AIDifficultyLevel.novice:
        return const AIDifficultyConfig(
          thinkingTimeMs: 500,
          randomnessProbability: 0.3, // 30% 随机性
          searchDepth: 3,
          useOpeningBook: false,
          useEndgameTablebase: false,
          evaluationWeight: 0.6,
          useDynamicTiming: false,
          threads: 1,
        );

      case AIDifficultyLevel.casual:
        return const AIDifficultyConfig(
          thinkingTimeMs: 800,
          randomnessProbability: 0.2, // 20% 随机性
          searchDepth: 4,
          useOpeningBook: true,
          useEndgameTablebase: false,
          evaluationWeight: 0.7,
          useDynamicTiming: false,
          threads: 1,
        );

      case AIDifficultyLevel.intermediate:
        return const AIDifficultyConfig(
          thinkingTimeMs: 1200,
          randomnessProbability: 0.1, // 10% 随机性
          searchDepth: 5,
          useOpeningBook: true,
          useEndgameTablebase: false,
          evaluationWeight: 0.8,
          useDynamicTiming: true,
          threads: 1,
        );

      case AIDifficultyLevel.advanced:
        return const AIDifficultyConfig(
          thinkingTimeMs: 2000,
          randomnessProbability: 0.05, // 5% 随机性
          searchDepth: 6,
          useOpeningBook: true,
          useEndgameTablebase: true,
          evaluationWeight: 0.9,
          useDynamicTiming: true,
          threads: 2,
        );

      case AIDifficultyLevel.expert:
        return const AIDifficultyConfig(
          thinkingTimeMs: 3000,
          randomnessProbability: 0.02, // 2% 随机性
          searchDepth: 8,
          useOpeningBook: true,
          useEndgameTablebase: true,
          evaluationWeight: 0.95,
          useDynamicTiming: true,
          threads: 2,
        );

      case AIDifficultyLevel.master:
        return const AIDifficultyConfig(
          thinkingTimeMs: 5000,
          randomnessProbability: 0.01, // 1% 随机性
          searchDepth: 10,
          useOpeningBook: true,
          useEndgameTablebase: true,
          evaluationWeight: 0.98,
          useDynamicTiming: true,
          threads: 4,
        );

      case AIDifficultyLevel.grandmaster:
        return const AIDifficultyConfig(
          thinkingTimeMs: 8000,
          randomnessProbability: 0.005, // 0.5% 随机性
          searchDepth: 12,
          useOpeningBook: true,
          useEndgameTablebase: true,
          evaluationWeight: 0.99,
          useDynamicTiming: true,
          threads: 4,
        );

      case AIDifficultyLevel.engine:
        return const AIDifficultyConfig(
          thinkingTimeMs: 15000,
          randomnessProbability: 0.0, // 无随机性
          searchDepth: 0, // 无限制
          useOpeningBook: true,
          useEndgameTablebase: true,
          evaluationWeight: 1.0,
          useDynamicTiming: true,
          threads: 8,
        );
    }
  }

  /// 根据设备类型调整配置
  static AIDifficultyConfig _adjustConfigForDevice(
    AIDifficultyConfig baseConfig,
    DeviceType deviceType,
    AIDifficultyLevel difficulty,
  ) {
    late double timeMultiplier;
    late int maxThreads;

    switch (deviceType) {
      case DeviceType.web:
        // Web端性能较好，但受浏览器限制
        timeMultiplier = 1.0;
        maxThreads = 4;
        break;
      case DeviceType.desktop:
        // 桌面端性能最好
        timeMultiplier = 1.2; // 可以给更多思考时间
        maxThreads = 8;
        break;
      case DeviceType.mobile:
        // 移动端性能受限
        timeMultiplier = 0.6; // 减少思考时间
        maxThreads = 2;
        break;
    }

    // 调整思考时间
    int adjustedThinkingTime =
        (baseConfig.thinkingTimeMs * timeMultiplier).round();

    // 移动端特别限制最低难度的思考时间
    if (deviceType == DeviceType.mobile && difficulty.level <= 3) {
      adjustedThinkingTime = adjustedThinkingTime.clamp(200, 1000);
    }

    // 调整线程数
    int adjustedThreads = baseConfig.threads.clamp(1, maxThreads);

    return AIDifficultyConfig(
      thinkingTimeMs: adjustedThinkingTime,
      randomnessProbability: baseConfig.randomnessProbability,
      searchDepth: baseConfig.searchDepth,
      useOpeningBook: baseConfig.useOpeningBook,
      useEndgameTablebase: baseConfig.useEndgameTablebase,
      evaluationWeight: baseConfig.evaluationWeight,
      useDynamicTiming: baseConfig.useDynamicTiming,
      threads: adjustedThreads,
    );
  }

  /// 应用随机性决策
  static bool shouldUseRandomMove(double randomnessProbability) {
    return _random.nextDouble() < randomnessProbability;
  }

  /// 获取弱化的评估值
  static double applyEvaluationWeight(double originalEval, double weight) {
    // 将评估值按权重调整，模拟较弱的AI判断
    return originalEval * weight + _random.nextGaussian() * (1 - weight) * 0.5;
  }

  /// 获取用户友好的难度描述
  static String getDifficultyDescription(AIDifficultyLevel difficulty) {
    switch (difficulty) {
      case AIDifficultyLevel.beginner:
        return '适合完全不会下棋的新手，AI会犯很多错误';
      case AIDifficultyLevel.novice:
        return '适合刚学会走棋的玩家，有一定挑战性';
      case AIDifficultyLevel.casual:
        return '适合休闲玩家，AI有基本战术意识';
      case AIDifficultyLevel.intermediate:
        return '适合有一定经验的玩家，AI具备中等棋力';
      case AIDifficultyLevel.advanced:
        return '适合进阶玩家，AI具有良好的战术素养';
      case AIDifficultyLevel.expert:
        return '适合高手玩家，AI具备专家级棋力';
      case AIDifficultyLevel.master:
        return '适合资深棋手，AI接近大师水平';
      case AIDifficultyLevel.grandmaster:
        return '适合专业棋手，AI具备超级大师实力';
      case AIDifficultyLevel.engine:
        return '引擎最强模式，适合想要极限挑战的玩家';
    }
  }

  /// 为移动端优化的快速难度选择
  static List<AIDifficultyLevel> getRecommendedDifficultiesForDevice(
      DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        // 移动端推荐较低的难度等级以保证性能
        return [
          AIDifficultyLevel.beginner,
          AIDifficultyLevel.novice,
          AIDifficultyLevel.casual,
          AIDifficultyLevel.intermediate,
          AIDifficultyLevel.advanced,
        ];
      case DeviceType.web:
      case DeviceType.desktop:
        // 桌面端和Web端可以支持所有难度
        return AIDifficultyLevel.values;
    }
  }
}

/// Random扩展，添加高斯分布随机数
extension RandomExtension on Random {
  /// 生成标准正态分布随机数（简化版本）
  double nextGaussian() {
    // 使用Box-Muller变换的简化版本
    final u1 = nextDouble();
    final u2 = nextDouble();
    final z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
    return z0;
  }
}
