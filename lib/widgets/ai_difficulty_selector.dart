import 'package:flutter/material.dart';
import '../utils/ai_difficulty_strategy.dart';
import '../models/chess_models.dart';
import '../widgets/themed_background.dart';

/// AI难度选择对话框
class AIDifficultySelector extends StatefulWidget {
  final AIDifficultyLevel? currentDifficulty;
  final Function(AIDifficultyLevel)? onDifficultySelected;
  final Function(AIDifficultyLevel, PieceColor)? onGameStart;
  final bool showAdvancedOptions;
  final bool showColorSelection;
  final PieceColor? initialPlayerColor;

  const AIDifficultySelector({
    super.key,
    this.currentDifficulty,
    this.onDifficultySelected,
    this.onGameStart,
    this.showAdvancedOptions = false,
    this.showColorSelection = false,
    this.initialPlayerColor,
  });

  @override
  State<AIDifficultySelector> createState() => _AIDifficultySelectorState();
}

class _AIDifficultySelectorState extends State<AIDifficultySelector> {
  late AIDifficultyLevel selectedDifficulty;
  late PieceColor selectedPlayerColor;
  late DeviceType deviceType;
  late List<AIDifficultyLevel> availableDifficulties;

  @override
  void initState() {
    super.initState();
    deviceType = AIDifficultyStrategy.getCurrentDeviceType();
    availableDifficulties = widget.showAdvancedOptions
        ? AIDifficultyLevel.values
        : AIDifficultyStrategy.getRecommendedDifficultiesForDevice(deviceType);

    selectedDifficulty = widget.currentDifficulty ??
        (availableDifficulties.contains(AIDifficultyLevel.intermediate)
            ? AIDifficultyLevel.intermediate
            : availableDifficulties.first);

    selectedPlayerColor = widget.initialPlayerColor ?? PieceColor.white;
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕高度，计算对话框最大高度
    final screenHeight = MediaQuery.of(context).size.height;
    final maxDialogHeight = screenHeight * 0.8; // 对话框最大高度为屏幕的80%

    return AlertDialog(
      title: Text(widget.showColorSelection ? '单机对战设置' : '选择AI难度'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: double.maxFinite,
          maxHeight: maxDialogHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 设备信息
              _buildDeviceInfo(),
              const SizedBox(height: 16),

              // 难度选择器
              _buildDifficultySelector(),

              // 颜色选择器（可选）
              if (widget.showColorSelection) ...[
                const SizedBox(height: 16),
                _buildColorSelector(),
              ],

              const SizedBox(height: 16),

              // 当前选择的详细信息
              _buildSelectedDifficultyInfo(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
          ),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.showColorSelection && widget.onGameStart != null) {
              widget.onGameStart!(selectedDifficulty, selectedPlayerColor);
            } else if (widget.onDifficultySelected != null) {
              widget.onDifficultySelected!(selectedDifficulty);
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(widget.showColorSelection ? '开始游戏' : '确定'),
        ),
      ],
    );
  }

  Widget _buildDeviceInfo() {
    String deviceInfo;
    IconData deviceIcon;
    Color deviceColor;

    switch (deviceType) {
      case DeviceType.web:
        deviceInfo = '浏览器 - 高性能模式';
        deviceIcon = Icons.web;
        deviceColor = Colors.blue;
        break;
      case DeviceType.desktop:
        deviceInfo = '桌面设备 - 最高性能';
        deviceIcon = Icons.computer;
        deviceColor = Colors.green;
        break;
      case DeviceType.mobile:
        deviceInfo = '移动设备 - 节能模式';
        deviceIcon = Icons.phone_android;
        deviceColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: deviceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: deviceColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(deviceIcon, color: deviceColor, size: 20),
          const SizedBox(width: 8),
          Text(
            deviceInfo,
            style: TextStyle(
              color: deviceColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '难度等级',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // 将难度选项列表用Column包装，避免嵌套滚动问题
        Column(
          mainAxisSize: MainAxisSize.min,
          children: availableDifficulties
              .map((difficulty) => _buildDifficultyOption(difficulty))
              .toList(),
        ),

        if (!widget.showAdvancedOptions &&
            availableDifficulties.length < AIDifficultyLevel.values.length)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    availableDifficulties = AIDifficultyLevel.values;
                  });
                },
                icon: const Icon(Icons.expand_more),
                label: const Text('显示所有难度'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDifficultyOption(AIDifficultyLevel difficulty) {
    final config =
        AIDifficultyStrategy.getConfigForDifficulty(difficulty, deviceType);
    final isSelected = selectedDifficulty == difficulty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedDifficulty = difficulty;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // 单选按钮
              Radio<AIDifficultyLevel>(
                value: difficulty,
                groupValue: selectedDifficulty,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDifficulty = value;
                    });
                  }
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),

              // 难度图标
              _buildDifficultyIcon(difficulty),
              const SizedBox(width: 8),

              // 内容区域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            difficulty.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        _buildDifficultyBadge(difficulty),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // 描述
                    Text(
                      AIDifficultyStrategy.getDifficultyDescription(difficulty),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // 配置摘要
                    _buildConfigSummary(config),
                  ],
                ),
              ),
            ],
          ),
        ),
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

    return Icon(icon, color: color, size: 20);
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        'Lv.${difficulty.level}',
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildConfigSummary(AIDifficultyConfig config) {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: [
        _buildConfigChip(
            '${(config.thinkingTimeMs / 1000).toStringAsFixed(1)}s',
            Icons.timer),
        if (config.randomnessProbability > 0)
          _buildConfigChip('${(config.randomnessProbability * 100).toInt()}%随机',
              Icons.shuffle),
        if (config.searchDepth > 0)
          _buildConfigChip('深度${config.searchDepth}', Icons.layers),
        if (config.threads > 1)
          _buildConfigChip('${config.threads}线程', Icons.memory),
      ],
    );
  }

  Widget _buildConfigChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey[600]),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '选择你的颜色',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(right: 4),
                color: selectedPlayerColor == PieceColor.white
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedPlayerColor = PieceColor.white;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Radio<PieceColor>(
                          value: PieceColor.white,
                          groupValue: selectedPlayerColor,
                          onChanged: (value) {
                            setState(() {
                              selectedPlayerColor = value!;
                            });
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.circle_outlined,
                            color: Colors.grey, size: 24),
                        const SizedBox(height: 4),
                        const Text('白方',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const Text('先手',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(left: 4),
                color: selectedPlayerColor == PieceColor.black
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedPlayerColor = PieceColor.black;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Radio<PieceColor>(
                          value: PieceColor.black,
                          groupValue: selectedPlayerColor,
                          onChanged: (value) {
                            setState(() {
                              selectedPlayerColor = value!;
                            });
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.circle,
                            color: Colors.black87, size: 24),
                        const SizedBox(height: 4),
                        const Text('黑方',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        const Text('后手',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedDifficultyInfo() {
    final config = AIDifficultyStrategy.getConfigForDifficulty(
        selectedDifficulty, deviceType);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '选中: ${selectedDifficulty.displayName}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),

          // 使用网格布局显示参数，更紧凑
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildCompactInfoItem(
                  '时间',
                  '${(config.thinkingTimeMs / 1000).toStringAsFixed(1)}s',
                  Icons.timer),
              if (config.randomnessProbability > 0)
                _buildCompactInfoItem(
                    '随机',
                    '${(config.randomnessProbability * 100).toStringAsFixed(1)}%',
                    Icons.shuffle),
              _buildCompactInfoItem(
                  '深度',
                  config.searchDepth == 0 ? '无限' : '${config.searchDepth}',
                  Icons.layers),
              _buildCompactInfoItem('线程', '${config.threads}', Icons.memory),
              if (config.useOpeningBook)
                _buildCompactInfoItem('开局库', '启用', Icons.book),
              if (config.useEndgameTablebase)
                _buildCompactInfoItem('残局库', '启用', Icons.analytics),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// 简化的难度选择器（用于快速选择）
class QuickDifficultySelector extends StatelessWidget {
  final AIDifficultyLevel currentDifficulty;
  final Function(AIDifficultyLevel) onDifficultyChanged;

  const QuickDifficultySelector({
    super.key,
    required this.currentDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = AIDifficultyStrategy.getCurrentDeviceType();
    final recommendedDifficulties =
        AIDifficultyStrategy.getRecommendedDifficultiesForDevice(deviceType);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: recommendedDifficulties.take(3).map((difficulty) {
        final isSelected = difficulty == currentDifficulty;
        return _buildQuickOption(context, difficulty, isSelected);
      }).toList(),
    );
  }

  Widget _buildQuickOption(
      BuildContext context, AIDifficultyLevel difficulty, bool isSelected) {
    Color color;
    if (difficulty.level <= 3) {
      color = Colors.green;
    } else if (difficulty.level <= 6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return GestureDetector(
      onTap: () => onDifficultyChanged(difficulty),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          difficulty.displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
