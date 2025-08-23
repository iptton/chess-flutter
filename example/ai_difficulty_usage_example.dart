// AI难度分级策略使用示例

import '../lib/services/chess_ai.dart';
import '../lib/utils/ai_difficulty_strategy.dart';
import '../lib/models/chess_models.dart';

void main() {
  print('=== AI难度分级策略使用示例 ===\n');

  // 1. 设备检测示例
  demonstrateDeviceDetection();

  // 2. 传统难度使用示例
  demonstrateTraditionalDifficulty();

  // 3. 新的高级难度使用示例
  demonstrateAdvancedDifficulty();

  // 4. 配置信息查看示例
  demonstrateConfigurationDetails();

  // 5. 推荐难度示例
  demonstrateRecommendedDifficulties();

  // 6. 向后兼容性示例
  demonstrateBackwardCompatibility();
}

void demonstrateDeviceDetection() {
  print('📱 设备检测示例');
  print('─' * 50);

  final deviceType = AIDifficultyStrategy.getCurrentDeviceType();
  print('当前设备类型: ${deviceType.name}');

  String deviceDescription;
  switch (deviceType) {
    case DeviceType.web:
      deviceDescription = '浏览器环境 - 中等性能，JavaScript限制';
      break;
    case DeviceType.desktop:
      deviceDescription = '桌面环境 - 高性能，资源充足';
      break;
    case DeviceType.mobile:
      deviceDescription = '移动环境 - 性能受限，需要节能';
      break;
  }

  print('设备特征: $deviceDescription');
  print('');
}

void demonstrateTraditionalDifficulty() {
  print('🎮 传统难度使用示例（向后兼容）');
  print('─' * 50);

  for (final difficulty in AIDifficulty.values) {
    final ai = ChessAI(difficulty: difficulty);
    final info = ai.getDifficultyInfo();

    print('传统难度: ${difficulty.name}');
    print('  → 映射到新系统: ${ai.advancedDifficulty.displayName}');
    print('  → 思考时间: ${info['thinkingTimeMs']}ms');
    print(
        '  → 随机性: ${(info['randomnessProbability'] * 100).toStringAsFixed(1)}%');
    print('  → 描述: ${ai.getDifficultyDescription()}');
    print('');
  }
}

void demonstrateAdvancedDifficulty() {
  print('🧠 高级难度使用示例（新系统）');
  print('─' * 50);

  // 展示几个典型的难度级别
  final sampleDifficulties = [
    AIDifficultyLevel.beginner,
    AIDifficultyLevel.intermediate,
    AIDifficultyLevel.expert,
    AIDifficultyLevel.engine,
  ];

  for (final difficulty in sampleDifficulties) {
    final ai = ChessAI.advanced(advancedDifficulty: difficulty);
    final info = ai.getDifficultyInfo();

    print('高级难度: ${difficulty.displayName} (级别 ${difficulty.level})');
    print('  → 思考时间: ${info['thinkingTimeMs']}ms');
    print(
        '  → 随机性: ${(info['randomnessProbability'] * 100).toStringAsFixed(1)}%');
    print(
        '  → 搜索深度: ${info['searchDepth'] == 0 ? "无限制" : "${info['searchDepth']}层"}');
    print('  → 开局库: ${info['useOpeningBook'] ? "启用" : "禁用"}');
    print('  → 残局库: ${info['useEndgameTablebase'] ? "启用" : "禁用"}');
    print('  → 线程数: ${info['threads']}');
    print('  → 描述: ${ai.getDifficultyDescription()}');
    print('');
  }
}

void demonstrateConfigurationDetails() {
  print('⚙️ 配置信息详细示例');
  print('─' * 50);

  final deviceType = AIDifficultyStrategy.getCurrentDeviceType();
  final difficulty = AIDifficultyLevel.expert;

  print('难度等级: ${difficulty.displayName}');
  print('设备类型: ${deviceType.name}');
  print('');

  // 显示不同设备类型下的配置差异
  for (final device in DeviceType.values) {
    final config =
        AIDifficultyStrategy.getConfigForDifficulty(difficulty, device);
    print('${device.name.padRight(8)} 设备配置:');
    print('  思考时间: ${config.thinkingTimeMs}ms');
    print('  线程数量: ${config.threads}');
    print('  动态时间: ${config.useDynamicTiming ? "启用" : "禁用"}');
    print('');
  }
}

