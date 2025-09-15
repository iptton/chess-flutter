import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/learning_bloc.dart';
import '../blocs/learning_events.dart';
import '../models/learning_models.dart';
import '../widgets/learning_board.dart';
import '../widgets/learning_instruction_panel.dart';
import '../widgets/learning_progress_bar.dart';
import '../widgets/learning_step_controls.dart';
import '../widgets/themed_background.dart';

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

class LessonDetailView extends StatefulWidget {
  const LessonDetailView({Key? key}) : super(key: key);

  @override
  State<LessonDetailView> createState() => _LessonDetailViewState();
}

class _LessonDetailViewState extends State<LessonDetailView> {
  bool _isStepDialogShowing = false;
  bool _isLessonDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LearningBloc, LearningState>(
      listener: (context, state) {
        // 监听步骤完成状态，显示完成对话框
        if (state.isStepCompleted && !_isStepDialogShowing) {
          _showStepCompletionDialog(context, state);
        }
        // 监听课程完成状态，显示庆祝对话框
        if (state.isLessonCompleted && !_isLessonDialogShowing) {
          _showLessonCompletionDialog(context, state);
        }
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            // 返回首页，并传递完成状态
            Navigator.of(context).pop(false);
            return false;
          },
          child: Scaffold(
            appBar: ThemedAppBar(
              title: state.currentLesson?.title ?? '课程学习',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _exitLesson(context, false),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  onPressed: () => _showExitDialog(context),
                  tooltip: '退出学习',
                ),
              ],
            ),
            body: BlocBuilder<LearningBloc, LearningState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('加载学习内容...'),
                      ],
                    ),
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
                          state.error!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
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

                return _buildLearningInterface(context, state);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLearningInterface(BuildContext context, LearningState state) {
    final lesson = state.currentLesson!;
    final currentStep = lesson.currentStep;

    return Column(
      children: [
        // 进度条
        LearningProgressBar(
          currentStep: lesson.currentStepIndex,
          totalSteps: lesson.steps.length,
          progress: lesson.progress,
        ),

        // 主要内容区域
        Expanded(
          child: Row(
            children: [
              // 左侧：棋盘
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: LearningBoard(
                    boardState: state.currentBoard,
                    highlightedPositions: state.highlightedPositions,
                    onMove: (from, to) => context.read<LearningBloc>().add(
                          ExecuteLearningMove(from, to),
                        ),
                    isInteractive: state.isWaitingForMove,
                    currentStep: currentStep, // 传递当前步骤
                  ),
                ),
              ),

              // 右侧：指令和控制面板
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // 指令面板
                    Expanded(
                      flex: 2,
                      child: LearningInstructionPanel(
                        step: currentStep,
                        currentInstruction: state.currentInstruction,
                        isDemonstrating: state.isDemonstrating,
                      ),
                    ),

                    // 控制按钮
                    LearningStepControls(
                      canGoBack: lesson.currentStepIndex > 0,
                      canGoForward: lesson.currentStepIndex <
                              lesson.steps.length - 1 ||
                          (lesson.currentStepIndex == lesson.steps.length - 1 &&
                              !lesson.isCompleted),
                      canSkip: currentStep?.type == StepType.practice,
                      isLastStep:
                          lesson.currentStepIndex == lesson.steps.length - 1,
                      canGoToLast:
                          lesson.currentStepIndex < lesson.steps.length - 1,
                      onPrevious: () => context.read<LearningBloc>().add(
                            const PreviousStep(),
                          ),
                      onNext: () => context.read<LearningBloc>().add(
                            const NextStep(),
                          ),
                      onSkip: () => context.read<LearningBloc>().add(
                            const SkipCurrentStep(),
                          ),
                      onRestart: () => context.read<LearningBloc>().add(
                            const RestartCurrentStep(),
                          ),
                      onHint: () => context.read<LearningBloc>().add(
                            const ShowHint(),
                          ),
                      onGoToLast: () => context.read<LearningBloc>().add(
                            GoToStep(lesson.steps.length - 1),
                          ),
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

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('退出学习'),
        content: const Text('确定要退出当前学习吗？进度将会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<LearningBloc>().add(const ExitLearning());
              Navigator.of(context).pop(false);
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }

  void _showStepCompletionDialog(BuildContext context, LearningState state) {
    final currentStep = state.currentLesson?.currentStep;
    if (currentStep == null) return;

    _isStepDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false, // 防止用户点击外部关闭
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('步骤完成！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentStep.successMessage ?? '太棒了！您已经成功完成了这个步骤！',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.green[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '继续保持这种学习状态，您正在稳步提升！',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _isStepDialogShowing = false;
              context.read<LearningBloc>().add(const ConfirmStepCompletion());
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('继续下一步'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showLessonCompletionDialog(BuildContext context, LearningState state) {
    final currentLesson = state.currentLesson;
    if (currentLesson == null) return;

    _isLessonDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false, // 防止用户点击外部关闭
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.celebration,
              color: Colors.amber,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '🎉 课程完成！',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '恭喜您成功完成了《${currentLesson.title}》课程！',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.1),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: Colors.amber[700],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '您已经掌握了这个主题的核心知识！',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '继续学习其他课程，提升您的国际象棋技能！',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (currentLesson.timeSpent != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '学习时长：${_formatDuration(currentLesson.timeSpent!)}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _isLessonDialogShowing = false;
              _exitLesson(context, true);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回学习首页'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}分${seconds}秒';
    } else {
      return '${seconds}秒';
    }
  }

  void _exitLesson(BuildContext context, bool completed) {
    // 返回首页，并传递完成状态
    Navigator.of(context).pop(completed);
  }
}
