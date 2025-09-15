import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _defaultHintModeKey = 'default_hint_mode';
  static const String _soundEnabledKey = 'sound_enabled';

  static Future<bool> getDefaultHintMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_defaultHintModeKey) ?? false;
  }

  static Future<void> setDefaultHintMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_defaultHintModeKey, value);
  }

  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? false; // 默认关闭
  }

  static Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, value);
  }
}
