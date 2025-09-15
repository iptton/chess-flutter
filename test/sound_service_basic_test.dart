import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/services/sound_service.dart';

void main() {
  group('Sound Service Basic Tests', () {
    test('RED: SoundService should be a singleton', () {
      final service1 = SoundService();
      final service2 = SoundService();
      expect(service1, same(service2));
    });

    test('RED: SoundService should have initial state', () {
      final service = SoundService();
      expect(service.isInitialized, isFalse);
      expect(service.isMuted, isFalse);
      expect(service.volume, equals(1.0));
    });

    test('RED: SoundService should handle volume validation', () {
      final service = SoundService();
      
      // Test invalid volume values
      expect(() => service.setVolume(-0.1), throwsArgumentError);
      expect(() => service.setVolume(1.1), throwsArgumentError);
    });

    test('RED: SoundService should handle mute/unmute without initialization', () async {
      final service = SoundService();
      
      // Should not throw exceptions even when not initialized
      await service.mute();
      expect(service.isMuted, isTrue);
      
      await service.unmute();
      expect(service.isMuted, isFalse);
      
      await service.toggleMute();
      expect(service.isMuted, isTrue);
      
      await service.toggleMute();
      expect(service.isMuted, isFalse);
    });

    test('RED: SoundService should handle dispose without initialization', () async {
      final service = SoundService();
      
      // Should not throw exception
      await service.dispose();
      expect(service.isInitialized, isFalse);
    });

    test('RED: SoundService should handle sound playing without initialization', () async {
      final service = SoundService();
      
      // Should not throw exceptions even when not initialized
      await service.playMoveSound();
      await service.playWinSound();
      await service.playLoseSound();
      await service.playCheckSound();
      await service.playPromotionSound();
    });
  });
}
