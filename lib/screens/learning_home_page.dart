import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/learning_bloc.dart';
import '../blocs/learning_events.dart';
import '../models/learning_models.dart';
import 'lesson_detail_page.dart';

/// 学习模式首页 - 显示可用课程列表
class LearningHomePage extends StatelessWidget {
  const LearningHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // 为首页创建独立的BlocProvider
      create: (context) => LearningBloc()..add(const LoadAvailableLessons()),
      child: const LearningHomeView(),
    );
  }
}

class LearningHomeView extends StatelessWidget {
  const LearningHomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('国际象棋学习'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
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
                    onPressed: () {
                      context
                          .read<LearningBloc>()
                          .add(const LoadAvailableLessons());
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<LearningBloc>().add(const LoadAvailableLessons());
            },
            child: _buildLessonsList(context, state.availableLessons),
          );
        },
      ),
    );
  }

  Widget _buildLessonsList(BuildContext context, List<LearningLesson> lessons) {
    if (lessons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无可用课程',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return _buildLessonCard(context, lesson);
      },
    );
  }

  Widget _buildLessonCard(BuildContext context, LearningLesson lesson) {
    final completedSteps = lesson.steps
        .where((step) => step.status == StepStatus.completed)
        .length;
    final totalSteps = lesson.steps.length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;
    final isCompleted = progress >= 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToLesson(context, lesson),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '已完成',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lesson.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCompleted ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completedSteps/$totalSteps',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _getModeIcon(lesson.mode),
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getModeDisplayName(lesson.mode),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getModeIcon(LearningMode mode) {
    switch (mode) {
      case LearningMode.basicRules:
        return Icons.school;
      case LearningMode.pieceMovement:
        return Icons.directions_walk;
      case LearningMode.specialMoves:
        return Icons.star;
      case LearningMode.tactics:
        return Icons.psychology;
      case LearningMode.endgame:
        return Icons.flag;
      case LearningMode.openings:
        return Icons.play_arrow;
    }
  }

  String _getModeDisplayName(LearningMode mode) {
    switch (mode) {
      case LearningMode.basicRules:
        return '基础规则';
      case LearningMode.pieceMovement:
        return '棋子移动';
      case LearningMode.specialMoves:
        return '特殊移动';
      case LearningMode.tactics:
        return '战术训练';
      case LearningMode.endgame:
        return '残局练习';
      case LearningMode.openings:
        return '开局学习';
    }
  }

  void _navigateToLesson(BuildContext context, LearningLesson lesson) async {
    // 使用路由导航到课程详情页
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LessonDetailPage(lessonId: lesson.id),
      ),
    );

    // 如果课程完成了，刷新课程列表
    if (result == true) {
      if (context.mounted) {
        context.read<LearningBloc>().add(const LoadAvailableLessons());
      }
    }
  }
}
