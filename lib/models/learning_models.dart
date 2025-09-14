import 'package:equatable/equatable.dart';
import 'chess_models.dart';

/// 学习模式类型
enum LearningMode {
  basicRules, // 基础规则
  pieceMovement, // 棋子移动
  specialMoves, // 特殊移动（王车易位、吃过路兵、兵升变）
  tactics, // 战术训练
  endgame, // 残局训练
  openings, // 开局训练
}

/// 学习步骤状态
enum StepStatus {
  notStarted, // 未开始
  inProgress, // 进行中
  completed, // 已完成
  failed, // 失败
}

/// 学习步骤类型
enum StepType {
  explanation, // 解释说明
  demonstration, // 演示
  practice, // 练习
  quiz, // 测验
}

/// 学习步骤
class LearningStep extends Equatable {
  final String id;
  final String title;
  final String description;
  final StepType type;
  final StepStatus status;
  final List<String> instructions;
  final List<List<ChessPiece?>>? boardState;
  final List<Position>? highlightPositions;
  final List<ChessMove>? requiredMoves;
  final List<ChessMove>? demonstrationMoves;
  final String? successMessage;
  final String? failureMessage;
  final Map<String, dynamic>? metadata;

  const LearningStep({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.status = StepStatus.notStarted,
    this.instructions = const [],
    this.boardState,
    this.highlightPositions,
    this.requiredMoves,
    this.demonstrationMoves,
    this.successMessage,
    this.failureMessage,
    this.metadata,
  });

  LearningStep copyWith({
    String? id,
    String? title,
    String? description,
    StepType? type,
    StepStatus? status,
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
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      instructions: instructions ?? this.instructions,
      boardState: boardState ?? this.boardState,
      highlightPositions: highlightPositions ?? this.highlightPositions,
      requiredMoves: requiredMoves ?? this.requiredMoves,
      demonstrationMoves: demonstrationMoves ?? this.demonstrationMoves,
      successMessage: successMessage ?? this.successMessage,
      failureMessage: failureMessage ?? this.failureMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        status,
        instructions,
        boardState,
        highlightPositions,
        requiredMoves,
        demonstrationMoves,
        successMessage,
        failureMessage,
        metadata,
      ];
}

/// 学习课程
class LearningLesson extends Equatable {
  final String id;
  final String title;
  final String description;
  final LearningMode mode;
  final List<LearningStep> steps;
  final int currentStepIndex;
  final bool isCompleted;
  final int score;
  final Duration? timeSpent;

  const LearningLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.mode,
    required this.steps,
    this.currentStepIndex = 0,
    this.isCompleted = false,
    this.score = 0,
    this.timeSpent,
  });

  LearningStep? get currentStep {
    if (currentStepIndex >= 0 && currentStepIndex < steps.length) {
      return steps[currentStepIndex];
    }
    return null;
  }

  double get progress {
    if (steps.isEmpty) return 0.0;
    final completedSteps =
        steps.where((step) => step.status == StepStatus.completed).length;
    return completedSteps / steps.length;
  }

  LearningLesson copyWith({
    String? id,
    String? title,
    String? description,
    LearningMode? mode,
    List<LearningStep>? steps,
    int? currentStepIndex,
    bool? isCompleted,
    int? score,
    Duration? timeSpent,
  }) {
    return LearningLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mode: mode ?? this.mode,
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      score: score ?? this.score,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        mode,
        steps,
        currentStepIndex,
        isCompleted,
        score,
        timeSpent,
      ];
}

/// 学习状态
class LearningState extends Equatable {
  final LearningLesson? currentLesson;
  final List<LearningLesson> availableLessons;
  final bool isLoading;
  final String? error;
  final DateTime? startTime;
  final List<List<ChessPiece?>>? currentBoard;
  final List<Position> highlightedPositions;
  final List<ChessMove> moveHistory;
  final String? currentInstruction;
  final bool isWaitingForMove;
  final bool isDemonstrating;

  const LearningState({
    this.currentLesson,
    this.availableLessons = const [],
    this.isLoading = false,
    this.error,
    this.startTime,
    this.currentBoard,
    this.highlightedPositions = const [],
    this.moveHistory = const [],
    this.currentInstruction,
    this.isWaitingForMove = false,
    this.isDemonstrating = false,
  });

