import 'package:flutter/material.dart';

class LearningStepControls extends StatelessWidget {
  final bool canGoBack;
  final bool canGoForward;
  final bool canSkip;
  final bool isLastStep;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onRestart;
  final VoidCallback? onHint;

  const LearningStepControls({
    Key? key,
    this.canGoBack = false,
    this.canGoForward = false,
    this.canSkip = false,
    this.isLastStep = false,
    this.onPrevious,
    this.onNext,
    this.onSkip,
    this.onRestart,
    this.onHint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主要控制按钮
          Row(
            children: [
              // 上一步按钮
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canGoBack ? onPrevious : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('上一步'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 下一步/完成按钮
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: canGoForward ? onNext : null,
                  icon: Icon(isLastStep ? Icons.check : Icons.arrow_forward),
                  label: Text(isLastStep ? '完成' : '下一步'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 辅助控制按钮
          Row(
            children: [
              // 重新开始按钮
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新开始'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 提示按钮
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('提示'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 跳过按钮
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canSkip ? onSkip : null,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('跳过'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: canSkip ? Colors.purple : Colors.grey,
                    side: BorderSide(color: canSkip ? Colors.purple : Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
