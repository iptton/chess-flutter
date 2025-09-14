import 'package:flutter/material.dart';
import '../models/learning_models.dart';

class LearningStatsPanel extends StatelessWidget {
  final LearningLesson lesson;
  final int moveCount;
  final int correctMoves;
  final int incorrectMoves;
  final Duration elapsedTime;
  final bool isCompleted;

  const LearningStatsPanel({
    Key? key,
    required this.lesson,
    required this.moveCount,
    required this.correctMoves,
    required this.incorrectMoves,
    required this.elapsedTime,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          _buildHeader(),
          const SizedBox(height: 16),
          _buildProgressSection(),
          const SizedBox(height: 16),
          _buildStatsSection(),
          const SizedBox(height: 16),
          _buildTimeSection(),
          if (isCompleted) ...[
            const SizedBox(height: 16),
            _buildCompletionCelebration(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.analytics_outlined,
          color: Colors.blue[600],
          size: 24,
        ),
        const SizedBox(width: 8),
        const Text(
          '学习统计',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    final currentStep = lesson.currentStepIndex + 1;
    final totalSteps = lesson.steps.length;
    final progressPercentage = ((currentStep / totalSteps) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '步骤 $currentStep / $totalSteps',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '${isCompleted ? 100 : progressPercentage}% 完成',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: isCompleted ? 1.0 : (currentStep / totalSteps),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            isCompleted ? Colors.green : Colors.blue,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        _buildStepIndicators(),
      ],
    );
  }

  Widget _buildStepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(lesson.steps.length, (index) {
        final step = lesson.steps[index];
        final isCurrent = index == lesson.currentStepIndex;
        final isCompleted = step.status == StepStatus.completed;
        final isPast = index < lesson.currentStepIndex;

        Color color;
        IconData icon;

        if (isCompleted ||
            (this.isCompleted && index <= lesson.currentStepIndex)) {
          color = Colors.green;
          icon = Icons.check_circle;
        } else if (isCurrent && !this.isCompleted) {
          color = Colors.blue;
          icon = Icons.radio_button_checked;
        } else if (isPast) {
          color = Colors.orange;
          icon = Icons.circle;
        } else {
          color = Colors.grey;
          icon = Icons.circle_outlined;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        );
      }),
    );
  }

  Widget _buildStatsSection() {
    final accuracy =
        moveCount > 0 ? ((correctMoves / moveCount) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '移动统计',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '移动次数',
                moveCount.toString(),
                Icons.touch_app,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                '正确',
                correctMoves.toString(),
                Icons.check,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                '错误',
                incorrectMoves.toString(),
                Icons.close,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.track_changes,
                color: Colors.purple[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '准确率: $accuracy%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection() {
    final minutes = elapsedTime.inMinutes;
    final seconds = elapsedTime.inSeconds % 60;
    final timeString = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '用时: $timeString',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCelebration() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[100]!, Colors.green[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '🎉 恭喜完成！',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '你已经成功完成了这个学习模块！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.green[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
