import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/learning_models.dart';
import '../models/chess_models.dart';
import '../services/learning_service.dart';
import 'learning_events.dart';

class LearningBloc extends Bloc<LearningEvent, LearningState> {
  final LearningService _learningService;
  Timer? _demonstrationTimer;

  LearningBloc({LearningService? learningService})
      : _learningService = learningService ?? LearningService(),
        super(const LearningState()) {
    
    on<LoadAvailableLessons>(_onLoadAvailableLessons);
    on<StartLesson>(_onStartLesson);
    on<StartLearningMode>(_onStartLearningMode);
    on<NextStep>(_onNextStep);
    on<PreviousStep>(_onPreviousStep);
    on<GoToStep>(_onGoToStep);
    on<RestartCurrentStep>(_onRestartCurrentStep);
    on<ExecuteLearningMove>(_onExecuteLearningMove);
    on<StartDemonstration>(_onStartDemonstration);
    on<StopDemonstration>(_onStopDemonstration);
    on<DemonstrateNextMove>(_onDemonstrateNextMove);
    on<ResetDemonstration>(_onResetDemonstration);
    on<CheckAnswer>(_onCheckAnswer);
    on<ShowHint>(_onShowHint);
    on<SkipCurrentStep>(_onSkipCurrentStep);
    on<CompleteLesson>(_onCompleteLesson);
    on<ExitLearning>(_onExitLearning);
    on<UpdateStepStatus>(_onUpdateStepStatus);
    on<SetBoardState>(_onSetBoardState);
    on<HighlightPositions>(_onHighlightPositions);
    on<ClearHighlights>(_onClearHighlights);
    on<ShowInstruction>(_onShowInstruction);
    on<ClearInstruction>(_onClearInstruction);
    on<ResetLearningState>(_onResetLearningState);
    on<SaveProgress>(_onSaveProgress);
    on<LoadProgress>(_onLoadProgress);
  }

  @override
  Future<void> close() {
    _demonstrationTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadAvailableLessons(
    LoadAvailableLessons event,
    Emitter<LearningState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final lessons = await _learningService.getAvailableLessons();
      emit(state.copyWith(
        availableLessons: lessons,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '加载课程失败: $e',
      ));
    }
  }

