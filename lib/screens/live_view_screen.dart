import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../viewmodels/live_view_viewmodel.dart';

class LiveViewScreen extends StatelessWidget {
  const LiveViewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LiveViewViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('监控摄像头'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: viewModel.error != null
          ? Center(child: Text(viewModel.error!, style: TextStyle(color: colorScheme.error)))
          : !viewModel.isCameraInitialized
              ? Center(
                  child: ElevatedButton(
                    onPressed: () => viewModel.initializeCamera(),
                    child: const Text('初始化摄像头'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 摄像头预览
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: viewModel.controller!.value.aspectRatio,
                        child: CameraPreview(viewModel.controller!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 推流按钮
                    FilledButton(
                      onPressed: () => viewModel.toggleStreaming(),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        viewModel.isStreaming ? '停止推流' : '开始推流',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (viewModel.isStreaming && viewModel.streamUrl != null) ...[
                      const SizedBox(height: 12),
                      Card(
                        color: colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Icon(Icons.link, color: colorScheme.primary),
                          title: const Text('推流地址'),
                          subtitle: Text(viewModel.streamUrl!),
                        ),
                      ),
                    ],
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