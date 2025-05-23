import 'package:flutter/material.dart';
import '../services/recording_service.dart';

/// 负责录像列表、播放、删除等业务逻辑
class RecordingsViewModel extends ChangeNotifier {
  final RecordingService recordingService;

  List<RecordingItem> recordings = [];

  RecordingsViewModel({required this.recordingService});

  Future<void> loadRecordings() async {
    recordings = await recordingService.getRecordings();
    notifyListeners();
  }

  Future<void> deleteRecording(String path) async {
    await recordingService.deleteRecording(path);
    await loadRecordings();
  }

  // 其他业务方法...
} 