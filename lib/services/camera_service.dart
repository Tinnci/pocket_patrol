import 'package:camera/camera.dart';

/// 封装摄像头相关底层操作
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isStreamingImages = false;
  void Function(CameraImage)? _onFrame;
  String? _recordingPath;

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

  /// 启动图像流，注册帧回调
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

  /// 开始录像，返回文件路径
  Future<String> startRecording() async {
    if (_controller == null || _controller!.value.isRecordingVideo) {
      throw Exception('摄像头未初始化或正在录像');
    }
    final dir = '/storage/emulated/0/Movies/PocketPatrol';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '$dir/rec_$ts.mp4';
    await _controller!.startVideoRecording();
    _recordingPath = path;
    return path;
  }

  /// 停止录像
  Future<void> stopRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) {
      throw Exception('未在录像');
    }
    final file = await _controller!.stopVideoRecording();
    _recordingPath = null;
    // 可将 file.path 移动/重命名到 _recordingPath
  }

  // 其他摄像头操作...
} 