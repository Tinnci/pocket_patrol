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

  void _onSignalMessage(String clientId, Map<String, dynamic> msg) async {
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

  // WebRTC 推流控制
  Future<void> startWebRTCStreaming() async {
    try {
      await webrtcService.startWebRTCServer();
      if (signalingService != null) {
        await signalingService!.start(port: 9000);
      }
      isWebRTCStreaming = true;
      webrtcConnectionState = 'connecting';
      error = null;
      // 监听连接状态
      webrtcService.onConnectionState = (state) {
        webrtcConnectionState = state;
        notifyListeners();
      };
      signalingStatus = 'started';
      updateQrData();
    } catch (e) {
      error = 'WebRTC 推流启动失败: $e';
      isWebRTCStreaming = false;
      webrtcConnectionState = 'failed';
      signalingStatus = 'failed';
      updateQrData();
    }
    notifyListeners();
  }

  Future<void> stopWebRTCStreaming() async {
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
    notifyListeners();
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
    super.dispose();
  }

  // 预留：WebRTC 推流接口
  // Future<void> startWebRTCStreaming() async {}
  // Future<void> stopWebRTCStreaming() async {}
  // ...

  Future<void> startRecording() async {
    if (isRecording) return;
    try {
      final path = await cameraService.startRecording();
      isRecording = true;
      currentRecordingPath = path;
      error = null;
    } catch (e) {
      error = '录像启动失败: $e';
      isRecording = false;
    }
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    try {
      await cameraService.stopRecording();
      isRecording = false;
      currentRecordingPath = null;
      error = null;
    } catch (e) {
      error = '录像停止失败: $e';
    }
    notifyListeners();
  }
} 