import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_history.dart';
import '../services/game_history_service.dart';
import '../models/chess_models.dart';
import '../widgets/chess_board.dart';
import '../widgets/themed_background.dart';
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
      appBar: ThemedAppBar(
        title: '对局复盘',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGameHistory,
          ),
        ],
      ),
      body: ThemedBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _gameHistory.isEmpty
                ? const Center(
                    child: ThemedCard(
                      child: Text(
                        '暂无历史对局',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGameHistory,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _gameHistory.length,
                      itemBuilder: (context, index) {
                        final game = _gameHistory[index];
                        return _buildGameHistoryItem(game);
                      },
                    ),
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

    return ThemedCard(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: ListTile(
        title: Row(
          children: [
            Text(
              dateFormat.format(game.startTime),
              style: const TextStyle(
                color: AppTheme.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: game.winner == null
                    ? AppTheme.primaryColor
                    : game.isCompleted
                        ? Colors.green
                        : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                getGameResult(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '回合数: ${game.moves.length} • ${game.gameMode == GameMode.faceToFace ? "面对面对战" : "单机对战"}',
          style: const TextStyle(
            color: AppTheme.secondaryTextColor,
          ),
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
