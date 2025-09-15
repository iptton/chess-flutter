import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/learning_bloc.dart';
import '../blocs/learning_events.dart';
import '../models/learning_models.dart';
import '../widgets/chess_board.dart';

/// 课程详情页 - 处理具体课程的学习逻辑
class LessonDetailPage extends StatelessWidget {
  final String lessonId;

  const LessonDetailPage({
    Key? key,
    required this.lessonId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // 为课程详情页创建独立的BlocProvider
      create: (context) => LearningBloc()..add(StartLesson(lessonId)),
      child: const LessonDetailView(),
    );
  }
}

class LessonDetailView extends StatelessWidget {
  const LessonDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<LearningBloc, LearningState>(
      listener: (context, state) {
        // 监听课程完成状态
        if (state.isLessonCompleted) {
          _showLessonCompletionDialog(context);
        }

        // 监听步骤完成状态
        if (state.isStepCompleted) {
          _showStepCompletionDialog(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<LearningBloc, LearningState>(
            builder: (context, state) {
              return Text(state.currentLesson?.title ?? '课程学习');
            },
          ),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => _exitLesson(context, false),
              tooltip: '返回首页',
            ),
          ],
        ),
        body: BlocBuilder<LearningBloc, LearningState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '加载失败: ${state.error}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('返回'),
                    ),
                  ],
                ),
              );
            }

            if (state.currentLesson == null) {
              return const Center(
                child: Text('课程不存在'),
              );
            }

            return _buildLessonContent(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context, LearningState state) {
    final lesson = state.currentLesson!;
    final currentStep = lesson.currentStepIndex < lesson.steps.length
        ? lesson.steps[lesson.currentStepIndex]
        : null;

    if (currentStep == null) {
      return const Center(
        child: Text('课程已完成'),
      );
    }

    return Column(
      children: [
        // 进度指示器
        _buildProgressIndicator(lesson),

        // 课程内容
        Expanded(
          child: _buildStepContent(context, state, currentStep),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(LearningLesson lesson) {
    final progress = (lesson.currentStepIndex + 1) / lesson.steps.length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '步骤 ${lesson.currentStepIndex + 1} / ${lesson.steps.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
      BuildContext context, LearningState state, LearningStep step) {
    switch (step.type) {
      case StepType.explanation:
        return _buildExplanationStep(context, step);
      case StepType.demonstration:
        return _buildDemonstrationStep(context, state, step);
      case StepType.practice:
        return _buildPracticeStep(context, state, step);
      case StepType.quiz:
        return _buildQuizStep(context, step);
    }
  }

  Widget _buildExplanationStep(BuildContext context, LearningStep step) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                step.description,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<LearningBloc>().add(const NextStep());
              },
              child: const Text('继续'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemonstrationStep(
      BuildContext context, LearningState state, LearningStep step) {
    return Column(
      children: [
        // 说明文字
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step.description,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),

        // 棋盘
        Expanded(
          child: ChessBoardLayout(
            topContent: [
              if (state.currentInstruction != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.currentInstruction!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // 演示控制按钮
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: state.isDemonstrating
                          ? null
                          : () {
                              context
                                  .read<LearningBloc>()
                                  .add(const StartDemonstration());
                            },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('开始演示'),
                    ),
                    ElevatedButton.icon(
                      onPressed: state.isDemonstrating
                          ? () {
                              context
                                  .read<LearningBloc>()
                                  .add(const StopDemonstration());
                            }
                          : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('停止演示'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<LearningBloc>().add(const NextStep());
                      },
                      child: const Text('继续'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeStep(
      BuildContext context, LearningState state, LearningStep step) {
    return Column(
      children: [
        // 说明文字
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Text(
            step.description,
            style: const TextStyle(fontSize: 16),
          ),
        ),

        // 棋盘
        Expanded(
          child: ChessBoardLayout(
            topContent: [
              if (state.currentInstruction != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    border: Border.all(color: Colors.amber[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.currentInstruction!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizStep(BuildContext context, LearningStep step) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                step.description,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<LearningBloc>().add(const NextStep());
              },
              child: const Text('完成'),
            ),
          ),
        ],
      ),
    );
  }

  void _showStepCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('步骤完成'),
        content: const Text('恭喜！您已完成当前步骤。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<LearningBloc>().add(const ConfirmStepCompletion());
            },
            child: const Text('继续下一步'),
          ),
        ],
      ),
    );
  }

  void _showLessonCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('课程完成'),
        content: const Text('恭喜！您已完成整个课程。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _exitLesson(context, true);
            },
            child: const Text('返回学习首页'),
          ),
        ],
      ),
    );
  }

  void _exitLesson(BuildContext context, bool completed) {
    // 返回首页，并传递完成状态
    Navigator.of(context).pop(completed);
  }
}
