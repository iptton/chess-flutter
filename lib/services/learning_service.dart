import '../models/learning_models.dart';
import '../models/chess_models.dart';
import '../data/learning_lessons.dart';

class LearningService {
  static final LearningService _instance = LearningService._internal();
  factory LearningService() => _instance;
  LearningService._internal();

  final LearningLessons _lessonsData = LearningLessons();

  /// 获取所有可用课程
  Future<List<LearningLesson>> getAvailableLessons() async {
    // 减少不必要的延迟，提升用户体验
    await Future.delayed(const Duration(milliseconds: 100));

    return [
      _lessonsData.basicRulesLesson,
      _lessonsData.pieceMovementLesson,
      _lessonsData.specialMovesLesson,
      _lessonsData.tacticsLesson,
      _lessonsData.endgameLesson,
      _lessonsData.openingsLesson,
    ];
  }

  /// 根据ID获取课程
  Future<LearningLesson?> getLessonById(String lessonId) async {
    final lessons = await getAvailableLessons();
    try {
      return lessons.firstWhere((lesson) => lesson.id == lessonId);
    } catch (e) {
      return null;
    }
  }

  /// 根据学习模式获取课程
  Future<LearningLesson?> getLessonByMode(LearningMode mode) async {
    final lessons = await getAvailableLessons();
    try {
      return lessons.firstWhere((lesson) => lesson.mode == mode);
    } catch (e) {
      return null;
    }
  }

  /// 保存学习进度
  Future<void> saveProgress(LearningLesson lesson) async {
    // TODO: 实现本地存储或云端同步
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// 加载学习进度
  Future<LearningLesson?> loadProgress(String lessonId) async {
    // TODO: 从本地存储或云端加载进度
    await Future.delayed(const Duration(milliseconds: 50));
    return null;
  }

  /// 获取用户学习统计
  Future<Map<String, dynamic>> getLearningStats() async {
    // TODO: 实现学习统计功能
    await Future.delayed(const Duration(milliseconds: 100));

    return {
      'totalLessonsCompleted': 0,
      'totalTimeSpent': const Duration(),
      'averageScore': 0.0,
      'completionRate': 0.0,
    };
  }

  /// 重置课程进度
  Future<void> resetLessonProgress(String lessonId) async {
    // TODO: 实现重置进度功能
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// 获取推荐的下一个课程
  Future<LearningLesson?> getRecommendedNextLesson(
      List<LearningLesson> completedLessons) async {
    final allLessons = await getAvailableLessons();

    // 简单的推荐逻辑：返回第一个未完成的课程
    for (final lesson in allLessons) {
      if (!completedLessons.any((completed) => completed.id == lesson.id)) {
        return lesson;
      }
    }

    return null;
  }

  /// 验证移动是否正确
  bool validateMove(ChessMove move, LearningStep step) {
    if (step.requiredMoves == null || step.requiredMoves!.isEmpty) {
      return true;
    }

    return step.requiredMoves!.any((requiredMove) =>
        requiredMove.from.row == move.from.row &&
        requiredMove.from.col == move.from.col &&
        requiredMove.to.row == move.to.row &&
        requiredMove.to.col == move.to.col);
  }

  /// 获取步骤提示
  String? getStepHint(LearningStep step) {
    if (step.metadata != null && step.metadata!.containsKey('hint')) {
      return step.metadata!['hint'] as String?;
    }

    // 根据步骤类型生成默认提示
    switch (step.type) {
      case StepType.practice:
        if (step.requiredMoves != null && step.requiredMoves!.isNotEmpty) {
          final firstMove = step.requiredMoves!.first;
          return '尝试将棋子从 ${_positionToString(firstMove.from)} 移动到 ${_positionToString(firstMove.to)}';
        }
        break;
      case StepType.demonstration:
        return '观看演示，学习正确的移动方式';
      case StepType.explanation:
        return '仔细阅读说明，理解规则要点';
      case StepType.quiz:
        return '根据所学知识选择正确答案';
    }

    return null;
  }

  /// 将位置转换为字符串表示
  String _positionToString(Position position) {
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    if (position.col >= 0 &&
        position.col < 8 &&
        position.row >= 0 &&
        position.row < 8) {
      return '${files[position.col]}${ranks[position.row]}';
    }

    return '${position.col},${position.row}';
  }

  /// 创建自定义课程
  LearningLesson createCustomLesson({
    required String title,
    required String description,
    required LearningMode mode,
    required List<LearningStep> steps,
  }) {
    return LearningLesson(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      mode: mode,
      steps: steps,
    );
  }

  /// 创建自定义步骤
  LearningStep createCustomStep({
    required String title,
    required String description,
    required StepType type,
    List<String>? instructions,
    List<List<ChessPiece?>>? boardState,
    List<Position>? highlightPositions,
    List<ChessMove>? requiredMoves,
    List<ChessMove>? demonstrationMoves,
    String? successMessage,
    String? failureMessage,
    Map<String, dynamic>? metadata,
  }) {
    return LearningStep(
      id: 'step_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: type,
      instructions: instructions ?? [],
      boardState: boardState,
      highlightPositions: highlightPositions,
      requiredMoves: requiredMoves,
      demonstrationMoves: demonstrationMoves,
      successMessage: successMessage,
      failureMessage: failureMessage,
      metadata: metadata,
    );
  }
}
