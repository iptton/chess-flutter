import 'package:flutter/material.dart';
import '../widgets/chess_board.dart';
import '../models/chess_models.dart';

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
            _buildGameButton(
              context,
              '单机对战',
              Icons.person,
              () => _startGame(context, GameMode.offline),
            ),
            const SizedBox(height: 16),
            _buildGameButton(
              context,
              '联网对战',
              Icons.cloud,
              () => _startGame(context, GameMode.online),
            ),
            const SizedBox(height: 16),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChessBoard(gameMode: mode),
      ),
    );
  }
} 