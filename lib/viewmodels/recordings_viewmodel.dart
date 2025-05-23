import 'package:flutter/material.dart';
import '../services/recording_service.dart';

/// 负责录像列表、播放、删除等业务逻辑
class RecordingsViewModel extends ChangeNotifier {
  final RecordingService recordingService;

  List<RecordingItem> recordings = [];
  bool isLoading = false;
  String? error;

  RecordingsViewModel({required this.recordingService});

  Future<void> loadRecordings() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      recordings = await recordingService.getRecordings();
    } catch (e) {
      error = '加载录像失败: $e';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRecording(String path) async {
    try {
      await recordingService.deleteRecording(path);
      await loadRecordings();
    } catch (e) {
      error = '删除录像失败: $e';
      notifyListeners();
    }
  }

  // 其他业务方法...
} 