void demonstrateRecommendedDifficulties() {
  print('📋 推荐难度示例');
  print('─' * 50);

  for (final deviceType in DeviceType.values) {
    final recommended =
        AIDifficultyStrategy.getRecommendedDifficultiesForDevice(deviceType);

    print('${deviceType.name} 推荐难度:');
    for (final difficulty in recommended) {
      print('  • ${difficulty.displayName} (级别 ${difficulty.level})');
    }
    print('');
  }
}

void demonstrateBackwardCompatibility() {
  print('🔄 向后兼容性示例');
  print('─' * 50);

  // 旧系统API
  final oldAI = ChessAI(difficulty: AIDifficulty.medium);
  print('旧API创建的AI:');
  print('  传统难度: ${oldAI.difficulty.name}');
  print('  对应新难度: ${oldAI.advancedDifficulty.displayName}');

  // 新系统API
  final newAI = ChessAI.advanced(advancedDifficulty: AIDifficultyLevel.expert);
  print('');
  print('新API创建的AI:');
  print('  高级难度: ${newAI.advancedDifficulty.displayName}');
  print('  兼容传统: ${newAI.difficulty.name}');

  print('');
  print('两种方式创建的AI都可以正常使用，保证了向后兼容性。');
  print('');
}

// 游戏中的实际使用示例
void gameUsageExample() {
  print('🎯 游戏中的实际使用示例');
  print('─' * 50);

  // 场景1: 新手玩家
  print('场景1: 新手玩家选择简单模式');
  final beginnerAI =
      ChessAI.advanced(advancedDifficulty: AIDifficultyLevel.beginner);
  print('AI配置: ${beginnerAI.getDifficultyDescription()}');

  // 场景2: 经验玩家
  print('');
  print('场景2: 经验玩家选择进阶模式');
  final advancedAI =
      ChessAI.advanced(advancedDifficulty: AIDifficultyLevel.advanced);
  print('AI配置: ${advancedAI.getDifficultyDescription()}');

  // 场景3: 高手挑战
  print('');
  print('场景3: 高手挑战引擎级');
  final engineAI =
      ChessAI.advanced(advancedDifficulty: AIDifficultyLevel.engine);
  print('AI配置: ${engineAI.getDifficultyDescription()}');

  print('');
  print('每个场景下AI都会根据设备性能自动调整参数，提供最佳的游戏体验。');
}

// 性能监控示例
void performanceMonitoringExample() {
  print('📊 性能监控示例');
  print('─' * 50);

  final stopwatch = Stopwatch();

  // 测试配置生成性能
  stopwatch.start();
  for (int i = 0; i < 100; i++) {
    for (final difficulty in AIDifficultyLevel.values) {
      AIDifficultyStrategy.getConfigForDifficulty(difficulty, null);
    }
  }
  stopwatch.stop();

  print('生成900个配置耗时: ${stopwatch.elapsedMilliseconds}ms');
  print(
      '平均每个配置: ${(stopwatch.elapsedMilliseconds / 900).toStringAsFixed(2)}ms');

  // 测试随机性决策性能
  stopwatch.reset();
  stopwatch.start();

  int randomCount = 0;
  for (int i = 0; i < 10000; i++) {
    if (AIDifficultyStrategy.shouldUseRandomMove(0.2)) {
      randomCount++;
    }
  }

  stopwatch.stop();

  print('');
  print('10000次随机决策耗时: ${stopwatch.elapsedMilliseconds}ms');
  print('随机性命中率: ${(randomCount / 10000 * 100).toStringAsFixed(1)}% (期望20%)');
}

// UI集成示例
void uiIntegrationExample() {
  print('🖥️ UI集成示例');
  print('─' * 50);

  print('示例代码:');
  print('''
// 在游戏设置界面中
void showDifficultySelector() {
  showDialog(
    context: context,
    builder: (context) => AIDifficultySelector(
      currentDifficulty: AIDifficultyLevel.intermediate,
      showAdvancedOptions: true,
      onDifficultySelected: (difficulty) {
        // 创建新的AI实例
        final ai = ChessAI.advanced(advancedDifficulty: difficulty);
        
        // 开始游戏
        startGameWithAI(ai);
      },
    ),
  );
}

// 或者使用快速选择器
Widget buildQuickSelector() {
  return QuickDifficultySelector(
    currentDifficulty: currentDifficulty,
    onDifficultyChanged: (difficulty) {
      setState(() {
        currentDifficulty = difficulty;
      });
    },
  );
}
''');
}
