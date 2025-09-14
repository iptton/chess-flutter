import '../models/learning_models.dart';
import '../models/chess_models.dart';

class AILearningService {
  static final AILearningService _instance = AILearningService._internal();
  factory AILearningService() => _instance;
  AILearningService._internal();

  // Track intervention history for effectiveness analysis
  final Map<String, List<_InterventionRecord>> _interventionHistory = {};

  /// 判断是否需要AI介入
  bool shouldUseAIIntervention(LearningLesson lesson) {
    // 基础规则和棋子移动不需要AI介入
    if (lesson.mode == LearningMode.basicRules ||
        lesson.mode == LearningMode.pieceMovement) {
      return false;
    }

    // 残局、战术、特殊移动需要AI介入
    return lesson.mode == LearningMode.endgame ||
        lesson.mode == LearningMode.tactics ||
        lesson.mode == LearningMode.specialMoves;
  }

  /// 获取AI提示
  Future<AIHint?> getAIHint(LearningStep step, int attemptCount) async {
    // 模拟AI分析延迟
    await Future.delayed(const Duration(milliseconds: 500));

    if (attemptCount < 1) {
      return null; // 第一次尝试前不给提示
    }

    final hintType = _determineHintType(attemptCount);
    final message = _generateHintMessage(step, hintType, attemptCount);
    final suggestedMove = _generateSuggestedMove(step, hintType);
    final confidence = _calculateConfidence(step, hintType);

    return AIHint(
      type: hintType,
      message: message,
      suggestedMove: suggestedMove,
      confidence: confidence,
      highlightPositions: _getHintHighlights(step, suggestedMove),
    );
  }

  /// 获取AI介入等级
  Future<AIInterventionLevel> getInterventionLevel(
      LearningStep step, int attemptCount, int userSkillLevel) async {
    // 根据用户技能等级调整介入阈值
    final skillAdjustment =
        userSkillLevel; // 0=beginner, 1=intermediate, 2=advanced
    final adjustedAttemptCount = attemptCount +
        skillAdjustment; // Higher skill = more attempts before help

    if (adjustedAttemptCount <= 1) {
      return AIInterventionLevel.none;
    } else if (adjustedAttemptCount == 2) {
      return AIInterventionLevel.gentle;
    } else if (adjustedAttemptCount == 3) {
      return AIInterventionLevel.moderate;
    } else if (adjustedAttemptCount == 4) {
      return AIInterventionLevel.strong;
    } else {
      return AIInterventionLevel.demonstration;
    }
  }

