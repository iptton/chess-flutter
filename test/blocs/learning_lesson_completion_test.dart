import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:testflutter/blocs/learning_bloc.dart';
import 'package:testflutter/blocs/learning_events.dart';
import 'package:testflutter/models/learning_models.dart';
import 'package:testflutter/models/chess_models.dart';

void main() {
  group('LearningBloc 课程完成庆祝功能', () {
    late LearningBloc learningBloc;

    setUp(() {
      learningBloc = LearningBloc();
    });

    tearDown(() {
      learningBloc.close();
    });

    group('课程完成庆祝', () {
      blocTest<LearningBloc, LearningState>(
        '当课程完成时应该设置isLessonCompleted为true',
        build: () => learningBloc,
        act: (bloc) {
          // 设置一个已完成的课程
          final lesson = LearningLesson(
            id: 'test-lesson',
            title: '测试课程',
            description: '测试描述',
            mode: LearningMode.basicRules,
            steps: [
              LearningStep(
                id: 'step1',
                title: '第一步',
                description: '第一步描述',
                type: StepType.explanation,
                status: StepStatus.completed,
              ),
            ],
            currentStepIndex: 0,
          );

          // 设置初始状态
          bloc.emit(LearningState(
            currentLesson: lesson,
            startTime: DateTime.now().subtract(Duration(minutes: 5)),
          ));

          // 完成课程
          bloc.add(const CompleteLesson());
        },
        expect: () => [
          // 课程完成后应该设置庆祝状态
          isA<LearningState>()
              .having((s) => s.isLessonCompleted, 'isLessonCompleted', true)
              .having((s) => s.currentLesson?.isCompleted, 'lesson.isCompleted', true)
              .having((s) => s.currentInstruction, 'currentInstruction', 
                      contains('恭喜！您已完成本课程！')),
        ],
      );

      blocTest<LearningBloc, LearningState>(
        '确认课程完成后应该重置isLessonCompleted并退出学习模式',
        build: () => learningBloc,
        act: (bloc) {
          // 设置课程完成庆祝状态
          bloc.emit(LearningState(
            currentLesson: LearningLesson(
              id: 'test-lesson',
              title: '测试课程',
              description: '测试描述',
              mode: LearningMode.basicRules,
              steps: [
                LearningStep(
                  id: 'step1',
                  title: '第一步',
                  description: '第一步描述',
                  type: StepType.explanation,
                  status: StepStatus.completed,
                ),
              ],
              isCompleted: true,
            ),
            isLessonCompleted: true,
          ));

          // 确认课程完成
          bloc.add(const ConfirmLessonCompletion());
        },
        expect: () => [
          // 重置isLessonCompleted
          isA<LearningState>()
              .having((s) => s.isLessonCompleted, 'isLessonCompleted', false),
          // 退出学习模式（清除当前课程）
          isA<LearningState>()
              .having((s) => s.currentLesson, 'currentLesson', null),
        ],
      );
    });

    group('课程时长记录', () {
      blocTest<LearningBloc, LearningState>(
        '课程完成时应该记录学习时长',
        build: () => learningBloc,
        act: (bloc) {
          final startTime = DateTime.now().subtract(Duration(minutes: 10));
          
          // 设置一个课程和开始时间
          final lesson = LearningLesson(
            id: 'test-lesson',
            title: '测试课程',
            description: '测试描述',
            mode: LearningMode.pieceMovement,
            steps: [
              LearningStep(
                id: 'step1',
                title: '第一步',
                description: '第一步描述',
                type: StepType.practice,
                status: StepStatus.completed,
              ),
            ],
          );

          // 设置初始状态
          bloc.emit(LearningState(
            currentLesson: lesson,
            startTime: startTime,
          ));

          // 完成课程
          bloc.add(const CompleteLesson());
        },
        expect: () => [
          // 课程完成后应该记录时长
          isA<LearningState>()
              .having((s) => s.currentLesson?.timeSpent, 'timeSpent', isNotNull)
              .having((s) => s.currentLesson?.timeSpent?.inMinutes, 'timeSpent.inMinutes', 
                      greaterThanOrEqualTo(9)), // 大约10分钟，允许一些误差
        ],
      );

      blocTest<LearningBloc, LearningState>(
        '没有开始时间时课程完成不应该记录时长',
        build: () => learningBloc,
        act: (bloc) {
          // 设置一个课程但没有开始时间
          final lesson = LearningLesson(
            id: 'test-lesson',
            title: '测试课程',
            description: '测试描述',
            mode: LearningMode.tactics,
            steps: [
              LearningStep(
                id: 'step1',
                title: '第一步',
                description: '第一步描述',
                type: StepType.quiz,
                status: StepStatus.completed,
              ),
            ],
          );

          // 设置初始状态（没有startTime）
          bloc.emit(LearningState(
            currentLesson: lesson,
          ));

          // 完成课程
          bloc.add(const CompleteLesson());
        },
        expect: () => [
          // 课程完成后时长应该为null
          isA<LearningState>()
              .having((s) => s.currentLesson?.timeSpent, 'timeSpent', null),
        ],
      );
    });
  });
}
