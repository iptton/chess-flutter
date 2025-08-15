import 'package:shared_preferences/shared_preferences.dart';

class PrivacyService {
  static const _acceptedKey = 'privacy_accepted';

  static Future<bool> isAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_acceptedKey) ?? false;
  }

  static Future<void> setAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_acceptedKey, accepted);
  }
}

