import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/utils/chess_formatters.dart';
import 'package:testflutter/screens/game_screen.dart';

void main() {
  group('ChessFormatters', () {
    group('getGameModeTitle', () {
      test('应该为AI对战模式返回正确的标题', () {
        // Arrange
        const gameMode = GameMode.offline;
        
        // Act
        final title = ChessFormatters.getGameModeTitle(gameMode);
        
        // Assert
        expect(title, equals('AI 对战'));
      });
      
      test('应该为联网对战模式返回正确的标题', () {
        // Arrange
        const gameMode = GameMode.online;
        
        // Act
        final title = ChessFormatters.getGameModeTitle(gameMode);
        
        // Assert
        expect(title, equals('联网对战'));
      });
      
      test('应该为面对面对战模式返回正确的标题', () {
        // Arrange
        const gameMode = GameMode.faceToFace;
        
        // Act
        final title = ChessFormatters.getGameModeTitle(gameMode);
        
        // Assert
        expect(title, equals('面对面对战'));
      });
    });
  });
}
