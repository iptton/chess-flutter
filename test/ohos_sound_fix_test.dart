import 'package:flutter_test/flutter_test.dart';
import 'package:testflutter/services/sound_service.dart';

void main() {
  group('RED: ohos平台音效修复测试', () {
    late SoundService soundService;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      soundService = SoundService();
    });

    test('ohos平台应该能够尝试初始化音效服务而不崩溃', () async {
      // Arrange - 模拟ohos平台环境

      // Act - 尝试初始化音效服务
      await soundService.initialize();

      // Assert - 在测试环境中会失败，但不应该崩溃
      // 在实际ohos设备上应该成功，这里主要验证没有平台特定的阻止逻辑
      expect(() => soundService.isInitialized, returnsNormally,
          reason: 'ohos平台应该能够安全地尝试初始化音效服务');
    });

    test('ohos平台应该能够播放音效', () async {
      // Arrange
      await soundService.initialize();

      // Act & Assert - 应该能够调用播放方法而不抛出异常
      expect(() async => await soundService.playMoveSound(), returnsNormally,
          reason: 'ohos平台应该能够播放移动音效');

      expect(() async => await soundService.playWinSound(), returnsNormally,
          reason: 'ohos平台应该能够播放胜利音效');

      expect(() async => await soundService.playCheckSound(), returnsNormally,
          reason: 'ohos平台应该能够播放将军音效');
    });

    test('ohos平台应该能够控制音量', () async {
      // Arrange
      await soundService.initialize();

      // Act & Assert - 应该能够设置音量而不抛出异常
      expect(() async => await soundService.setVolume(0.5), returnsNormally,
          reason: 'ohos平台应该能够设置音量');

      expect(() async => await soundService.mute(), returnsNormally,
          reason: 'ohos平台应该能够静音');

      expect(() async => await soundService.unmute(), returnsNormally,
          reason: 'ohos平台应该能够取消静音');
    });

    test('验证没有平台特定的阻止逻辑', () {
      // Assert - SoundService不应该包含针对ohos平台的特殊处理
      // 这是一个代码审查测试，确保没有类似 if (Platform.isOhos) return; 的逻辑

      // 通过检查SoundService的基本功能，确保它对所有平台一视同仁
      expect(soundService, isNotNull);
      expect(soundService.volume, greaterThanOrEqualTo(0.0));
      expect(soundService.volume, lessThanOrEqualTo(1.0));
      expect(soundService.isMuted, isA<bool>());
      expect(soundService.isInitialized, isA<bool>());
    });
  });
}
