import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class RecordingItem {
  final String title;
  final String time;
  final String thumb;
  final String path;

  RecordingItem({required this.title, required this.time, required this.thumb, required this.path});
}

/// 封装录像相关底层操作
class RecordingService {
  // 获取本地录像目录
  Future<Directory> getRecordingsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    return recordingsDir;
  }

  // 扫描本地录像文件
  Future<List<RecordingItem>> getRecordings() async {
    final dir = await getRecordingsDirectory();
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.mp4')).toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    return files.map((file) {
      final stat = file.statSync();
      return RecordingItem(
        title: file.uri.pathSegments.last,
        time: dateFormat.format(stat.modified),
        thumb: '', // 可后续生成缩略图
        path: file.path,
      );
    }).toList();
  }

  // 删除指定录像
  Future<void> deleteRecording(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // 预留：保存录像、生成缩略图等
} 