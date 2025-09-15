import 'package:audioplayers/audioplayers.dart';

/// 音效播放服务
/// 负责管理游戏中的所有音效播放
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  bool _isMuted = false;
  double _volume = 1.0;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 是否静音
  bool get isMuted => _isMuted;

  /// 当前音量 (0.0 - 1.0)
  double get volume => _volume;

  /// 初始化音效服务
  Future<void> initialize() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer.setVolume(_volume);
      _isInitialized = true;
    } catch (e) {
      print('SoundService: 初始化失败 - $e');
      _isInitialized = false;
    }
  }

  /// 播放移动音效
  Future<void> playMoveSound() async {
    await _playSound('assets/sounds/move.wav');
  }

  /// 播放胜利音效
  Future<void> playWinSound() async {
    await _playSound('assets/sounds/victory.wav');
  }

  /// 播放失败音效
  Future<void> playLoseSound() async {
    await _playSound('assets/sounds/defeat.wav');
  }

  /// 播放将军音效
  Future<void> playCheckSound() async {
    await _playSound('assets/sounds/check.wav');
  }

  /// 播放兵升变音效
  Future<void> playPromotionSound() async {
    await _playSound('assets/sounds/promotion.wav');
  }

  /// 设置音量
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError('音量必须在0.0到1.0之间');
    }
    
    _volume = volume;
    if (_isInitialized) {
      await _audioPlayer.setVolume(_isMuted ? 0.0 : _volume);
    }
  }

  /// 静音
  Future<void> mute() async {
    _isMuted = true;
    if (_isInitialized) {
      await _audioPlayer.setVolume(0.0);
    }
  }

  /// 取消静音
  Future<void> unmute() async {
    _isMuted = false;
    if (_isInitialized) {
      await _audioPlayer.setVolume(_volume);
    }
  }

  /// 切换静音状态
  Future<void> toggleMute() async {
    if (_isMuted) {
      await unmute();
    } else {
      await mute();
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_isInitialized) {
      await _audioPlayer.dispose();
      _isInitialized = false;
    }
  }

  /// 播放指定音效文件
  Future<void> _playSound(String assetPath) async {
    if (!_isInitialized || _isMuted) {
      return;
    }

    try {
      await _audioPlayer.play(AssetSource(assetPath.replaceFirst('assets/', '')));
    } catch (e) {
      print('SoundService: 播放音效失败 - $assetPath: $e');
    }
  }
}
