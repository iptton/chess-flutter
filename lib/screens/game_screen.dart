import 'package:flutter/material.dart';

import '../widgets/chess_board.dart';
import '../services/chess_ai.dart';
import '../models/chess_models.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum GameMode {
  offline,   // 单机对战（人机）
  online,    // 联网对战
  faceToFace, // 面对面对战
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('对战'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGameButton(
              context,
              '单机对战（AI）',
              Icons.person,
              () => _startGame(context, GameMode.offline),
            ),
            const SizedBox(height: 16),
            // _buildGameButton(
            //   context,
            //   '联网对战（开发中）',
            //   Icons.cloud,
            //   () => _startGame(context, GameMode.online),
            // ),
            // const SizedBox(height: 16),
            _buildGameButton(
              context,
              '面对面对战',
              Icons.people,
              () => _startGame(context, GameMode.faceToFace),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
          fontSize: 16.0
          );
    }
  }

  void _showAISettingsDialog(BuildContext context) {
    AIDifficulty selectedDifficulty = AIDifficulty.medium;
    PieceColor playerColor = PieceColor.white;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('单机对战设置'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择AI难度:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...AIDifficulty.values.map((difficulty) {
                    return RadioListTile<AIDifficulty>(
                      title: Text(_getDifficultyName(difficulty)),
                      subtitle: Text(_getDifficultyDescription(difficulty)),
                      value: difficulty,
                      groupValue: selectedDifficulty,
                      onChanged: (value) {
                        setState(() {
                          selectedDifficulty = value!;
                        });
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  const Text('选择你的颜色:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<PieceColor>(
                          title: const Text('白方'),
                          subtitle: const Text('先手'),
                          value: PieceColor.white,
                          groupValue: playerColor,
                          onChanged: (value) {
                            setState(() {
                              playerColor = value!;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<PieceColor>(
                          title: const Text('黑方'),
                          subtitle: const Text('后手'),
                          value: PieceColor.black,
                          groupValue: playerColor,
                          onChanged: (value) {
                            setState(() {
                              playerColor = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startAIGame(context, selectedDifficulty, playerColor);
                  },
                  child: const Text('开始游戏'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getDifficultyName(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return '简单';
      case AIDifficulty.medium:
        return '中等';
      case AIDifficulty.hard:
        return '困难';
    }
  }

  String _getDifficultyDescription(AIDifficulty difficulty) {
    switch (difficulty) {
      case AIDifficulty.easy:
        return '适合初学者';
      case AIDifficulty.medium:
        return '适合有一定基础的玩家';
      case AIDifficulty.hard:
        return '适合高手挑战';
    }
  }

  void _startAIGame(BuildContext context, AIDifficulty difficulty, PieceColor playerColor) {
    final aiColor = playerColor == PieceColor.white ? PieceColor.black : PieceColor.white;

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
}
