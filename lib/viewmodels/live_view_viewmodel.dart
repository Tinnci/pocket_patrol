import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/streaming_service.dart';
import '../services/image_conversion_service.dart';

/// 负责摄像头预览、初始化、错误处理、推流等业务逻辑
class LiveViewViewModel extends ChangeNotifier {
  final CameraService cameraService;
  late final StreamingService streamingService;
  bool isCameraInitialized = false;
  String? error;
  bool isStreaming = false;
  int? streamingPort;
  String? streamUrl;

  LiveViewViewModel({required this.cameraService}) {
    streamingService = StreamingService(
      cameraService: cameraService,
      imageConversionService: ImageConversionService(),
    );
  }

  CameraController? get controller => cameraService.controller;

  Future<void> initializeCamera() async {
    try {
      await cameraService.initialize();
      isCameraInitialized = true;
      error = null;
    } catch (e) {
      error = '摄像头初始化失败: $e';
      isCameraInitialized = false;
    }
    notifyListeners();
  }

  Future<void> disposeCamera() async {
    await cameraService.dispose();
    isCameraInitialized = false;
    notifyListeners();
  }

  /// 启动 MJPEG 推流
  Future<void> startStreaming({int port = 8080, String? authToken}) async {
    try {
      await streamingService.startStreamingServer(port, authToken: authToken);
      isStreaming = true;
      streamingPort = port;
      streamUrl = 'http://<本机IP或Tailscale IP>:$port/stream.mjpeg';
      error = null;
    } catch (e) {
      error = '推流启动失败: $e';
      isStreaming = false;
    }
    notifyListeners();
  }

  /// 停止 MJPEG 推流
  Future<void> stopStreaming() async {
    await streamingService.stopStreamingServer();
    isStreaming = false;
    streamingPort = null;
    streamUrl = null;
    notifyListeners();
  }

  /// 切换推流状态
  Future<void> toggleStreaming() async {
    if (isStreaming) {
      await stopStreaming();
    } else {
      await startStreaming();
    }
  }

  // 预留：WebRTC 推流接口
  // Future<void> startWebRTCStreaming() async {}
  // Future<void> stopWebRTCStreaming() async {}
  // ...
} 