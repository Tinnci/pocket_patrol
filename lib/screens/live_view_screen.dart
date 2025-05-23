import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class LiveViewScreen extends StatefulWidget {
  const LiveViewScreen({Key? key}) : super(key: key);

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = '未检测到摄像头设备';
        });
        return;
      }
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = '摄像头初始化失败: $e';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('监控摄像头'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: _error != null
          ? Center(child: Text(_error!, style: TextStyle(color: colorScheme.error)))
          : !_isCameraInitialized
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 摄像头预览
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: CameraPreview(_controller!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 连接按钮
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('连接', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                    // 网络状态
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: colorScheme.surfaceContainerHighest,
                      child: ListTile(
                        leading: Icon(Icons.wifi, color: colorScheme.primary),
                        title: const Text('Tailscale', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('已连接'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 设置项
                    Text('设置', style: TextStyle(color: colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.videocam, color: colorScheme.primary),
                            title: const Text('摄像头分辨率'),
                            trailing: const Text('1080p'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.sensors, color: colorScheme.primary),
                            title: const Text('运动检测灵敏度'),
                            trailing: const Text('中'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.public, color: colorScheme.primary),
                            title: const Text('远程访问'),
                            trailing: const Text('已启用'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
} 