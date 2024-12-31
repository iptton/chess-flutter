import 'package:equatable/equatable.dart';
import '../screens/game_screen.dart';
import 'chess_models.dart';

class GameHistory extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<ChessMove> moves;
  final PieceColor? winner;
  final GameMode gameMode;
  final bool isCompleted;

  const GameHistory({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.moves,
    this.winner,
    required this.gameMode,
    required this.isCompleted,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'moves': moves.map((move) => move.toJson()).toList(),
      'winner': winner?.toString(),
      'gameMode': gameMode.toString(),
      'isCompleted': isCompleted,
    };
  }

  factory GameHistory.fromJson(Map<String, dynamic> json) {
    return GameHistory(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      moves: (json['moves'] as List).map((move) => ChessMove.fromJson(move)).toList(),
      winner: json['winner'] == null ? null : PieceColor.values.firstWhere(
        (e) => e.toString() == json['winner'],
      ),
      gameMode: GameMode.values.firstWhere(
        (e) => e.toString() == json['gameMode'],
      ),
      isCompleted: json['isCompleted'],
    );
  }

  @override
  List<Object?> get props => [id, startTime, endTime, moves, winner, gameMode, isCompleted];
}