import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// 负责主题切换、设置项、Token 管理等业务逻辑
class SettingsViewModel extends ChangeNotifier {
  final SettingsService settingsService;

  ThemeMode themeMode = ThemeMode.system;
  bool useLightMode = true;

  // 新增：分辨率
  String _resolution = '720p';
  String get resolution => _resolution;
  void setResolution(String v) {
    _resolution = v;
    notifyListeners();
    // 可持久化到 settingsService
  }

  // 新增：运动检测灵敏度（0=低，1=中，2=高）
  double _motionSensitivity = 1;
  double get motionSensitivity => _motionSensitivity;
  String get motionSensitivityLabel {
    switch (_motionSensitivity.round()) {
      case 0:
        return '低';
      case 2:
        return '高';
      default:
        return '中';
    }
  }
  void setMotionSensitivity(double v) {
    _motionSensitivity = v;
    notifyListeners();
    // 可持久化到 settingsService
  }

  SettingsViewModel({required this.settingsService});

  Future<void> loadThemeMode() async {
    final saved = await settingsService.loadThemeMode();
    if (saved != null) {
      useLightMode = saved;
      themeMode = saved ? ThemeMode.light : ThemeMode.dark;
      notifyListeners();
    }
  }

  Future<void> toggleTheme(bool useLight) async {
    useLightMode = useLight;
    themeMode = useLight ? ThemeMode.light : ThemeMode.dark;
    await settingsService.saveThemeMode(useLight);
    notifyListeners();
  }

  // 其他设置项、Token 管理方法...
} 