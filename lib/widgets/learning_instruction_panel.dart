import 'package:flutter/material.dart';
import '../models/learning_models.dart';

class LearningInstructionPanel extends StatelessWidget {
  final LearningStep? step;
  final String? currentInstruction;
  final bool isDemonstrating;

  const LearningInstructionPanel({
    Key? key,
    this.step,
    this.currentInstruction,
    this.isDemonstrating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (step == null) {
      return const Center(
        child: Text('没有可用的学习内容'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 步骤标题和类型
          Row(
            children: [
              _buildStepTypeIcon(step!.type),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step!.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 步骤描述
          Text(
            step!.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          
          const Divider(height: 24),
          
          // 当前指令或说明
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentInstruction != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getInstructionBackgroundColor(step!.type),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getInstructionBorderColor(step!.type),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getInstructionIcon(step!.type),
                            color: _getInstructionIconColor(step!.type),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentInstruction!,
                              style: TextStyle(
                                fontSize: 14,
                                color: _getInstructionTextColor(step!.type),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // 详细说明
                  if (step!.instructions.isNotEmpty) ...[
                    const Text(
                      '详细说明：',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...step!.instructions.map((instruction) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Text(
                              instruction,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                  
                  // 演示状态指示
                  if (isDemonstrating) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '正在演示中...',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTypeIcon(StepType type) {
    final iconMap = {
      StepType.explanation: Icons.info_outline,
      StepType.demonstration: Icons.play_circle_outline,
      StepType.practice: Icons.sports_esports,
      StepType.quiz: Icons.quiz,
    };

    final colorMap = {
      StepType.explanation: Colors.blue,
      StepType.demonstration: Colors.green,
      StepType.practice: Colors.orange,
      StepType.quiz: Colors.purple,
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorMap[type]?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconMap[type],
        color: colorMap[type],
        size: 20,
      ),
    );
  }

  Color _getInstructionBackgroundColor(StepType type) {
    switch (type) {
      case StepType.explanation:
        return Colors.blue[50]!;
      case StepType.demonstration:
        return Colors.green[50]!;
      case StepType.practice:
        return Colors.orange[50]!;
      case StepType.quiz:
        return Colors.purple[50]!;
    }
  }

  Color _getInstructionBorderColor(StepType type) {
    switch (type) {
      case StepType.explanation:
        return Colors.blue[200]!;
      case StepType.demonstration:
        return Colors.green[200]!;
      case StepType.practice:
        return Colors.orange[200]!;
      case StepType.quiz:
        return Colors.purple[200]!;
    }
  }

  Color _getInstructionTextColor(StepType type) {
    switch (type) {
      case StepType.explanation:
        return Colors.blue[800]!;
      case StepType.demonstration:
        return Colors.green[800]!;
      case StepType.practice:
        return Colors.orange[800]!;
      case StepType.quiz:
        return Colors.purple[800]!;
    }
  }

  Color _getInstructionIconColor(StepType type) {
    switch (type) {
      case StepType.explanation:
        return Colors.blue;
      case StepType.demonstration:
        return Colors.green;
      case StepType.practice:
        return Colors.orange;
      case StepType.quiz:
        return Colors.purple;
    }
  }

  IconData _getInstructionIcon(StepType type) {
    switch (type) {
      case StepType.explanation:
        return Icons.lightbulb_outline;
      case StepType.demonstration:
        return Icons.visibility;
      case StepType.practice:
        return Icons.touch_app;
      case StepType.quiz:
        return Icons.help_outline;
    }
  }
}