  /// 获取AI解释
  Future<AIExplanation?> getAIExplanation(
      LearningStep step, String question) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return AIExplanation(
      title: '关于 ${step.title}',
      content: _generateExplanationContent(step, question),
      keyPoints: _generateKeyPoints(step),
      difficulty: _determineDifficulty(step),
      demonstrationMoves: step.demonstrationMoves,
    );
  }

  /// 获取AI个性设置
  AIPersonality getAIPersonality(LearningStep step) {
    if (step.type == StepType.explanation ||
        step.mode == LearningMode.basicRules) {
      return const AIPersonality(
        tone: AITone.encouraging,
        verbosity: AIVerbosity.detailed,
        useEncouragement: true,
        adaptToUserLevel: true,
      );
    } else {
      return const AIPersonality(
        tone: AITone.analytical,
        verbosity: AIVerbosity.concise,
        useEncouragement: false,
        adaptToUserLevel: true,
      );
    }
  }

  /// 记录AI介入
  Future<void> recordAIIntervention(
      String stepId, AIInterventionLevel level, bool wasSuccessful) async {
    _interventionHistory.putIfAbsent(stepId, () => []);
    _interventionHistory[stepId]!.add(_InterventionRecord(
      level: level,
      wasSuccessful: wasSuccessful,
      timestamp: DateTime.now(),
    ));
  }

  /// 获取介入效果统计
  Future<InterventionEffectiveness?> getInterventionEffectiveness(
      String stepId) async {
    final records = _interventionHistory[stepId];
    if (records == null || records.isEmpty) {
      return null;
    }

    final totalInterventions = records.length;
    final successfulInterventions =
        records.where((r) => r.wasSuccessful).length;
    final successRate = successfulInterventions / totalInterventions;

    final levelSum = records.map((r) => r.level.index).reduce((a, b) => a + b);
    final averageInterventionLevel = levelSum / totalInterventions;

    final interventionCounts = <AIInterventionLevel, int>{};
    for (final level in AIInterventionLevel.values) {
      interventionCounts[level] = records.where((r) => r.level == level).length;
    }

    return InterventionEffectiveness(
      totalInterventions: totalInterventions,
      successfulInterventions: successfulInterventions,
      successRate: successRate,
      averageInterventionLevel: averageInterventionLevel,
      interventionCounts: interventionCounts,
    );
  }

  // Private helper methods

  AIHintType _determineHintType(int attemptCount) {
    if (attemptCount == 1) {
      return AIHintType.move;
    } else if (attemptCount == 2) {
      return AIHintType.explanation;
    } else {
      return AIHintType.demonstration;
    }
  }

  String _generateHintMessage(
      LearningStep step, AIHintType type, int attemptCount) {
    switch (type) {
      case AIHintType.move:
        return '试试移动高亮的棋子到建议的位置。';
      case AIHintType.explanation:
        return '这个位置的关键是要考虑 ${step.title} 的基本原理。';
      case AIHintType.demonstration:
        return '让我来演示正确的移动序列。';
      case AIHintType.strategy:
        return '从战略角度考虑，这里需要关注长期目标。';
    }
  }

  ChessMove? _generateSuggestedMove(LearningStep step, AIHintType type) {
    if (type == AIHintType.move && step.requiredMoves?.isNotEmpty == true) {
      return step.requiredMoves!.first;
    }
    return null;
  }

  double _calculateConfidence(LearningStep step, AIHintType type) {
    // 基于步骤类型和提示类型计算置信度
    if (step.type == StepType.practice && type == AIHintType.move) {
      return 0.9;
    } else if (step.type == StepType.explanation) {
      return 0.8;
    } else {
      return 0.7;
    }
  }

  List<Position>? _getHintHighlights(
      LearningStep step, ChessMove? suggestedMove) {
    if (suggestedMove != null) {
      return [suggestedMove.from, suggestedMove.to];
    }
    return step.highlightPositions;
  }

  String _generateExplanationContent(LearningStep step, String question) {
    return '在 ${step.title} 中，${step.description}。这个概念对于理解国际象棋的深层策略非常重要。';
  }

  List<String> _generateKeyPoints(LearningStep step) {
    return [
      '理解 ${step.title} 的基本概念',
      '掌握相关的移动规则',
      '识别实际游戏中的应用场景',
      '练习相关的战术技巧',
    ];
  }

  ExplanationDifficulty _determineDifficulty(LearningStep step) {
    // For endgame steps, check if it's a basic endgame
    if (step.mode == LearningMode.endgame && step.id.contains('king_pawn')) {
      return ExplanationDifficulty.intermediate;
    }

    switch (step.mode) {
      case LearningMode.basicRules:
      case LearningMode.pieceMovement:
        return ExplanationDifficulty.beginner;
      case LearningMode.specialMoves:
      case LearningMode.tactics:
        return ExplanationDifficulty.intermediate;
      case LearningMode.endgame:
      case LearningMode.openings:
        return ExplanationDifficulty.advanced;
    }
  }
}

// Private class for tracking intervention records
class _InterventionRecord {
  final AIInterventionLevel level;
  final bool wasSuccessful;
  final DateTime timestamp;

  _InterventionRecord({
    required this.level,
    required this.wasSuccessful,
    required this.timestamp,
  });
}

// Extension to add mode property to LearningStep
extension LearningStepExtension on LearningStep {
  LearningMode get mode {
    // Determine mode based on step ID or other properties
    if (id.contains('basic') || id.contains('rule')) {
      return LearningMode.basicRules;
    } else if (id.contains('endgame') || id.contains('king_pawn')) {
      return LearningMode.endgame;
    } else if (id.contains('castling') ||
        id.contains('en_passant') ||
        id.contains('promotion')) {
      return LearningMode.specialMoves;
    } else if (id.contains('tactic') || id.contains('pin')) {
      return LearningMode.tactics;
    } else if (id.contains('pawn') ||
        id.contains('rook') ||
        id.contains('knight') ||
        id.contains('bishop') ||
        id.contains('queen') ||
        id.contains('king')) {
      return LearningMode.pieceMovement;
    } else {
      return LearningMode.openings;
    }
  }
}
