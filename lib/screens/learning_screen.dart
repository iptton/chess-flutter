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
import '../models/chess_models.dart';
import '../services/chess_ai.dart';
import '../widgets/chess_board.dart';
import '../screens/game_screen.dart';

class LearningScreen extends StatelessWidget {
  final LearningMode? initialMode;

  const LearningScreen({
    Key? key,
    this.initialMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LearningBloc()
        ..add(const LoadAvailableLessons())
        ..add(initialMode != null
            ? StartLearningMode(initialMode!)
            : const LoadAvailableLessons()),
      child: const LearningView(),
    );
  }
}

class LearningView extends StatefulWidget {
  const LearningView({Key? key}) : super(key: key);

  @override
  State<LearningView> createState() => _LearningViewState();
}

class _LearningViewState extends State<LearningView> {
  bool _isStepDialogShowing = false;
  bool _isLessonDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LearningBloc, LearningState>(
      listenWhen: (previous, current) =>
          (current.isStepCompleted && !_isStepDialogShowing) ||
          (current.isLessonCompleted && !_isLessonDialogShowing) ||
          current.navigateToGame != null,
      listener: (context, state) {
        // 监听步骤完成状态，显示完成对话框
        if (state.isStepCompleted && !_isStepDialogShowing) {
          _showStepCompletionDialog(context, state);
        }
        // 监听课程完成状态，显示庆祝对话框
        if (state.isLessonCompleted && !_isLessonDialogShowing) {
          _showLessonCompletionDialog(context, state);
        }
        // 监听导航事件
        if (state.navigateToGame != null) {
          final navArgs = state.navigateToGame!;
          // 导航后立即清除状态，避免重复导航
          context.read<LearningBloc>().add(const ClearNavigation());
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChessBoard(
                gameMode: navArgs.gameMode,
                initialBoard: navArgs.boardState,
                aiColor: navArgs.aiColor,
                allowedPlayer: navArgs.allowedPlayer,
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return WillPopScope(
          onWillPop: () async {
            // Handle back button behavior
            if (state.currentLesson != null) {
              // If in a lesson, return to learning home instead of main home
              context.read<LearningBloc>().add(const ExitLearning());
              return false; // Prevent default back behavior
            }
            return true; // Allow normal back behavior to main home
          },
          child: Scaffold(
            appBar: ThemedAppBar(
              title: '学习模式',
              leading: state.currentLesson != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        // Return to learning home when in a lesson
                        context.read<LearningBloc>().add(const ExitLearning());
                      },
                    )
                  : null, // Use default back button when in learning home
              actions: [
                if (state.currentLesson != null)
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
                          onPressed: () => context.read<LearningBloc>().add(
                                const LoadAvailableLessons(),
                              ),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                if (state.currentLesson == null) {
                  return _buildLessonSelector(context, state);
                }

                return _buildLearningInterface(context, state);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonSelector(BuildContext context, LearningState state) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择学习内容',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '从基础规则开始，逐步掌握国际象棋的精髓',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 响应式网格配置
                    final screenWidth = constraints.maxWidth;
                    int crossAxisCount;
                    double childAspectRatio;
                    double spacing;

                    if (screenWidth < 600) {
                      // 移动端 - 增加高度以容纳内容
                      crossAxisCount = 2;
                      childAspectRatio = 0.85; // 降低比例，增加高度
                      spacing = 16;
                    } else if (screenWidth < 900) {
                      // 平板
                      crossAxisCount = 3;
                      childAspectRatio = 0.95; // 稍微降低比例
                      spacing = 20;
                    } else if (screenWidth < 1400) {
                      // 桌面
                      crossAxisCount = 4;
                      childAspectRatio = 1.0;
                      spacing = 24;
                    } else {
                      // 大桌面
                      crossAxisCount = 5;
                      childAspectRatio = 0.9;
                      spacing = 28;
                    }

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                      ),
                      itemCount: state.availableLessons.length,
                      itemBuilder: (context, index) {
                        final lesson = state.availableLessons[index];
                        return _buildLessonCard(context, lesson);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, LearningLesson lesson) {
    final iconMap = {
      LearningMode.basicRules: Icons.school,
      LearningMode.pieceMovement: Icons.directions_walk,
      LearningMode.specialMoves: Icons.star,
      LearningMode.tactics: Icons.psychology,
      LearningMode.endgame: Icons.flag,
      LearningMode.openings: Icons.play_arrow,
    };

    final colorMap = {
      LearningMode.basicRules: Colors.blue,
      LearningMode.pieceMovement: Colors.green,
      LearningMode.specialMoves: Colors.orange,
      LearningMode.tactics: Colors.purple,
      LearningMode.endgame: Colors.red,
      LearningMode.openings: Colors.teal,
    };

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.read<LearningBloc>().add(
              StartLesson(lesson.id),
            ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorMap[lesson.mode]?.withOpacity(0.1) ??
                    Colors.blue.withOpacity(0.1),
                colorMap[lesson.mode]?.withOpacity(0.05) ??
                    Colors.blue.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    iconMap[lesson.mode] ?? Icons.school,
                    color: colorMap[lesson.mode] ?? Colors.blue,
                    size: 32,
                  ),
                  const Spacer(),
                  if (lesson.isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 24,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                lesson.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              LinearProgressIndicator(
                value: lesson.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorMap[lesson.mode] ?? Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(lesson.progress * 100).toInt()}% 完成',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
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

                    // 新增：从谜题开始对战的按钮
                    if (currentStep?.boardState != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(height: 24),
                            const Text(
                              '从当前局面开始',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                context
                                    .read<LearningBloc>()
                                    .add(const StartAIGameFromPuzzle());
                              },
                              icon: const Icon(Icons.computer),
                              label: const Text('AI 对战'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                context
                                    .read<LearningBloc>()
                                    .add(const StartPVPGameFromPuzzle());
                              },
                              icon: const Icon(Icons.people),
                              label: const Text('面对面对战'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
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
              Navigator.of(context).pop();
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
              context.read<LearningBloc>().add(const ConfirmLessonCompletion());
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
}
