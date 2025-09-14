import 'package:equatable/equatable.dart';
import '../models/learning_models.dart';
import '../models/chess_models.dart';

/// 学习模式事件基类
abstract class LearningEvent extends Equatable {
  const LearningEvent();

  @override
  List<Object?> get props => [];
}

/// 加载可用课程
class LoadAvailableLessons extends LearningEvent {
  const LoadAvailableLessons();
}

/// 开始课程
class StartLesson extends LearningEvent {
  final String lessonId;

  const StartLesson(this.lessonId);

  @override
  List<Object?> get props => [lessonId];
}

/// 开始特定模式的课程
class StartLearningMode extends LearningEvent {
  final LearningMode mode;

  const StartLearningMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

/// 进入下一步
class NextStep extends LearningEvent {
  const NextStep();
}

/// 进入上一步
class PreviousStep extends LearningEvent {
  const PreviousStep();
}

/// 跳转到指定步骤
class GoToStep extends LearningEvent {
  final int stepIndex;

  const GoToStep(this.stepIndex);

  @override
  List<Object?> get props => [stepIndex];
}

/// 重新开始当前步骤
class RestartCurrentStep extends LearningEvent {
  const RestartCurrentStep();
}

/// 用户执行移动
class ExecuteLearningMove extends LearningEvent {
  final Position from;
  final Position to;

  const ExecuteLearningMove(this.from, this.to);

  @override
  List<Object?> get props => [from, to];
}

/// 开始演示
class StartDemonstration extends LearningEvent {
  const StartDemonstration();
}

/// 停止演示
class StopDemonstration extends LearningEvent {
  const StopDemonstration();
}

/// 演示下一步移动
class DemonstrateNextMove extends LearningEvent {
  const DemonstrateNextMove();
}

/// 重置演示
class ResetDemonstration extends LearningEvent {
  const ResetDemonstration();
}

/// 检查用户答案
class CheckAnswer extends LearningEvent {
  final dynamic answer;

  const CheckAnswer(this.answer);

  @override
  List<Object?> get props => [answer];
}

/// 显示提示
class ShowHint extends LearningEvent {
  const ShowHint();
}

/// 跳过当前步骤
class SkipCurrentStep extends LearningEvent {
  const SkipCurrentStep();
}

/// 完成课程
class CompleteLesson extends LearningEvent {
  const CompleteLesson();
}

/// 退出学习模式
class ExitLearning extends LearningEvent {
  const ExitLearning();
}

/// 更新步骤状态
class UpdateStepStatus extends LearningEvent {
  final String stepId;
  final StepStatus status;

  const UpdateStepStatus(this.stepId, this.status);

  @override
  List<Object?> get props => [stepId, status];
}

/// 设置棋盘状态
class SetBoardState extends LearningEvent {
  final List<List<ChessPiece?>> board;

  const SetBoardState(this.board);

  @override
  List<Object?> get props => [board];
}

/// 高亮位置
class HighlightPositions extends LearningEvent {
  final List<Position> positions;

  const HighlightPositions(this.positions);

  @override
  List<Object?> get props => [positions];
}

/// 清除高亮
class ClearHighlights extends LearningEvent {
  const ClearHighlights();
}

/// 显示指令
class ShowInstruction extends LearningEvent {
  final String instruction;

  const ShowInstruction(this.instruction);

  @override
  List<Object?> get props => [instruction];
}

/// 清除指令
class ClearInstruction extends LearningEvent {
  const ClearInstruction();
}

/// 重置学习状态
class ResetLearningState extends LearningEvent {
  const ResetLearningState();
}

/// 保存学习进度
class SaveProgress extends LearningEvent {
  const SaveProgress();
}

/// 加载学习进度
class LoadProgress extends LearningEvent {
  final String lessonId;

  const LoadProgress(this.lessonId);

  @override
  List<Object?> get props => [lessonId];
}
