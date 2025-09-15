import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/learning_bloc.dart';
import '../blocs/learning_events.dart';
import '../models/learning_models.dart';
import '../widgets/themed_background.dart';
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
      appBar: ThemedAppBar(
        title: '学习模式',
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

          return _buildLessonSelector(context, state);
        },
      ),
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
                child: _buildLessonsGrid(context, state.availableLessons),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonsGrid(BuildContext context, List<LearningLesson> lessons) {
    if (lessons.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.white70,
            ),
            SizedBox(height: 16),
            Text(
              '暂无可用课程',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
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
          itemCount: lessons.length,
          itemBuilder: (context, index) {
            final lesson = lessons[index];
            return _buildLessonCard(context, lesson);
          },
        );
      },
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
        onTap: () => _navigateToLesson(context, lesson),
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
