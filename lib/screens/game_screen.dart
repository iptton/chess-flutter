import 'package:flutter/material.dart';

import '../widgets/chess_board.dart';
import '../widgets/ai_difficulty_selector.dart';
import '../widgets/themed_background.dart';
import '../services/chess_ai.dart';
import '../models/chess_models.dart';
import '../utils/ai_difficulty_strategy.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum GameMode {
  offline, // 单机对战（人机）
  online, // 联网对战
  faceToFace, // 面对面对战
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(
        title: '对战',
      ),
      body: ThemedBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ThemedCard(
                child: Column(
                  children: [
                    ThemedButton(
                      text: '单机对战（AI）',
                      icon: Icons.person,
                      onPressed: () => _startGame(context, GameMode.offline),
                    ),
                    const SizedBox(height: 16),
                    ThemedButton(
                      text: '面对面对战',
                      icon: Icons.people,
                      onPressed: () => _startGame(context, GameMode.faceToFace),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, GameMode mode) {
    if (mode == GameMode.offline) {
      // 单机对战模式，显示AI设置对话框
      _showAISettingsDialog(context);
    } else if (mode == GameMode.faceToFace) {
      // 面对面对战模式
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChessBoard(gameMode: mode),
        ),
      );
    } else {
      // 联网对战模式暂未实现
      Fluttertoast.showToast(
          msg: "开发中，敬请期待",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  void _showAISettingsDialog(BuildContext context) {
    AIDifficultyLevel selectedDifficulty = AIDifficultyLevel.intermediate;
    PieceColor playerColor = PieceColor.white;

    showDialog(
      context: context,
      builder: (context) => AIDifficultySelector(
        currentDifficulty: selectedDifficulty,
        showAdvancedOptions: true,
        showColorSelection: true,
        initialPlayerColor: playerColor,
        onGameStart: (difficulty, color) {
          Navigator.of(context).pop(true);
          _startAdvancedAIGame(context, difficulty, color);
        },
      ),
    );
  }

  void _startAIGame(
      BuildContext context, AIDifficulty difficulty, PieceColor playerColor) {
    final aiColor =
        playerColor == PieceColor.white ? PieceColor.black : PieceColor.white;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChessBoard(
          gameMode: GameMode.offline,
          aiDifficulty: difficulty,
          aiColor: aiColor,
          allowedPlayer: playerColor,
        ),
      ),
    );
  }

  void _startAdvancedAIGame(BuildContext context, AIDifficultyLevel difficulty,
      PieceColor playerColor) async {
    try {
      print('GameScreen: === 开始执行 _startAdvancedAIGame ===');

      final aiColor =
          playerColor == PieceColor.white ? PieceColor.black : PieceColor.white;

      print('GameScreen: 创建高级AI实例...');
      final ai = ChessAI.advanced(advancedDifficulty: difficulty);
      print('GameScreen: AI实例创建成功: ${ai.advancedDifficulty.displayName}');

      print('GameScreen: 检查context是否有效...');
      if (!context.mounted) {
        print('GameScreen: 错误 - context不可用');
        return;
      }
      print('GameScreen: context有效');

      print('GameScreen: 尝试简单的导航...');

      // 尝试使用传统的导航方式
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            print('GameScreen: 正在构建ChessBoard...');
            return ChessBoard(
              gameMode: GameMode.offline,
              aiColor: aiColor,
              allowedPlayer: playerColor,
              advancedAI: ai,
            );
          },
        ),
      );

      print('GameScreen: 导航完成，结果: $result');
    } catch (e, stackTrace) {
      print('GameScreen: _startAdvancedAIGame发生异常: $e');
      print('GameScreen: 堆栈跟踪: $stackTrace');

      // 如果高级AI失败，回退到传统AI
      print('GameScreen: 尝试回退到传统方式...');
      _startAIGame(context, difficulty._toOldDifficulty(), playerColor);
    }
  }
}

/// 扩展方法：将新难度等级转换为旧的枚举（用于兼容性）
extension AIDifficultyLevelExtension on AIDifficultyLevel {
  AIDifficulty _toOldDifficulty() {
    final result = level <= 3
        ? AIDifficulty.easy
        : (level <= 6 ? AIDifficulty.medium : AIDifficulty.hard);
    print(
        'AIDifficultyLevelExtension: ${displayName}(级别$level) -> ${result.name}');
    return result;
  }
}
