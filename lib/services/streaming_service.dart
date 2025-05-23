import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:camera/camera.dart';
import 'image_conversion_service.dart';
import 'camera_service.dart';

class StreamingService {
  HttpServer? _httpServer;
  final _router = Router();
  StreamController<List<int>>? _mjpegStreamController;
  final CameraService cameraService;
  final ImageConversionService imageConversionService;
  String? _activeAuthToken;
  bool get isStreaming => _httpServer != null;
  int? get port => _httpServer?.port;

  StreamingService({required this.cameraService, required this.imageConversionService}) {
    _router.get('/stream.mjpeg', (shelf.Request request) {
      if (_activeAuthToken != null) {
        final authHeader = request.headers['Authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ') || authHeader.substring(7) != _activeAuthToken) {
          return shelf.Response.forbidden('Unauthorized');
        }
      }
      return _mjpegStreamHandler(request);
    });
  }

  Future<void> startStreamingServer(int port, {String? authToken}) async {
    _activeAuthToken = authToken;
    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_router.call);
    _httpServer = await io.serve(handler, InternetAddress.anyIPv4, port);
    print('MJPEG 服务器已启动，监听端口: ${_httpServer!.port}');
  }

  Future<void> stopStreamingServer() async {
    await _mjpegStreamController?.close();
    _mjpegStreamController = null;
    await _httpServer?.close(force: true);
    _httpServer = null;
    _activeAuthToken = null;
    print('MJPEG 服务器已停止');
  }

  shelf.Response _mjpegStreamHandler(shelf.Request request) {
    _mjpegStreamController = StreamController<List<int>>(
      onListen: () {
        print('MJPEG 客户端已连接，开始推送帧...');
        cameraService.startImageStream((CameraImage cameraImage) async {
          if (_mjpegStreamController == null || _mjpegStreamController!.isClosed) {
            cameraService.stopImageStream();
            return;
          }
          final jpegData = await imageConversionService.convertCameraImageToJpeg(cameraImage);
          if (jpegData != null && !_mjpegStreamController!.isClosed) {
            _mjpegStreamController!.add(utf8.encode('--frame\r\n'));
            _mjpegStreamController!.add(utf8.encode('Content-Type: image/jpeg\r\n'));
            _mjpegStreamController!.add(utf8.encode('Content-Length: ${jpegData.length}\r\n'));
            _mjpegStreamController!.add(utf8.encode('X-Timestamp: ${DateTime.now().millisecondsSinceEpoch}\r\n'));
            _mjpegStreamController!.add(utf8.encode('\r\n'));
            _mjpegStreamController!.add(jpegData);
            _mjpegStreamController!.add(utf8.encode('\r\n'));
          }
        });
      },
      onCancel: () {
        print('MJPEG 客户端已断开');
        cameraService.stopImageStream();
        _mjpegStreamController?.close();
        _mjpegStreamController = null;
      },
    );
    final headers = {
      'Content-Type': 'multipart/x-mixed-replace; boundary=--frame',
      'Connection': 'close',
      'Cache-Control': 'no-store, no-cache, must-revalidate, pre-check=0, post-check=0, max-age=0',
      'Pragma': 'no-cache',
      'Access-Control-Allow-Origin': '*',
    };
    final responseContext = {'shelf.io.buffer_output': false};
    return shelf.Response.ok(
      _mjpegStreamController!.stream,
      headers: headers,
      context: responseContext,
    );
  }
} 