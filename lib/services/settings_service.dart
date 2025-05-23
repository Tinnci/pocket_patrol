import 'package:shared_preferences/shared_preferences.dart';

/// 封装设置项持久化、Token 生成等底层操作
class SettingsService {
  static const _themeKey = 'theme_mode';

  Future<void> saveThemeMode(bool useLight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, useLight);
  }

  Future<bool?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey);
  }

  Future<String> generateToken() async {
    // TODO: 生成安全 Token
    return '';
  }

  // 其他设置项操作...
} 