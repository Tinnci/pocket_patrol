import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/streaming_service.dart';
import '../services/image_conversion_service.dart';
import '../services/webrtc_streaming_service.dart';
import '../services/network_service.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../services/signaling_service.dart';

/// Represents the current operating mode of the camera.
enum CameraMode {
  previewOnly,
  mjpegStreaming,
  webrtcStreaming,
  localRecording,
}

/// 负责摄像头预览、初始化、错误处理、推流等业务逻辑
class LiveViewViewModel extends ChangeNotifier {
  final CameraService cameraService;
  late final StreamingService streamingService;
  late final WebRTCStreamingService webrtcService;
  SignalingService? signalingService;
  bool isCameraInitialized = false;
  String? error;
  // MJPEG
  bool isStreaming = false;
  int? streamingPort;
  String? streamUrl;
  // WebRTC
  bool isWebRTCStreaming = false;
  String? localSdp;
  String? remoteSdp;
  List<Map<String, dynamic>> localIceCandidates = [];
  List<Map<String, dynamic>> remoteIceCandidates = [];
  // WebRTC 连接状态
  String webrtcConnectionState = 'disconnected'; // connecting/connected/disconnected/failed
  // 网络与二维码
  String? tailscaleIp;
  String? wsUrl;
  String? roomToken;
  String? qrData;
  // 状态管理
  String tailscaleStatus = 'connecting'; // connecting/connected/failed
  String signalingStatus = 'starting'; // starting/started/failed
  String? statusMessage;
  // 录像相关
  bool isRecording = false;
  String? currentRecordingPath;
  String? _lastRecordedPath;
  String? get lastRecordedPath => _lastRecordedPath;
  // 当前摄像头工作模式
  CameraMode currentMode = CameraMode.previewOnly;
  // 是否忙碌 (推流或录像)
  bool get isBusy => isStreaming || isWebRTCStreaming || isRecording;

  LiveViewViewModel({required this.cameraService}) {
    streamingService = StreamingService(
      cameraService: cameraService,
      imageConversionService: ImageConversionService(),
    );
    webrtcService = WebRTCStreamingService();
    _initNetworkInfo();
  }

  Future<void> _initNetworkInfo() async {
    tailscaleStatus = 'connecting';
    signalingStatus = 'starting';
    statusMessage = null;
    notifyListeners();
    try {
      tailscaleIp = await NetworkService.getTailscaleIp();
      if (tailscaleIp == null) {
        tailscaleStatus = 'failed';
        statusMessage = '未检测到 Tailscale IP，请先连接虚拟内网';
        qrData = null;
        notifyListeners();
        return;
      }
      tailscaleStatus = 'connected';
      roomToken = const Uuid().v4();
      wsUrl = 'ws://$tailscaleIp:9000';
      signalingStatus = 'starting';
      signalingService = SignalingService(
        onMessage: _onSignalMessage,
        roomToken: roomToken!,
      );
      // 初始化后再设置 webrtc 回调
      webrtcService.onLocalSdp = (sdp) {
        localSdp = jsonEncode({'sdp': sdp.sdp, 'type': sdp.type});
        if (signalingService != null && signalingService!.server != null) {
          signalingService!.clients.forEach((id, ws) {
            ws.add(jsonEncode({
              'type': 'sdp',
              'role': 'host',
              'room': roomToken,
              'data': {'sdp': sdp.sdp, 'type': sdp.type}
            }));
          });
        }
        notifyListeners();
      };
      webrtcService.onLocalIceCandidate = (c) {
        final candidate = {
          'candidate': c.candidate,
          'sdpMid': c.sdpMid,
          'sdpMLineIndex': c.sdpMLineIndex,
        };
        localIceCandidates.add(candidate);
        if (signalingService != null && signalingService!.server != null) {
          signalingService!.clients.forEach((id, ws) {
            ws.add(jsonEncode({
              'type': 'ice',
              'role': 'host',
              'room': roomToken,
              'data': candidate
            }));
          });
        }
        notifyListeners();
      };
      updateQrData();
    } catch (e) {
      tailscaleStatus = 'failed';
      statusMessage = '获取 Tailscale IP 失败';
      qrData = null;
      notifyListeners();
    }
  }

  void updateQrData() {
    if (tailscaleStatus == 'connected' && signalingStatus == 'started' && roomToken != null && wsUrl != null) {
      qrData = '{"ws":"$wsUrl","room":"$roomToken"}';
      statusMessage = null;
    } else if (tailscaleStatus != 'connected') {
      qrData = null;
      statusMessage = '未检测到 Tailscale IP，请先连接虚拟内网';
    } else if (signalingStatus != 'started') {
      qrData = null;
      statusMessage = '信令服务未启动，请重试';
    }
    notifyListeners();
  }

