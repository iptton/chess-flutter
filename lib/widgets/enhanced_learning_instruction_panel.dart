import 'package:flutter/material.dart';
import '../models/learning_models.dart';

class EnhancedLearningInstructionPanel extends StatelessWidget {
  final LearningStep? step;
  final int currentInstructionIndex;
  final int totalInstructions;
  final VoidCallback? onNextInstruction;
  final VoidCallback? onPreviousInstruction;
  final bool showProgress;
  final String? currentInstruction;

  const EnhancedLearningInstructionPanel({
    Key? key,
    this.step,
    required this.currentInstructionIndex,
    required this.totalInstructions,
    this.onNextInstruction,
    this.onPreviousInstruction,
    this.showProgress = true,
    this.currentInstruction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        
        if (isWideScreen) {
          return _buildExpandedLayout(context);
        } else {
          return _buildCompactLayout(context);
        }
      },
    );
  }

  Widget _buildExpandedLayout(BuildContext context) {
    return Container(
      key: const Key('expanded_instruction_layout'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildProgressIndicator(),
          const SizedBox(height: 20),
          Expanded(
            child: _buildInstructionContent(context),
          ),
          const SizedBox(height: 16),
          _buildNavigationControls(context),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Container(
      key: const Key('compact_instruction_layout'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactHeader(context),
          const SizedBox(height: 12),
          if (showProgress) _buildCompactProgressIndicator(),
          if (showProgress) const SizedBox(height: 12),
          Expanded(
            child: _buildInstructionContent(context),
          ),
          const SizedBox(height: 12),
          _buildCompactNavigationControls(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (step == null) return const SizedBox.shrink();

    return Row(
      children: [
        _buildStepTypeIcon(step!.type),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step!.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step!.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader(BuildContext context) {
    if (step == null) return const SizedBox.shrink();

    return Row(
      children: [
        _buildStepTypeIcon(step!.type, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            step!.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    if (!showProgress || totalInstructions <= 1) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '指令进度',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${currentInstructionIndex + 1} / $totalInstructions',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (currentInstructionIndex + 1) / totalInstructions,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildCompactProgressIndicator() {
    if (!showProgress || totalInstructions <= 1) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: (currentInstructionIndex + 1) / totalInstructions,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 4,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${currentInstructionIndex + 1} / $totalInstructions',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionContent(BuildContext context) {
    final instruction = currentInstruction ?? 
        (step?.instructions.isNotEmpty == true 
            ? step!.instructions[currentInstructionIndex.clamp(0, step!.instructions.length - 1)]
            : step?.description ?? '暂无指令');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getInstructionBackgroundColor(step?.type ?? StepType.explanation),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getInstructionBorderColor(step?.type ?? StepType.explanation),
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getInstructionIcon(step?.type ?? StepType.explanation),
                  color: _getInstructionIconColor(step?.type ?? StepType.explanation),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    instruction,
                    style: TextStyle(
                      fontSize: 16,
                      color: _getInstructionTextColor(step?.type ?? StepType.explanation),
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls(BuildContext context) {
    if (totalInstructions <= 1) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: currentInstructionIndex > 0 ? onPreviousInstruction : null,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('上一条'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: currentInstructionIndex < totalInstructions - 1 ? onNextInstruction : null,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('下一条'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactNavigationControls(BuildContext context) {
    if (totalInstructions <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: currentInstructionIndex > 0 ? onPreviousInstruction : null,
          icon: const Icon(Icons.arrow_back),
          style: IconButton.styleFrom(
            backgroundColor: currentInstructionIndex > 0 ? Colors.grey[200] : Colors.grey[100],
            foregroundColor: currentInstructionIndex > 0 ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
        IconButton(
          onPressed: currentInstructionIndex < totalInstructions - 1 ? onNextInstruction : null,
          icon: const Icon(Icons.arrow_forward),
          style: IconButton.styleFrom(
            backgroundColor: currentInstructionIndex < totalInstructions - 1 ? Colors.blue[100] : Colors.grey[100],
            foregroundColor: currentInstructionIndex < totalInstructions - 1 ? Colors.blue[700] : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildStepTypeIcon(StepType type, {double size = 24}) {
    final iconMap = {
      StepType.explanation: Icons.info_outline,
      StepType.demonstration: Icons.play_circle_outline,
      StepType.practice: Icons.edit_outlined,
      StepType.quiz: Icons.quiz_outlined,
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
        color: colorMap[type]!.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconMap[type],
        color: colorMap[type],
        size: size,
      ),
    );
  }

  // Helper methods for styling based on step type
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

  Color _getInstructionIconColor(StepType type) {
    switch (type) {
      case StepType.explanation:
        return Colors.blue[600]!;
      case StepType.demonstration:
        return Colors.green[600]!;
      case StepType.practice:
        return Colors.orange[600]!;
      case StepType.quiz:
        return Colors.purple[600]!;
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
}
