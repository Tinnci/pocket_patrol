import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'dart:async';

class WebRTCStreamingService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool isStreaming = false;
  final List<RTCIceCandidate> _pendingCandidates = [];
  Function(RTCSessionDescription)? onLocalSdp;
  Function(RTCIceCandidate)? onLocalIceCandidate;
  Function(String)? onConnectionState;

  Future<void> startWebRTCServer({bool audio = false, Map<String, dynamic>? config}) async {
    final configuration = config ?? {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
    final offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': false,
      },
      'optional': [],
    };
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': audio,
      'video': true,
    });
    _peerConnection = await createPeerConnection(configuration, offerSdpConstraints);
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
    _peerConnection!.onIceCandidate = (candidate) {
      if (onLocalIceCandidate != null) onLocalIceCandidate!(candidate);
      else _pendingCandidates.add(candidate);
        };
    _peerConnection!.onConnectionState = (state) {
      print('WebRTC 连接状态: $state');
      if (onConnectionState != null) onConnectionState!(state.toString().split('.').last);
    };
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    isStreaming = true;
    if (onLocalSdp != null) onLocalSdp!(offer);
  }

  Future<void> stopWebRTCServer() async {
    await _localStream?.dispose();
    _localStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
    isStreaming = false;
  }

  Future<void> handleRemoteSdp(String sdp, String type) async {
    if (_peerConnection == null) return;
    final desc = RTCSessionDescription(sdp, type);
    await _peerConnection!.setRemoteDescription(desc);
    // 添加之前缓存的 ICE
    for (final c in _pendingCandidates) {
      await _peerConnection!.addCandidate(c);
    }
    _pendingCandidates.clear();
  }

  Future<void> handleRemoteIceCandidate(Map<String, dynamic> candidate) async {
    if (_peerConnection == null) return;
    final ice = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    await _peerConnection!.addCandidate(ice);
  }
} 