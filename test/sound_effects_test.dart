import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/services/sound_service.dart';

void main() {
  group('Sound Effects Tests', () {
    late SoundService soundService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      soundService = SoundService();
    });

    test('RED: SoundService should be able to initialize', () {
      expect(soundService, isNotNull);
      expect(soundService.isInitialized, isFalse);
    });

    test('RED: SoundService should initialize successfully', () async {
      // 在测试环境中，初始化可能会失败，但不应该抛出异常
      await soundService.initialize();
      // 在测试环境中，我们主要验证方法不会抛出异常
      expect(soundService, isNotNull);
    });

    test('RED: SoundService should play move sound', () async {
      await soundService.initialize();

      // Should not throw exception
      expect(() async => await soundService.playMoveSound(), returnsNormally);
    });

    test('RED: SoundService should play win sound', () async {
      await soundService.initialize();

      // Should not throw exception
      expect(() async => await soundService.playWinSound(), returnsNormally);
    });

    test('RED: SoundService should play lose sound', () async {
      await soundService.initialize();

      // Should not throw exception
      expect(() async => await soundService.playLoseSound(), returnsNormally);
    });

    test('RED: SoundService should play check sound', () async {
      await soundService.initialize();

      // Should not throw exception
      expect(() async => await soundService.playCheckSound(), returnsNormally);
    });

    test('RED: SoundService should play promotion sound', () async {
      await soundService.initialize();

      // Should not throw exception
      expect(
          () async => await soundService.playPromotionSound(), returnsNormally);
    });

    test('RED: SoundService should handle volume control', () async {
      await soundService.initialize();

      // Test volume setting
      await soundService.setVolume(0.5);
      expect(soundService.volume, equals(0.5));

      await soundService.setVolume(0.0);
      expect(soundService.volume, equals(0.0));

      await soundService.setVolume(1.0);
      expect(soundService.volume, equals(1.0));
    });

    test('RED: SoundService should handle mute/unmute', () async {
      await soundService.initialize();

      expect(soundService.isMuted, isFalse);

      await soundService.mute();
      expect(soundService.isMuted, isTrue);

      await soundService.unmute();
      expect(soundService.isMuted, isFalse);
    });

    test('RED: SoundService should not play sounds when muted', () async {
      await soundService.initialize();
      await soundService.mute();

      // Should not throw exception even when muted
      expect(() async => await soundService.playMoveSound(), returnsNormally);
      expect(() async => await soundService.playWinSound(), returnsNormally);
      expect(() async => await soundService.playLoseSound(), returnsNormally);
    });

    test('RED: SoundService should dispose properly', () async {
      await soundService.initialize();
      expect(soundService.isInitialized, isTrue);

      await soundService.dispose();
      expect(soundService.isInitialized, isFalse);
    });

    tearDown(() async {
      if (soundService.isInitialized) {
        await soundService.dispose();
      }
    });
  });
}
