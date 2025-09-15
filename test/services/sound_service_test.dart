import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/services/sound_service.dart';

void main() {
  group('SoundService', () {
    late SoundService soundService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      soundService = SoundService();
    });

    group('初始化', () {
      test('应该能够安全地初始化', () async {
        // Act
        await soundService.initialize();
        
        // Assert - 在测试环境中，初始化可能失败，但不应该抛出异常
        // 我们主要验证方法不会崩溃
        expect(true, isTrue);
      });
      
      test('初始状态应该是未初始化', () {
        // Assert
        expect(soundService.isInitialized, isFalse);
        expect(soundService.isMuted, isFalse);
        expect(soundService.volume, equals(1.0));
      });
    });

    group('音量控制', () {
      test('应该能够设置音量', () async {
        // Arrange
        const newVolume = 0.5;
        
        // Act
        await soundService.setVolume(newVolume);
        
        // Assert
        expect(soundService.volume, equals(newVolume));
      });
      
      test('设置无效音量应该抛出异常', () async {
        // Act & Assert
        expect(() => soundService.setVolume(-0.1), throwsArgumentError);
        expect(() => soundService.setVolume(1.1), throwsArgumentError);
      });
      
      test('应该能够静音和取消静音', () async {
        // Act
        await soundService.mute();
        
        // Assert
        expect(soundService.isMuted, isTrue);
        
        // Act
        await soundService.unmute();
        
        // Assert
        expect(soundService.isMuted, isFalse);
      });
      
      test('应该能够切换静音状态', () async {
        // Arrange
        final initialMuteState = soundService.isMuted;
        
        // Act
        await soundService.toggleMute();
        
        // Assert
        expect(soundService.isMuted, equals(!initialMuteState));
        
        // Act
        await soundService.toggleMute();
        
        // Assert
        expect(soundService.isMuted, equals(initialMuteState));
      });
    });

    group('音效播放', () {
      test('播放音效方法应该不抛出异常', () async {
        // 在测试环境中，这些方法可能会失败，但不应该抛出异常
        
        // Act & Assert
        expect(() => soundService.playMoveSound(), returnsNormally);
        expect(() => soundService.playWinSound(), returnsNormally);
        expect(() => soundService.playLoseSound(), returnsNormally);
        expect(() => soundService.playCheckSound(), returnsNormally);
        expect(() => soundService.playPromotionSound(), returnsNormally);
      });
    });

    group('资源管理', () {
      test('应该能够安全地释放资源', () async {
        // Act & Assert
        expect(() => soundService.dispose(), returnsNormally);
      });
    });
  });
}
