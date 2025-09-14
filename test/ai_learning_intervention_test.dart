import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';
import 'package:testflutter/services/ai_learning_service.dart';
import 'package:testflutter/data/learning_lessons.dart';

void main() {
  group('AI Learning Intervention Tests', () {
    late AILearningService aiLearningService;
    late LearningLessons learningLessons;

    setUp(() {
      aiLearningService = AILearningService();
      learningLessons = LearningLessons();
    });

    test('should determine when AI intervention is needed', () {
      // Arrange: Create different lesson types
      final basicRulesLesson = learningLessons.basicRulesLesson;
      final endgameLesson = learningLessons.endgameLesson;
      final tacticsLesson = learningLessons.tacticsLesson;

      // Act & Assert: Basic rules should not need AI intervention
      expect(
          aiLearningService.shouldUseAIIntervention(basicRulesLesson), isFalse);

      // Act & Assert: Endgame should need AI intervention
      expect(aiLearningService.shouldUseAIIntervention(endgameLesson), isTrue);

      // Act & Assert: Tactics should need AI intervention
      expect(aiLearningService.shouldUseAIIntervention(tacticsLesson), isTrue);
    });

    test('should provide AI hints for difficult positions', () async {
      // Arrange: Create a difficult endgame position
      final endgameStep = LearningStep(
        id: 'difficult_endgame',
        title: '困难残局',
        description: '需要AI帮助的残局',
        type: StepType.practice,
        boardState: _createDifficultEndgameBoard(),
        requiredMoves: [
          ChessMove(
            from: const Position(row: 7, col: 4),
            to: const Position(row: 6, col: 4),
            piece:
                const ChessPiece(type: PieceType.king, color: PieceColor.white),
          ),
        ],
      );

      // Act
      final hint = await aiLearningService.getAIHint(
          endgameStep, 1); // After 1 failed attempt

      // Assert
      expect(hint, isNotNull);
      expect(hint!.type, equals(AIHintType.move));
      expect(hint.message, isNotEmpty);
      expect(hint.suggestedMove, isNotNull);
      expect(hint.confidence, greaterThan(0.5));
    });

    test('should provide different types of AI hints', () async {
      // Arrange: Create different scenarios
      final tacticsStep = LearningStep(
        id: 'tactics_step',
        title: '战术练习',
        description: '需要战术提示',
        type: StepType.practice,
        boardState: _createTacticsBoard(),
      );

      // Act: Get different hint types
      final moveHint = await aiLearningService.getAIHint(tacticsStep, 1);
      final explanationHint = await aiLearningService.getAIHint(tacticsStep, 2);
      final demonstrationHint =
          await aiLearningService.getAIHint(tacticsStep, 3);

      // Assert: Should provide different hint types based on attempt count
      expect(moveHint?.type, equals(AIHintType.move));
      expect(explanationHint?.type, equals(AIHintType.explanation));
      expect(demonstrationHint?.type, equals(AIHintType.demonstration));
    });

    test('should escalate AI intervention based on user struggles', () async {
      // Arrange: Create a learning step
      final step = LearningStep(
        id: 'escalation_test',
        title: '升级测试',
        description: '测试AI介入升级',
        type: StepType.practice,
        boardState: _createTestBoard(),
      );

      // Act & Assert: Progressive escalation

      // First attempt - no hint
      var intervention =
          await aiLearningService.getInterventionLevel(step, 1, 0);
      expect(intervention, equals(AIInterventionLevel.none));

      // Second attempt - gentle hint
      intervention = await aiLearningService.getInterventionLevel(step, 2, 0);
      expect(intervention, equals(AIInterventionLevel.gentle));

      // Third attempt - moderate help
      intervention = await aiLearningService.getInterventionLevel(step, 3, 0);
      expect(intervention, equals(AIInterventionLevel.moderate));

      // Fourth attempt - strong guidance
      intervention = await aiLearningService.getInterventionLevel(step, 4, 0);
      expect(intervention, equals(AIInterventionLevel.strong));

      // Fifth attempt - full demonstration
      intervention = await aiLearningService.getInterventionLevel(step, 5, 0);
      expect(intervention, equals(AIInterventionLevel.demonstration));
    });

    test('should consider user skill level in AI intervention', () async {
      // Arrange: Create same step for different skill levels
      final step = LearningStep(
        id: 'skill_test',
        title: '技能测试',
        description: '测试技能等级影响',
        type: StepType.practice,
        boardState: _createTestBoard(),
      );

      // Act: Get intervention for different skill levels
      final beginnerIntervention =
          await aiLearningService.getInterventionLevel(step, 2, 0); // Beginner
      final intermediateIntervention = await aiLearningService
          .getInterventionLevel(step, 2, 1); // Intermediate
      final advancedIntervention =
          await aiLearningService.getInterventionLevel(step, 2, 2); // Advanced

      // Assert: Advanced players should get less help (lower intervention level)
      expect(
          beginnerIntervention.index, lessThan(intermediateIntervention.index));
      expect(
          intermediateIntervention.index, lessThan(advancedIntervention.index));
    });

    test('should provide contextual AI explanations', () async {
      // Arrange: Create endgame position
      final endgameStep = LearningStep(
        id: 'king_pawn_explanation_test',
        title: '解释测试',
        description: '测试AI解释',
        type: StepType.practice,
        boardState: _createKingPawnEndgameBoard(),
      );

      // Act
      final explanation = await aiLearningService.getAIExplanation(
          endgameStep, 'Why is this move important?');

      // Assert
      expect(explanation, isNotNull);
      expect(explanation!.title, isNotEmpty);
      expect(explanation.content, isNotEmpty);
      expect(explanation.keyPoints, isNotEmpty);
      expect(
          explanation.difficulty, equals(ExplanationDifficulty.intermediate));
    });

    test('should adapt AI personality for learning context', () async {
      // Arrange: Create different learning contexts
      final basicStep = LearningStep(
        id: 'basic_test',
        title: '基础测试',
        description: '基础学习',
        type: StepType.explanation,
        boardState: _createTestBoard(),
      );

      final advancedStep = LearningStep(
        id: 'advanced_test',
        title: '高级测试',
        description: '高级学习',
        type: StepType.practice,
        boardState: _createDifficultEndgameBoard(),
      );

      // Act
      final basicPersonality = aiLearningService.getAIPersonality(basicStep);
      final advancedPersonality =
          aiLearningService.getAIPersonality(advancedStep);

      // Assert
      expect(basicPersonality.tone, equals(AITone.encouraging));
      expect(basicPersonality.verbosity, equals(AIVerbosity.detailed));
      expect(advancedPersonality.tone, equals(AITone.analytical));
      expect(advancedPersonality.verbosity, equals(AIVerbosity.concise));
    });

    test('should track AI intervention effectiveness', () async {
      // Arrange: Create learning session
      final step = LearningStep(
        id: 'tracking_test',
        title: '跟踪测试',
        description: '测试效果跟踪',
        type: StepType.practice,
        boardState: _createTestBoard(),
      );

      // Act: Simulate AI intervention and user success
      await aiLearningService.recordAIIntervention(
          step.id, AIInterventionLevel.moderate, true);
      await aiLearningService.recordAIIntervention(
          step.id, AIInterventionLevel.gentle, false);

      // Get effectiveness metrics
      final effectiveness =
          await aiLearningService.getInterventionEffectiveness(step.id);

      // Assert
      expect(effectiveness, isNotNull);
      expect(effectiveness!.totalInterventions, equals(2));
      expect(effectiveness.successfulInterventions, equals(1));
      expect(effectiveness.successRate, equals(0.5));
      expect(
          effectiveness.averageInterventionLevel, equals(1.5)); // (2 + 1) / 2
    });

    test('should disable AI intervention for basic learning modes', () {
      // Arrange: Create basic learning lessons
      final basicRulesLesson = learningLessons.basicRulesLesson;
      final pieceMovementLesson = learningLessons.pieceMovementLesson;

      // Act & Assert: Basic lessons should not use AI
      expect(
          aiLearningService.shouldUseAIIntervention(basicRulesLesson), isFalse);
      expect(aiLearningService.shouldUseAIIntervention(pieceMovementLesson),
          isFalse);
    });

    test('should enable AI intervention for complex learning modes', () {
      // Arrange: Create complex learning lessons
      final endgameLesson = learningLessons.endgameLesson;
      final tacticsLesson = learningLessons.tacticsLesson;

      // Act & Assert: Complex lessons should use AI
      expect(aiLearningService.shouldUseAIIntervention(endgameLesson), isTrue);
      expect(aiLearningService.shouldUseAIIntervention(tacticsLesson), isTrue);
    });
  });
}

