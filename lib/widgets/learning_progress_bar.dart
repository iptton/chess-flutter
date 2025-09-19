import 'package:flutter/material.dart';

class LearningProgressBar extends StatefulWidget {
  final int currentStep;
  final int totalSteps;
  final double progress;

  const LearningProgressBar({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    required this.progress,
  }) : super(key: key);

  @override
  State<LearningProgressBar> createState() => _LearningProgressBarState();
}

class _LearningProgressBarState extends State<LearningProgressBar> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 初始化后滚动到当前步骤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentStep();
    });
  }

  @override
  void didUpdateWidget(LearningProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当步骤改变时，滚动到新的当前步骤
    if (oldWidget.currentStep != widget.currentStep) {
      _scrollToCurrentStep();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentStep() {
    if (!_scrollController.hasClients || !mounted) return;

    // 延迟执行以确保布局完成
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients || !mounted) return;

      // 计算当前步骤的位置
      const double stepWidth = 28.0; // 24px 宽度 + 4px margin
      final double screenWidth = MediaQuery.of(context).size.width;
      final double targetOffset = (widget.currentStep * stepWidth) -
          (screenWidth / 2) +
          (stepWidth / 2);

      // 确保偏移量在有效范围内
      final double maxOffset = _scrollController.position.maxScrollExtent;
      final double minOffset = _scrollController.position.minScrollExtent;
      final double clampedOffset = targetOffset.clamp(minOffset, maxOffset);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 步骤指示器
          Row(
            children: [
              Text(
                '步骤 ${widget.currentStep + 1} / ${widget.totalSteps}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(widget.progress * 100).toInt()}% 完成',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 进度条
          LinearProgressIndicator(
            value: widget.progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
          ),

          const SizedBox(height: 12),

          // 步骤点指示器 - 支持水平滑动
          Stack(
            children: [
              SizedBox(
                height: 32, // 固定高度以容纳指示器
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: widget.totalSteps > 10, // 只在步骤较多时显示滚动条
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16), // 添加左右边距
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.totalSteps, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildStepDot(index),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
              // 左侧渐变指示器
              if (widget.totalSteps > 10)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              // 右侧渐变指示器
              if (widget.totalSteps > 10)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int index) {
    final isCompleted = index < widget.currentStep;
    final isCurrent = index == widget.currentStep;

    Color color;
    IconData? icon;

    if (isCompleted) {
      color = Colors.green;
      icon = Icons.check;
    } else if (isCurrent) {
      color = Colors.blue;
    } else {
      color = Colors.grey[300]!;
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isCurrent ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: icon != null
          ? Icon(
              icon,
              size: 16,
              color: Colors.white,
            )
          : Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted || isCurrent
                      ? Colors.white
                      : Colors.grey[600],
                ),
              ),
            ),
    );
  }
}
