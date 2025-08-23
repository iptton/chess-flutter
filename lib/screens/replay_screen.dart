import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_history.dart';
import '../services/game_history_service.dart';
import '../models/chess_models.dart';
import '../widgets/chess_board.dart';
import 'game_screen.dart';

class ReplayScreen extends StatefulWidget {
  const ReplayScreen({super.key});

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  List<GameHistory> _gameHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGameHistory();
  }

  Future<void> _loadGameHistory() async {
    setState(() {
      _isLoading = true;
    });

    final history = await GameHistoryService.getGameHistory();

    setState(() {
      _gameHistory = history;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('对局复盘'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGameHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _gameHistory.isEmpty
              ? const Center(child: Text('暂无历史对局'))
              : RefreshIndicator(
                  onRefresh: _loadGameHistory,
                  child: ListView.builder(
                    itemCount: _gameHistory.length,
                    itemBuilder: (context, index) {
                      final game = _gameHistory[index];
                      return _buildGameHistoryItem(game);
                    },
                  ),
                ),
    );
  }

  Widget _buildGameHistoryItem(GameHistory game) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    String getGameResult() {
      if (!game.isCompleted) return '未完成';
      if (game.winner == null) return '和棋';
      return '${game.winner == PieceColor.white ? "白方" : "黑方"}胜';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Text(dateFormat.format(game.startTime)),
            const Spacer(),
            Text(
              getGameResult(),
              style: TextStyle(
                color: game.winner == null
                    ? Colors.blue
                    : game.isCompleted
                        ? Colors.green
                        : Colors.orange,
              ),
            ),
          ],
        ),
        subtitle: Text(
          '回合数: ${game.moves.length} • ${game.gameMode == GameMode.faceToFace ? "面对面对战" : "单机对战"}',
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChessBoard(
                gameMode: game.gameMode,
                replayGame: game,
              ),
            ),
          );
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('删除对局记录'),
              content: const Text('确定要删除这条对局记录吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    await GameHistoryService.deleteGame(game.id);
                    Navigator.pop(context);
                    _loadGameHistory(); // 重新加载列表
                  },
                  child: const Text(
                    '删除',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
