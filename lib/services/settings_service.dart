import 'package:shared_preferences/shared_preferences.dart';

/// 封装设置项持久化、Token 生成等底层操作
class SettingsService {
  static const _themeKey = 'theme_mode';
  // 新增 keys for other settings
  static const _resolutionKey = 'setting_resolution';
  static const _motionSensitivityKey = 'setting_motion_sensitivity';
  static const _nightVisionKey = 'setting_night_vision';
  static const _motionDetectionRemindKey = 'setting_motion_detection_remind';
  static const _soundRemindKey = 'setting_sound_remind';


  Future<void> saveThemeMode(bool useLight) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, useLight);
  }

  Future<bool?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey);
  }

  // 新增：保存分辨率
  Future<void> saveResolution(String resolution) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resolutionKey, resolution);
  }

  // 新增：加载分辨率
  Future<String?> loadResolution() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_resolutionKey);
  }

  // 新增：保存运动检测灵敏度
  Future<void> saveMotionSensitivity(double sensitivity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_motionSensitivityKey, sensitivity);
  }

  // 新增：加载运动检测灵敏度
  Future<double?> loadMotionSensitivity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_motionSensitivityKey);
  }

  // 新增：保存夜视模式
  Future<void> saveNightVisionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_nightVisionKey, enabled);
  }

  // 新增：加载夜视模式
  Future<bool?> loadNightVisionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_nightVisionKey);
  }

  // 新增：保存移动侦测提醒设置
  Future<void> saveMotionDetectionRemindEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_motionDetectionRemindKey, enabled);
  }

  // 新增：加载移动侦测提醒设置
  Future<bool?> loadMotionDetectionRemindEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_motionDetectionRemindKey);
  }

  // 新增：保存声音提醒设置
  Future<void> saveSoundRemindEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundRemindKey, enabled);
  }

  // 新增：加载声音提醒设置
  Future<bool?> loadSoundRemindEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundRemindKey);
  }


  Future<String> generateToken() async {
    // TODO: 生成安全 Token
    return '';
  }

  // 其他设置项操作...
} 