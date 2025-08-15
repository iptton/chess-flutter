import 'package:flutter/material.dart';

import '../widgets/chess_board.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum GameMode {
  offline,
  online,
  faceToFace,
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
            // _buildGameButton(
            //   context,
            //   '单机对战（开发中）',
            //   Icons.person,
            //   () => _startGame(context, GameMode.offline),
            // ),
            // const SizedBox(height: 16),
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
    // 当前仅支持面对面对战，其他模式先显示 Toast 提示
    if (mode != GameMode.faceToFace) {
      Fluttertoast.showToast(
          msg: "开发中，敬请期待",
          // 显示的文本
          toastLength: Toast.LENGTH_SHORT,
          // Toast显示的时长
          gravity: ToastGravity.CENTER,
          // Toast显示的位置
          timeInSecForIosWeb: 1,
          // iOS和Web平台上显示的时长
          backgroundColor: Colors.black87,
          // 背景色
          textColor: Colors.white,
          // 文字颜色
          fontSize: 16.0 // 文字大小
          );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChessBoard(gameMode: mode),
        ),
      );
    }
  }
}