  LearningState copyWith({
    LearningLesson? currentLesson,
    List<LearningLesson>? availableLessons,
    bool? isLoading,
    String? error,
    DateTime? startTime,
    List<List<ChessPiece?>>? currentBoard,
    List<Position>? highlightedPositions,
    List<ChessMove>? moveHistory,
    String? currentInstruction,
    bool? isWaitingForMove,
    bool? isDemonstrating,
  }) {
    return LearningState(
      currentLesson: currentLesson ?? this.currentLesson,
      availableLessons: availableLessons ?? this.availableLessons,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      startTime: startTime ?? this.startTime,
      currentBoard: currentBoard ?? this.currentBoard,
      highlightedPositions: highlightedPositions ?? this.highlightedPositions,
      moveHistory: moveHistory ?? this.moveHistory,
      currentInstruction: currentInstruction ?? this.currentInstruction,
      isWaitingForMove: isWaitingForMove ?? this.isWaitingForMove,
      isDemonstrating: isDemonstrating ?? this.isDemonstrating,
    );
  }

  @override
  List<Object?> get props => [
        currentLesson,
        availableLessons,
        isLoading,
        error,
        startTime,
        currentBoard,
        highlightedPositions,
        moveHistory,
        currentInstruction,
        isWaitingForMove,
        isDemonstrating,
      ];
}

/// AI介入等级
enum AIInterventionLevel {
  none, // 无介入
  gentle, // 轻微提示
  moderate, // 中等帮助
  strong, // 强力指导
  demonstration, // 完整演示
}

/// AI提示类型
enum AIHintType {
  move, // 移动建议
  explanation, // 解释说明
  demonstration, // 演示
  strategy, // 策略建议
}

/// AI语调
enum AITone {
  encouraging, // 鼓励性
  analytical, // 分析性
  friendly, // 友好
  professional, // 专业
}

/// AI详细程度
enum AIVerbosity {
  concise, // 简洁
  moderate, // 中等
  detailed, // 详细
}

/// 解释难度
enum ExplanationDifficulty {
  beginner, // 初学者
  intermediate, // 中级
  advanced, // 高级
}

/// AI提示
class AIHint extends Equatable {
  final AIHintType type;
  final String message;
  final ChessMove? suggestedMove;
  final double confidence;
  final List<Position>? highlightPositions;

  const AIHint({
    required this.type,
    required this.message,
    this.suggestedMove,
    required this.confidence,
    this.highlightPositions,
  });

  @override
  List<Object?> get props => [
        type,
        message,
        suggestedMove,
        confidence,
        highlightPositions,
      ];
}

/// AI解释
class AIExplanation extends Equatable {
  final String title;
  final String content;
  final List<String> keyPoints;
  final ExplanationDifficulty difficulty;
  final List<ChessMove>? demonstrationMoves;

  const AIExplanation({
    required this.title,
    required this.content,
    required this.keyPoints,
    required this.difficulty,
    this.demonstrationMoves,
  });

  @override
  List<Object?> get props => [
        title,
        content,
        keyPoints,
        difficulty,
        demonstrationMoves,
      ];
}

/// AI个性设置
class AIPersonality extends Equatable {
  final AITone tone;
  final AIVerbosity verbosity;
  final bool useEncouragement;
  final bool adaptToUserLevel;

  const AIPersonality({
    required this.tone,
    required this.verbosity,
    this.useEncouragement = true,
    this.adaptToUserLevel = true,
  });

  @override
  List<Object?> get props => [
        tone,
        verbosity,
        useEncouragement,
        adaptToUserLevel,
      ];
}

/// AI介入效果统计
class InterventionEffectiveness extends Equatable {
  final int totalInterventions;
  final int successfulInterventions;
  final double successRate;
  final double averageInterventionLevel;
  final Map<AIInterventionLevel, int> interventionCounts;

  const InterventionEffectiveness({
    required this.totalInterventions,
    required this.successfulInterventions,
    required this.successRate,
    required this.averageInterventionLevel,
    required this.interventionCounts,
  });

  @override
  List<Object?> get props => [
        totalInterventions,
        successfulInterventions,
        successRate,
        averageInterventionLevel,
        interventionCounts,
      ];
}
