import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';

/// 负责摄像头预览、初始化、错误处理等业务逻辑
class LiveViewViewModel extends ChangeNotifier {
  final CameraService cameraService;

  bool isCameraInitialized = false;
  String? error;

  LiveViewViewModel({required this.cameraService});

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

  // 其他业务方法...
} 