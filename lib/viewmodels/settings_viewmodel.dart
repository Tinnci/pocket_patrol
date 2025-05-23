import 'package:flutter/material.dart';
import '../services/settings_service.dart';

/// 负责主题切换、设置项、Token 管理等业务逻辑
class SettingsViewModel extends ChangeNotifier {
  final SettingsService settingsService;

  ThemeMode themeMode = ThemeMode.system;
  bool useLightMode = true;

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