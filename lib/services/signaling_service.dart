// lib/services/signaling_service.dart
import 'dart:io';
import 'dart:convert';

typedef OnSignalMessage = void Function(String clientId, Map<String, dynamic> message);

class SignalingService {
  HttpServer? _server;
  final Map<String, WebSocket> _clients = {};
  final OnSignalMessage onMessage;
  final String roomToken;

  SignalingService({required this.onMessage, required this.roomToken});

  Future<void> start({int port = 9000}) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen((HttpRequest req) async {
      if (WebSocketTransformer.isUpgradeRequest(req)) {
        final ws = await WebSocketTransformer.upgrade(req);
        final clientId = '${ws.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
        _clients[clientId] = ws;
        ws.listen((data) {
          try {
            final msg = jsonDecode(data);
            // 校验房间号/Token
            if (msg['room'] != roomToken) return;
            onMessage(clientId, msg);
            // 广播给其他客户端（多端支持）
            for (final entry in _clients.entries) {
              if (entry.key != clientId) {
                entry.value.add(data);
              }
            }
          } catch (_) {}
        }, onDone: () {
          _clients.remove(clientId);
        }, onError: (_) {
          _clients.remove(clientId);
        });
      } else {
        req.response
          ..statusCode = HttpStatus.forbidden
          ..write('WebSocket only')
          ..close();
      }
    });
    print('信令服务器已启动: ws://${_server!.address.address}:$port');
  }

  Future<void> stop() async {
    for (final ws in _clients.values) {
      await ws.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }
}
