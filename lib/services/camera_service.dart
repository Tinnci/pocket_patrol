import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 封装摄像头相关底层操作
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isStreamingImages = false;
  void Function(CameraImage)? _onFrame;
  String? _recordingPath;
  String? get recordingPath => _recordingPath;
  bool get isBusy => (_controller?.value.isRecordingVideo ?? false) || _isStreamingImages;

  CameraController? get controller => _controller;
  List<CameraDescription>? get cameras => _cameras;

  /// 初始化摄像头
  Future<void> initialize({ResolutionPreset preset = ResolutionPreset.high}) async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('未检测到摄像头设备');
    }
    _controller = CameraController(_cameras![0], preset);
    await _controller!.initialize();
  }

  /// 释放摄像头资源
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  /// 启动图像流，注册帧回调（与录像互斥）
  void startImageStream(void Function(CameraImage) onFrame) {
    if (_controller == null || _isStreamingImages) return;
    _onFrame = onFrame;
    _controller!.startImageStream((CameraImage image) {
      if (_onFrame != null) {
        _onFrame!(image);
      }
    });
    _isStreamingImages = true;
  }

  /// 停止图像流
  void stopImageStream() {
    if (_controller == null || !_isStreamingImages) return;
    _controller!.stopImageStream();
    _isStreamingImages = false;
    _onFrame = null;
  }

  /// 开始录像，返回文件路径（与图像流互斥）
  Future<String> startRecording() async {
    if (_controller == null || _controller!.value.isRecordingVideo) {
      throw Exception('摄像头未初始化或正在录像');
    }
    // 若正在推流，先停止图像流
    if (_isStreamingImages) {
      stopImageStream();
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDocDir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${recordingsDir.path}/rec_$ts.mp4';
    await _controller!.startVideoRecording();
    _recordingPath = path;
    return path;
  }

  /// 停止录像，返回录制完成的文件
  Future<XFile> stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      throw Exception('未在录像');
    }
    final file = await _controller!.stopVideoRecording();
    if (_recordingPath != null) {
      try {
        final newFile = await File(file.path).copy(_recordingPath!);
        print('录像文件已移动到: ${_recordingPath!}');
        return XFile(newFile.path);
      } catch (e) {
        print('移动录像文件失败: $e');
        return file;
      }
    } else {
      return file;
    }
  }

  // 其他摄像头操作...
} 