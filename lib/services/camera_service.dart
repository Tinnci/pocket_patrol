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
  bool get isBusy => (_controller?.value.isRecordingVideo ?? false) || _isStreamingImages;

  CameraController? get controller => _controller;
  List<CameraDescription>? get cameras => _cameras;
  String? get recordingPath => _recordingPath;
  CameraDescription? _selectedCameraDescription;
  CameraDescription? get selectedCameraDescription => _selectedCameraDescription;

  // 新增：存储当前实际使用的 preset，并提供更新方法
  ResolutionPreset _currentGlobalPreset = ResolutionPreset.high;
  void updateGlobalResolutionPreset(ResolutionPreset preset) {
    _currentGlobalPreset = preset;
    print('CameraService: Global resolution preset updated to $preset');
  }

  /// 初始化摄像头
  Future<void> initialize({CameraDescription? cameraDescription}) async {
    // 先释放旧的控制器
    await _controller?.dispose();
    _controller = null;

    _cameras ??= await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('未检测到摄像头设备');
    }

    _selectedCameraDescription = cameraDescription ?? _cameras![0];

    _controller = CameraController(
      _selectedCameraDescription!,
      _currentGlobalPreset,
    );
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

  // 新增：设置摄像头分辨率
  Future<void> setResolution(ResolutionPreset preset) async {
    // TODO: 实现根据 preset 切换分辨率的逻辑
    // 这可能需要 dispose 当前 controller 并用新的 preset 重新 initialize
    // 需要考虑是否正在推流或录像，可能需要先停止
    print('CameraService: Setting resolution to $preset');
    // 示例：如果 controller 已初始化，可以尝试设置新的 ImageFormatGroup，
    // 但更安全的做法是重新初始化
    // if (_controller != null) {
    //   await _controller!.stopImageStream(); // Stop stream if active
    //   await _controller!.dispose(); // Dispose old controller
    //   _controller = CameraController(_cameras![0], preset); // Create new controller
    //   await _controller!.initialize(); // Initialize with new preset
    //   // Restart stream if it was active before
    // }
  }

  // 新增：控制夜视模式
  Future<void> setNightVision(bool enabled) async {
    // TODO: 调用平台原生代码或摄像头 API 启用/禁用夜视
    print('CameraService: Setting night vision to $enabled');
    // Example: if (_controller != null) { _controller!.setFlashMode(enabled ? FlashMode.torch : FlashMode.off); }
  }

  /// 新增切换摄像头的方法
  Future<void> switchCamera(CameraDescription newCameraDescription) async {
    if (_controller != null && _controller!.value.isRecordingVideo) {
      await stopRecording();
    }
    if (_controller != null && _controller!.value.isStreamingImages) {
      stopImageStream();
    }
    await initialize(cameraDescription: newCameraDescription);
  }

  // 其他摄像头操作...
}