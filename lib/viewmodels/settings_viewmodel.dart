import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/camera_service.dart';
import 'package:camera/camera.dart';

/// 负责主题切换、设置项、Token 管理等业务逻辑
class SettingsViewModel extends ChangeNotifier {
  final SettingsService settingsService;
  final CameraService cameraService;

  ThemeMode themeMode = ThemeMode.system;
  bool useLightMode = true;

  // 新增：可用分辨率选项列表
  final List<String> availableResolutions = const ['720p', '1080p', '4K']; // 硬编码的选项列表

  // 新增：分辨率
  String _resolution = '720p'; // 默认值应是 availableResolutions 中的一个
  String get resolution => _resolution;
  Future<void> setResolution(String v) async {
    if (_resolution == v) return; // Avoid unnecessary updates
    _resolution = v;
    notifyListeners();
    await settingsService.saveResolution(v); // Save to persistence
    // TODO: 可持久化到 settingsService
    // TODO: 通知 CameraService 应用新的分辨率
    ResolutionPreset preset;
    switch (v) {
      case '720p':
        preset = ResolutionPreset.medium;
        break;
      case '1080p':
        preset = ResolutionPreset.high;
        break;
      case '4K':
        preset = ResolutionPreset.max;
        break;
      default:
        preset = ResolutionPreset.medium; // Default
    }
    // 调用 CameraService 的方法更新全局期望分辨率
    cameraService.updateGlobalResolutionPreset(preset);
    // 注意：这里只是更新了 CameraService 内部记录的期望preset，
    // 实际重新初始化摄像头应用新分辨率的逻辑将在 LiveViewViewModel 中处理，
    // 当 LiveViewViewModel 监听到 SettingsViewModel 的变化时触发。
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
  Future<void> setMotionSensitivity(double v) async {
    if (_motionSensitivity == v) return; // Avoid unnecessary updates
    _motionSensitivity = v;
    notifyListeners();
    await settingsService.saveMotionSensitivity(v); // Save to persistence
    // TODO: 预留：通知运动检测服务应用新的灵敏度
    // if (motionDetectionService != null) motionDetectionService.setSensitivity(v);
  }

  // 新增：夜视模式
  bool _isNightVisionEnabled = false;
  bool get isNightVisionEnabled => _isNightVisionEnabled;
  Future<void> setNightVisionEnabled(bool value) async {
    if (_isNightVisionEnabled == value) return; // Avoid unnecessary updates
    _isNightVisionEnabled = value;
    notifyListeners();
    await settingsService.saveNightVisionEnabled(value); // Save to persistence
    // TODO: 预留：通知摄像头服务启用/禁用夜视
    await cameraService.setNightVision(value);
  }

  // 新增：移动侦测提醒
  bool _isMotionDetectionRemindEnabled = true;
  bool get isMotionDetectionRemindEnabled => _isMotionDetectionRemindEnabled;
  Future<void> setMotionDetectionRemindEnabled(bool value) async {
    if (_isMotionDetectionRemindEnabled == value) return; // Avoid unnecessary updates
    _isMotionDetectionRemindEnabled = value;
    notifyListeners();
    await settingsService.saveMotionDetectionRemindEnabled(value); // Save to persistence
    // TODO: 预留：通知运动检测服务是否发送提醒
    // if (motionDetectionService != null) motionDetectionService.setRemindEnabled(value);
  }

  // 新增：声音提醒
  bool _isSoundRemindEnabled = false;
  bool get isSoundRemindEnabled => _isSoundRemindEnabled;
  Future<void> setSoundRemindEnabled(bool value) async {
    if (_isSoundRemindEnabled == value) return; // Avoid unnecessary updates
    _isSoundRemindEnabled = value;
    notifyListeners();
    await settingsService.saveSoundRemindEnabled(value); // Save to persistence
    // TODO: 预留：通知声音检测服务是否发送提醒
    // if (soundDetectionService != null) soundDetectionService.setRemindEnabled(value);
  }

  SettingsViewModel({required this.settingsService, required this.cameraService});

  // 加载所有设置项
  Future<void> loadSettings() async {
     await loadThemeMode();
     // 加载其他设置项，使用 ?? 提供默认值
     // 加载的分辨率如果不在 availableResolutions 中，可以使用默认值
     _resolution = await settingsService.loadResolution() ?? availableResolutions.first; // 使用列表的第一个作为默认值
     if (!availableResolutions.contains(_resolution)) {
        _resolution = availableResolutions.first; // 如果加载的值无效，使用默认值
     }
     _motionSensitivity = await settingsService.loadMotionSensitivity() ?? 1.0;
     _isNightVisionEnabled = await settingsService.loadNightVisionEnabled() ?? false;
     _isMotionDetectionRemindEnabled = await settingsService.loadMotionDetectionRemindEnabled() ?? true;
     _isSoundRemindEnabled = await settingsService.loadSoundRemindEnabled() ?? false;

     // Initial application of loaded settings to services
     ResolutionPreset preset;
     switch (_resolution) {
       case '720p':
         preset = ResolutionPreset.medium;
         break;
       case '1080p':
         preset = ResolutionPreset.high;
         break;
       case '4K':
         preset = ResolutionPreset.max;
         break;
       default:
         preset = ResolutionPreset.medium;
     }
     // 在加载设置后，通知 CameraService 应用加载的分辨率
     cameraService.updateGlobalResolutionPreset(preset);
     await cameraService.setNightVision(_isNightVisionEnabled);
     // TODO: 预留：应用运动检测灵敏度、提醒等到相关服务
     // if (motionDetectionService != null) motionDetectionService.setSensitivity(_motionSensitivity);
     // if (motionDetectionService != null) motionDetectionService.setRemindEnabled(_isMotionDetectionRemindEnabled);
     // if (soundDetectionService != null) soundDetectionService.setRemindEnabled(_isSoundRemindEnabled);
     notifyListeners(); // 加载完成后通知一次
  }

  Future<void> loadThemeMode() async {
    final saved = await settingsService.loadThemeMode();
    if (saved != null) {
      useLightMode = saved;
      themeMode = saved ? ThemeMode.light : ThemeMode.dark;
      // 这里不需要 notifyListeners()，因为 loadSettings 最后会通知
    }
  }

  Future<void> toggleTheme(bool useLight) async {
    if (useLightMode == useLight) return; // Avoid unnecessary updates
    useLightMode = useLight;
    themeMode = useLight ? ThemeMode.light : ThemeMode.dark;
    await settingsService.saveThemeMode(useLight);
    notifyListeners();
  }

  // 其他设置项、Token 管理方法...
} 