// Helper methods for creating test boards
List<List<ChessPiece?>> _createDifficultEndgameBoard() {
  final board =
      List.generate(8, (row) => List.generate(8, (col) => null as ChessPiece?));

  // King and pawn endgame
  board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
  board[5][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
  board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);

  return board;
}

List<List<ChessPiece?>> _createTacticsBoard() {
  final board =
      List.generate(8, (row) => List.generate(8, (col) => null as ChessPiece?));

  // Pin tactic setup
  board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
  board[6][4] =
      const ChessPiece(type: PieceType.queen, color: PieceColor.white);
  board[4][4] = const ChessPiece(type: PieceType.rook, color: PieceColor.black);
  board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);

  return board;
}

List<List<ChessPiece?>> _createTestBoard() {
  final board =
      List.generate(8, (row) => List.generate(8, (col) => null as ChessPiece?));

  // Simple test setup
  board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
  board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);

  return board;
}

List<List<ChessPiece?>> _createKingPawnEndgameBoard() {
  final board =
      List.generate(8, (row) => List.generate(8, (col) => null as ChessPiece?));

  // King and pawn vs king
  board[7][4] = const ChessPiece(type: PieceType.king, color: PieceColor.white);
  board[5][4] = const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
  board[0][4] = const ChessPiece(type: PieceType.king, color: PieceColor.black);

  return board;
}