  Future<void> _onStartLesson(
    StartLesson event,
    Emitter<LearningState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final lesson = await _learningService.getLessonById(event.lessonId);
      if (lesson != null) {
        emit(state.copyWith(
          currentLesson: lesson,
          startTime: DateTime.now(),
          isLoading: false,
        ));
        
        // 初始化第一步
        _initializeCurrentStep(emit);
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: '课程不存在',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '启动课程失败: $e',
      ));
    }
  }

  Future<void> _onStartLearningMode(
    StartLearningMode event,
    Emitter<LearningState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final lesson = await _learningService.getLessonByMode(event.mode);
      if (lesson != null) {
        emit(state.copyWith(
          currentLesson: lesson,
          startTime: DateTime.now(),
          isLoading: false,
        ));
        
        // 初始化第一步
        _initializeCurrentStep(emit);
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: '该学习模式暂未实现',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '启动学习模式失败: $e',
      ));
    }
  }

  void _onNextStep(
    NextStep event,
    Emitter<LearningState> emit,
  ) {
    final lesson = state.currentLesson;
    if (lesson == null) return;

    final nextIndex = lesson.currentStepIndex + 1;
    if (nextIndex < lesson.steps.length) {
      final updatedLesson = lesson.copyWith(currentStepIndex: nextIndex);
      emit(state.copyWith(currentLesson: updatedLesson));
      _initializeCurrentStep(emit);
    } else {
      // 课程完成
      add(const CompleteLesson());
    }
  }

  void _onPreviousStep(
    PreviousStep event,
    Emitter<LearningState> emit,
  ) {
    final lesson = state.currentLesson;
    if (lesson == null) return;

    final prevIndex = lesson.currentStepIndex - 1;
    if (prevIndex >= 0) {
      final updatedLesson = lesson.copyWith(currentStepIndex: prevIndex);
      emit(state.copyWith(currentLesson: updatedLesson));
      _initializeCurrentStep(emit);
    }
  }

  void _onGoToStep(
    GoToStep event,
    Emitter<LearningState> emit,
  ) {
    final lesson = state.currentLesson;
    if (lesson == null) return;

    if (event.stepIndex >= 0 && event.stepIndex < lesson.steps.length) {
      final updatedLesson = lesson.copyWith(currentStepIndex: event.stepIndex);
      emit(state.copyWith(currentLesson: updatedLesson));
      _initializeCurrentStep(emit);
    }
  }

  void _onRestartCurrentStep(
    RestartCurrentStep event,
    Emitter<LearningState> emit,
  ) {
    _initializeCurrentStep(emit);
  }

  void _onExecuteLearningMove(
    ExecuteLearningMove event,
    Emitter<LearningState> emit,
  ) {
    final lesson = state.currentLesson;
    final currentStep = lesson?.currentStep;
    
    if (lesson == null || currentStep == null) return;
    if (currentStep.type != StepType.practice) return;

    final move = ChessMove(
      from: event.from,
      to: event.to,
      piece: state.currentBoard?[event.from.row][event.from.col] ?? 
             const ChessPiece(type: PieceType.pawn, color: PieceColor.white),
    );

    // 检查移动是否正确
    final isCorrectMove = _isCorrectMove(move, currentStep);
    
    if (isCorrectMove) {
      // 执行移动
      final newBoard = _executeMove(state.currentBoard!, move);
      final newMoveHistory = [...state.moveHistory, move];
      
      emit(state.copyWith(
        currentBoard: newBoard,
        moveHistory: newMoveHistory,
        currentInstruction: currentStep.successMessage ?? '做得很好！',
      ));

      // 检查是否完成了所有必需的移动
      if (_isStepCompleted(currentStep, newMoveHistory)) {
        _completeCurrentStep(emit);
      }
    } else {
      emit(state.copyWith(
        currentInstruction: currentStep.failureMessage ?? '这个移动不正确，请再试一次。',
      ));
    }
  }

  void _initializeCurrentStep(Emitter<LearningState> emit) {
    final lesson = state.currentLesson;
    final currentStep = lesson?.currentStep;
    
    if (lesson == null || currentStep == null) return;

    // 设置棋盘状态
    final board = currentStep.boardState ?? _createInitialBoard();
    
    // 设置高亮位置
    final highlights = currentStep.highlightPositions ?? [];
    
    // 设置指令
    final instruction = currentStep.instructions.isNotEmpty 
        ? currentStep.instructions.first 
        : currentStep.description;

    emit(state.copyWith(
      currentBoard: board,
      highlightedPositions: highlights,
      moveHistory: [],
      currentInstruction: instruction,
      isWaitingForMove: currentStep.type == StepType.practice,
      isDemonstrating: false,
    ));

    // 如果是演示类型，自动开始演示
    if (currentStep.type == StepType.demonstration) {
      add(const StartDemonstration());
    }
  }

  bool _isCorrectMove(ChessMove move, LearningStep step) {
    if (step.requiredMoves == null || step.requiredMoves!.isEmpty) {
      return true; // 如果没有指定必需移动，则任何移动都是正确的
    }

    // 检查移动是否在必需移动列表中
    return step.requiredMoves!.any((requiredMove) =>
        requiredMove.from.row == move.from.row &&
        requiredMove.from.col == move.from.col &&
        requiredMove.to.row == move.to.row &&
        requiredMove.to.col == move.to.col);
  }

  bool _isStepCompleted(LearningStep step, List<ChessMove> moveHistory) {
    if (step.requiredMoves == null || step.requiredMoves!.isEmpty) {
      return true;
    }

    // 检查是否完成了所有必需的移动
    return step.requiredMoves!.every((requiredMove) =>
        moveHistory.any((move) =>
            move.from.row == requiredMove.from.row &&
            move.from.col == requiredMove.from.col &&
            move.to.row == requiredMove.to.row &&
            move.to.col == requiredMove.to.col));
  }

  List<List<ChessPiece?>> _executeMove(List<List<ChessPiece?>> board, ChessMove move) {
    final newBoard = board.map((row) => List<ChessPiece?>.from(row)).toList();
    
    // 执行移动
    newBoard[move.to.row][move.to.col] = newBoard[move.from.row][move.from.col];
    newBoard[move.from.row][move.from.col] = null;
    
    return newBoard;
  }

  void _completeCurrentStep(Emitter<LearningState> emit) {
    final lesson = state.currentLesson;
    if (lesson == null) return;

    final currentStepIndex = lesson.currentStepIndex;
    final updatedSteps = List<LearningStep>.from(lesson.steps);
    updatedSteps[currentStepIndex] = updatedSteps[currentStepIndex].copyWith(
      status: StepStatus.completed,
    );

    final updatedLesson = lesson.copyWith(steps: updatedSteps);
    emit(state.copyWith(currentLesson: updatedLesson));

    // 延迟进入下一步
    Timer(const Duration(seconds: 2), () {
      add(const NextStep());
    });
  }

  // 其他事件处理方法的占位符
  void _onStartDemonstration(StartDemonstration event, Emitter<LearningState> emit) {
    // TODO: 实现演示逻辑
  }

  void _onStopDemonstration(StopDemonstration event, Emitter<LearningState> emit) {
    // TODO: 实现停止演示逻辑
  }

  void _onDemonstrateNextMove(DemonstrateNextMove event, Emitter<LearningState> emit) {
    // TODO: 实现演示下一步移动逻辑
  }

  void _onResetDemonstration(ResetDemonstration event, Emitter<LearningState> emit) {
    // TODO: 实现重置演示逻辑
  }

  void _onCheckAnswer(CheckAnswer event, Emitter<LearningState> emit) {
    // TODO: 实现检查答案逻辑
  }

  void _onShowHint(ShowHint event, Emitter<LearningState> emit) {
    // TODO: 实现显示提示逻辑
  }

  void _onSkipCurrentStep(SkipCurrentStep event, Emitter<LearningState> emit) {
    // TODO: 实现跳过当前步骤逻辑
  }

  void _onCompleteLesson(CompleteLesson event, Emitter<LearningState> emit) {
    // TODO: 实现完成课程逻辑
  }

  void _onExitLearning(ExitLearning event, Emitter<LearningState> emit) {
    // TODO: 实现退出学习逻辑
  }

  void _onUpdateStepStatus(UpdateStepStatus event, Emitter<LearningState> emit) {
    // TODO: 实现更新步骤状态逻辑
  }

  void _onSetBoardState(SetBoardState event, Emitter<LearningState> emit) {
    emit(state.copyWith(currentBoard: event.board));
  }

  void _onHighlightPositions(HighlightPositions event, Emitter<LearningState> emit) {
    emit(state.copyWith(highlightedPositions: event.positions));
  }

  void _onClearHighlights(ClearHighlights event, Emitter<LearningState> emit) {
    emit(state.copyWith(highlightedPositions: []));
  }

  void _onShowInstruction(ShowInstruction event, Emitter<LearningState> emit) {
    emit(state.copyWith(currentInstruction: event.instruction));
  }

  void _onClearInstruction(ClearInstruction event, Emitter<LearningState> emit) {
    emit(state.copyWith(currentInstruction: null));
  }

  void _onResetLearningState(ResetLearningState event, Emitter<LearningState> emit) {
    emit(const LearningState());
  }

  void _onSaveProgress(SaveProgress event, Emitter<LearningState> emit) {
    // TODO: 实现保存进度逻辑
  }

  void _onLoadProgress(LoadProgress event, Emitter<LearningState> emit) {
    // TODO: 实现加载进度逻辑
  }

  /// 创建初始棋盘状态
  List<List<ChessPiece?>> _createInitialBoard() {
    final board = List.generate(8, (row) {
      return List.generate(8, (col) {
        return _getInitialPiece(row, col);
      });
    });
    return board;
  }

  /// 获取初始位置的棋子
  ChessPiece? _getInitialPiece(int row, int col) {
    if (row == 1) {
      return const ChessPiece(type: PieceType.pawn, color: PieceColor.black);
    } else if (row == 6) {
      return const ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    } else if (row == 0 || row == 7) {
      final color = row == 0 ? PieceColor.black : PieceColor.white;
      switch (col) {
        case 0:
        case 7:
          return ChessPiece(type: PieceType.rook, color: color);
        case 1:
        case 6:
          return ChessPiece(type: PieceType.knight, color: color);
        case 2:
        case 5:
          return ChessPiece(type: PieceType.bishop, color: color);
        case 3:
          return ChessPiece(type: PieceType.queen, color: color);
        case 4:
          return ChessPiece(type: PieceType.king, color: color);
      }
    }
    return null;
  }
}
