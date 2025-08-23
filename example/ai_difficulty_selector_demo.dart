import 'package:flutter/material.dart';
import '../lib/widgets/ai_difficulty_selector.dart';
import '../lib/utils/ai_difficulty_strategy.dart';

/// AI难度选择器滚动功能演示
class AIDifficultySelectorDemo extends StatefulWidget {
  const AIDifficultySelectorDemo({super.key});

  @override
  State<AIDifficultySelectorDemo> createState() =>
      _AIDifficultySelectorDemoState();
}

class _AIDifficultySelectorDemoState extends State<AIDifficultySelectorDemo> {
  AIDifficultyLevel selectedDifficulty = AIDifficultyLevel.intermediate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI难度选择器演示'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 当前选择显示
            _buildCurrentSelection(),

            const SizedBox(height: 24),

            // 演示说明
            _buildDemoDescription(),

            const SizedBox(height: 24),

            // 按钮区域
            _buildActionButtons(),

            const Spacer(),

            // 底部信息
            _buildFooterInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSelection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '当前选择的AI难度',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDifficultyIcon(selectedDifficulty),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDifficulty.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AIDifficultyStrategy.getDifficultyDescription(
                            selectedDifficulty),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildDifficultyBadge(selectedDifficulty),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoDescription() {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  '滚动功能改进说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              '📱 自适应高度',
              '对话框高度自动适应屏幕大小，最大高度为屏幕的80%',
            ),
            _buildFeatureItem(
              '📜 流畅滚动',
              '内容超出对话框高度时自动启用滚动，支持触摸和鼠标滚轮',
            ),
            _buildFeatureItem(
              '🎯 紧凑布局',
              '优化了选项卡片的布局，减少垂直空间占用，显示更多内容',
            ),
            _buildFeatureItem(
              '⚡ 快速交互',
              '整个卡片区域都可点击，提升用户体验',
            ),
            _buildFeatureItem(
              '📊 智能摘要',
              '重要参数以标签形式紧凑显示，信息密度更高',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _showFullDifficultySelector,
          icon: const Icon(Icons.settings),
          label: const Text('打开完整难度选择器（支持滚动）'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _showQuickSelector,
          icon: const Icon(Icons.flash_on),
          label: const Text('快速难度选择器'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _showDifficultyComparison,
          icon: const Icon(Icons.compare_arrows),
          label: const Text('查看各难度级别对比'),
        ),
      ],
    );
  }

  Widget _buildFooterInfo() {
    final deviceType = AIDifficultyStrategy.getCurrentDeviceType();
    final recommendedDifficulties =
        AIDifficultyStrategy.getRecommendedDifficultiesForDevice(deviceType);

    return Card(
      color: Colors.grey.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设备信息',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '当前设备: ${_getDeviceTypeName(deviceType)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              '推荐难度: ${recommendedDifficulties.length} 个级别',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullDifficultySelector() {
    showDialog(
      context: context,
      builder: (context) => AIDifficultySelector(
        currentDifficulty: selectedDifficulty,
        showAdvancedOptions: true,
        onDifficultySelected: (difficulty) {
          setState(() {
            selectedDifficulty = difficulty;
          });

          // 显示选择结果
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已选择: ${difficulty.displayName}'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showQuickSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '快速选择难度',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            QuickDifficultySelector(
              currentDifficulty: selectedDifficulty,
              onDifficultyChanged: (difficulty) {
                setState(() {
                  selectedDifficulty = difficulty;
                });
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('快速选择: ${difficulty.displayName}'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyComparison() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DifficultyComparisonScreen(),
      ),
    );
  }

  Widget _buildDifficultyIcon(AIDifficultyLevel difficulty) {
    IconData icon;
    Color color;

    if (difficulty.level <= 3) {
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (difficulty.level <= 6) {
      icon = Icons.sentiment_neutral;
      color = Colors.orange;
    } else {
      icon = Icons.sentiment_very_dissatisfied;
      color = Colors.red;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildDifficultyBadge(AIDifficultyLevel difficulty) {
    Color badgeColor;
    if (difficulty.level <= 3) {
      badgeColor = Colors.green;
    } else if (difficulty.level <= 6) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        'Lv.${difficulty.level}',
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getDeviceTypeName(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.web:
        return '浏览器';
      case DeviceType.desktop:
        return '桌面设备';
      case DeviceType.mobile:
        return '移动设备';
    }
  }
}

/// 难度级别对比页面
class DifficultyComparisonScreen extends StatelessWidget {
  const DifficultyComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceType = AIDifficultyStrategy.getCurrentDeviceType();

    return Scaffold(
      appBar: AppBar(
        title: const Text('难度级别对比'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: AIDifficultyLevel.values.length,
        itemBuilder: (context, index) {
          final difficulty = AIDifficultyLevel.values[index];
          final config = AIDifficultyStrategy.getConfigForDifficulty(
              difficulty, deviceType);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildDifficultyIcon(difficulty),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          difficulty.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildDifficultyBadge(difficulty),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AIDifficultyStrategy.getDifficultyDescription(difficulty),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildInfoChip('思考时间',
                          '${(config.thinkingTimeMs / 1000).toStringAsFixed(1)}s'),
                      if (config.randomnessProbability > 0)
                        _buildInfoChip('随机性',
                            '${(config.randomnessProbability * 100).toInt()}%'),
                      _buildInfoChip(
                          '搜索深度',
                          config.searchDepth == 0
                              ? '无限制'
                              : '${config.searchDepth}层'),
                      _buildInfoChip('线程数', '${config.threads}'),
                      if (config.useOpeningBook) _buildInfoChip('开局库', '启用'),
                      if (config.useEndgameTablebase)
                        _buildInfoChip('残局库', '启用'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDifficultyIcon(AIDifficultyLevel difficulty) {
    IconData icon;
    Color color;

    if (difficulty.level <= 3) {
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (difficulty.level <= 6) {
      icon = Icons.sentiment_neutral;
      color = Colors.orange;
    } else {
      icon = Icons.sentiment_very_dissatisfied;
      color = Colors.red;
    }

    return Icon(icon, color: color, size: 24);
  }

  Widget _buildDifficultyBadge(AIDifficultyLevel difficulty) {
    Color badgeColor;
    if (difficulty.level <= 3) {
      badgeColor = Colors.green;
    } else if (difficulty.level <= 6) {
      badgeColor = Colors.orange;
    } else {
      badgeColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        'Lv.${difficulty.level}',
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
