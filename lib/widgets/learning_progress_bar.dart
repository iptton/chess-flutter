import 'package:flutter/material.dart';

class LearningProgressBar extends StatelessWidget {
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
                '步骤 ${currentStep + 1} / $totalSteps',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}% 完成',
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
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 6,
          ),
          
          const SizedBox(height: 12),
          
          // 步骤点指示器
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildStepDot(index),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int index) {
    final isCompleted = index < currentStep;
    final isCurrent = index == currentStep;
    
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
                  color: isCompleted || isCurrent ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
    );
  }
}
