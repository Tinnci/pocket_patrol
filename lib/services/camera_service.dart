import 'package:camera/camera.dart';

/// 封装摄像头相关底层操作
class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

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

  // 其他摄像头操作...
} 