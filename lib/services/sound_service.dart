import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'settings_service.dart';

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

  /// 检查当前平台是否支持音效
  bool _isPlatformSupported() {
    if (kIsWeb) return true;

    try {
      final platform = Platform.operatingSystem;
      // ohos平台目前不支持audioplayers插件
      if (platform == 'ohos') {
        if (kDebugMode) {
          print('SoundService: 检测到ohos平台，audioplayers插件暂不支持');
        }
        return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SoundService: 平台检测失败: $e');
      }
      return false;
    }
  }

  /// 初始化音效服务
  Future<void> initialize() async {
    try {
      // 检测平台信息
      String platformInfo = 'Unknown';
      if (!kIsWeb) {
        try {
          platformInfo = Platform.operatingSystem;
        } catch (e) {
          platformInfo = 'Platform detection failed: $e';
        }
      } else {
        platformInfo = 'Web';
      }

      if (kDebugMode) {
        print('SoundService: 开始初始化音效服务，平台: $platformInfo');
      }

      // 检查平台支持
      if (!_isPlatformSupported()) {
        _isInitialized = false;
        if (kDebugMode) {
          print('SoundService: 当前平台($platformInfo)不支持音效功能');
        }
        return;
      }

      _audioPlayer = AudioPlayer();

      // 尝试设置音量来测试插件是否正常工作
      await _audioPlayer.setVolume(_volume);
      _isInitialized = true;

      if (kDebugMode) {
        print('SoundService: 音效服务已初始化成功，平台: $platformInfo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SoundService: 初始化失败 - $e');
        print('SoundService: 错误详情: ${e.toString()}');
      }
      _isInitialized = false;

      // 如果是插件未找到的错误，我们不再尝试创建AudioPlayer
      // 直接标记为未初始化，这样其他方法可以安全地处理
      if (e.toString().contains('MissingPluginException')) {
        if (kDebugMode) {
          print('SoundService: 插件未找到，音效功能将被禁用');
        }
      }
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
      if (kDebugMode) {
        print('SoundService: 音量设置为 ${_isMuted ? 0.0 : _volume}');
      }
    }
  }

  /// 静音
  Future<void> mute() async {
    _isMuted = true;
    if (_isInitialized) {
      await _audioPlayer.setVolume(0.0);
      if (kDebugMode) {
        print('SoundService: 已静音');
      }
    }
  }

  /// 取消静音
  Future<void> unmute() async {
    _isMuted = false;
    if (_isInitialized) {
      await _audioPlayer.setVolume(_volume);
      if (kDebugMode) {
        print('SoundService: 已取消静音，音量: $_volume');
      }
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
    try {
      if (_isInitialized) {
        await _audioPlayer.dispose();
        _isInitialized = false;
        if (kDebugMode) {
          print('SoundService: 资源已释放');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('SoundService: 释放资源失败 - $e');
      }
      _isInitialized = false; // 无论如何都标记为未初始化
    }
  }

  /// 播放指定音效文件
  Future<void> _playSound(String assetPath) async {
    if (kDebugMode) {
      print('SoundService: 尝试播放音效 - $assetPath');
      print('SoundService: 状态检查 - 已初始化: $_isInitialized, 已静音: $_isMuted');
    }

    // 如果服务未初始化、已静音，或者AudioPlayer实例不存在，直接返回
    if (!_isInitialized || _isMuted) {
      if (kDebugMode) {
        print('SoundService: 跳过播放 - 服务未初始化或已静音');
      }
      return;
    }

    try {
      // 检查用户设置是否启用音效
      final soundEnabled = await SettingsService.getSoundEnabled();
      if (kDebugMode) {
        print('SoundService: 用户音效设置: $soundEnabled');
      }

      if (!soundEnabled) {
        if (kDebugMode) {
          print('SoundService: 跳过播放 - 用户已禁用音效');
        }
        return;
      }

      // 尝试播放音效
      final assetSource = AssetSource(assetPath.replaceFirst('assets/', ''));
      if (kDebugMode) {
        print('SoundService: 开始播放音效文件: ${assetSource.path}');
      }

      await _audioPlayer.play(assetSource);

      if (kDebugMode) {
        print('SoundService: 音效播放成功 - $assetPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SoundService: 播放音效失败 - $assetPath: $e');
        print('SoundService: 错误类型: ${e.runtimeType}');
      }

      // 如果是插件错误，标记服务为未初始化以避免后续尝试
      if (e.toString().contains('MissingPluginException')) {
        _isInitialized = false;
        if (kDebugMode) {
          print('SoundService: 检测到插件错误，禁用音效功能');
        }
      }
    }
  }
}
