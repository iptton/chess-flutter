import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/game_history.dart';
import '../models/chess_models.dart';

class GameHistoryService {
  static const String _historyKey = 'game_history';
  static const _uuid = Uuid();

  static Future<void> saveGame(GameHistory game) async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = await getGameHistory();
    
    historyList.insert(0, game); // 新的游戏放在最前面
    
    // 只保留最近的50场游戏
    if (historyList.length > 50) {
      historyList.removeRange(50, historyList.length);
    }
    
    final jsonList = historyList.map((game) => game.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  static Future<List<GameHistory>> getGameHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => GameHistory.fromJson(json)).toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static String generateGameId() {
    return _uuid.v4();
  }
} 