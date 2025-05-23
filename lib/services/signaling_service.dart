// lib/services/signaling_service.dart
import 'dart:io';
import 'dart:convert';

typedef OnSignalMessage = void Function(String clientId, Map<String, dynamic> message);

class SignalingService {
  HttpServer? server;
  final Map<String, WebSocket> clients = {};
  final OnSignalMessage onMessage;
  final String roomToken;

  SignalingService({required this.onMessage, required this.roomToken});

  Future<void> start({int port = 9000}) async {
    server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    server!.listen((HttpRequest req) async {
      if (WebSocketTransformer.isUpgradeRequest(req)) {
        final ws = await WebSocketTransformer.upgrade(req);
        final clientId = '${ws.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
        clients[clientId] = ws;
        ws.listen((data) {
          try {
            final msg = jsonDecode(data);
            // 校验房间号/Token
            if (msg['room'] != roomToken) return;
            onMessage(clientId, msg);
            // 广播给其他客户端（多端支持）
            for (final entry in clients.entries) {
              if (entry.key != clientId) {
                entry.value.add(data);
              }
            }
          } catch (_) {}
        }, onDone: () {
          clients.remove(clientId);
        }, onError: (_) {
          clients.remove(clientId);
        });
      } else {
        req.response
          ..statusCode = HttpStatus.forbidden
          ..write('WebSocket only')
          ..close();
      }
    });
    print('信令服务器已启动: ws://${server!.address.address}:$port');
  }

  Future<void> stop() async {
    for (final ws in clients.values) {
      await ws.close();
    }
    clients.clear();
    await server?.close(force: true);
    server = null;
  }
}