  Future<void> _onSignalMessage(String clientId, Map<String, dynamic> msg) async {
    if (msg['type'] == 'sdp' && msg['role'] == 'viewer') {
      // 观看端发来 SDP（Answer）
      await setRemoteSdp(jsonEncode(msg['data']));
    } else if (msg['type'] == 'ice' && msg['role'] == 'viewer') {
      // 观看端发来 ICE
      await addRemoteIceCandidate(jsonEncode(msg['data']));
    }
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

  /// 启动 MJPEG 推流 (与其他推流和录像互斥)
  Future<void> startStreaming({int port = 8080, String? authToken}) async {
    if (isStreaming) return; // 已在推流
    // 如果忙碌（正在进行其他推流或录像），先停止
    if (isWebRTCStreaming) {
      await stopWebRTCStreaming();
    }
    if (isRecording) {
      await stopRecording();
    }
    try {
      // 确保摄像头已初始化
      if (!isCameraInitialized || controller == null) {
        await initializeCamera();
        if (!isCameraInitialized || controller == null) {
          throw Exception('摄像头初始化失败');
        }
      }
      cameraService.startImageStream(streamingService.handleCameraImage); // 让 StreamingService 处理帧
      await streamingService.startStreamingServer(port, authToken: authToken);
      isStreaming = true;
      streamingPort = port;
      streamUrl = 'http://<本机IP或Tailscale IP>:$port/stream.mjpeg';
      error = null;
      currentMode = CameraMode.mjpegStreaming;
    } catch (e) {
      error = '推流启动失败: $e';
      isStreaming = false;
      currentMode = CameraMode.previewOnly;
      cameraService.stopImageStream();
    }
    notifyListeners();
  }

  /// 停止 MJPEG 推流
  Future<void> stopStreaming() async {
    if (!isStreaming) return;
    await streamingService.stopStreamingServer();
    cameraService.stopImageStream();
    isStreaming = false;
    streamingPort = null;
    streamUrl = null;
    currentMode = CameraMode.previewOnly;
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

  // WebRTC 推流控制 (与其他推流和录像互斥)
  Future<void> startWebRTCStreaming() async {
    if (isWebRTCStreaming) return;
    if (isStreaming) {
      await stopStreaming();
    }
    if (isRecording) {
      await stopRecording();
    }
    try {
      // WebRTC 独占摄像头，先释放 CameraController
      await cameraService.dispose();
      isCameraInitialized = false;
      await webrtcService.startWebRTCServer();
      if (signalingService != null) {
        await signalingService!.start(port: 9000);
      }
      isWebRTCStreaming = true;
      webrtcConnectionState = 'connecting';
      error = null;
      webrtcService.onConnectionState = (state) {
        webrtcConnectionState = state;
        if (state == 'connected') {
          currentMode = CameraMode.webrtcStreaming;
        } else if (state == 'failed' || state == 'disconnected') {
          stopWebRTCStreaming();
        }
        notifyListeners();
      };
      signalingStatus = 'started';
      updateQrData();
      currentMode = CameraMode.webrtcStreaming;
    } catch (e) {
      error = 'WebRTC 推流启动失败: $e';
      isWebRTCStreaming = false;
      webrtcConnectionState = 'failed';
      signalingStatus = 'failed';
      updateQrData();
      currentMode = CameraMode.previewOnly;
      await initializeCamera();
    }
    notifyListeners();
  }

  Future<void> stopWebRTCStreaming() async {
    if (!isWebRTCStreaming) return;
    await webrtcService.stopWebRTCServer();
    if (signalingService != null) {
      await signalingService!.stop();
    }
    isWebRTCStreaming = false;
    webrtcConnectionState = 'disconnected';
    signalingStatus = 'starting';
    updateQrData();
    localSdp = null;
    remoteSdp = null;
    localIceCandidates.clear();
    remoteIceCandidates.clear();
    currentMode = CameraMode.previewOnly;
    notifyListeners();
    // WebRTC 结束后恢复摄像头
    await initializeCamera();
  }

  Future<void> toggleWebRTCStreaming() async {
    if (isWebRTCStreaming) {
      await stopWebRTCStreaming();
    } else {
      await startWebRTCStreaming();
    }
  }

  // 信令：设置远端 SDP
  Future<void> setRemoteSdp(String sdpJson) async {
    try {
      final map = jsonDecode(sdpJson);
      await webrtcService.handleRemoteSdp(map['sdp'], map['type']);
      remoteSdp = sdpJson;
      notifyListeners();
    } catch (e) {
      error = '远端SDP设置失败: $e';
      notifyListeners();
    }
  }

  // 信令：添加远端 ICE
  Future<void> addRemoteIceCandidate(String candidateJson) async {
    try {
      final map = jsonDecode(candidateJson);
      await webrtcService.handleRemoteIceCandidate(map);
      remoteIceCandidates.add(map);
      notifyListeners();
    } catch (e) {
      error = '远端ICE添加失败: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    webrtcService.stopWebRTCServer();
    streamingService.stopStreamingServer();
    signalingService?.stop();
    // 停止录像，避免资源泄露 (dispose 可能在录像结束前调用)
    if (isRecording) {
      cameraService.stopRecording(); // 注意：这个停止可能是异步的，dispose 中直接 await 可能有问题，这里先这样处理
    }
    currentMode = CameraMode.previewOnly; // ViewModel 销毁，回到预览模式
    cameraService.dispose(); // 释放 CameraController 资源
    super.dispose();
  }

  // 预留：WebRTC 推流接口
  // Future<void> startWebRTCStreaming() async {}
  // Future<void> stopWebRTCStreaming() async {}
  // ...

  Future<void> startRecording() async {
    if (isRecording) return;
    if (isStreaming) {
      await stopStreaming();
    }
    if (isWebRTCStreaming) {
      await stopWebRTCStreaming();
    }
    try {
      if (!isCameraInitialized || controller == null) {
        await initializeCamera();
        if (!isCameraInitialized || controller == null) {
          throw Exception('摄像头初始化失败');
        }
      }
      currentRecordingPath = await cameraService.startRecording();
      _lastRecordedPath = null;
      isRecording = true;
      error = null;
      currentMode = CameraMode.localRecording;
    } catch (e) {
      error = '录像启动失败: $e';
      isRecording = false;
      currentMode = CameraMode.previewOnly;
    }
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    try {
      final recordedFile = await cameraService.stopRecording();
      _lastRecordedPath = recordedFile.path;
      currentRecordingPath = null;
      isRecording = false;
      error = null;
      currentMode = CameraMode.previewOnly;
    } catch (e) {
      error = '录像停止失败: $e';
      isRecording = false;
      currentRecordingPath = null;
      _lastRecordedPath = null;
    }
    notifyListeners();
  }
} 