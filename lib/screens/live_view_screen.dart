import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../viewmodels/live_view_viewmodel.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'recording_player_screen.dart';
import '../viewmodels/settings_viewmodel.dart';

class LiveViewScreen extends StatefulWidget {
  const LiveViewScreen({Key? key}) : super(key: key);

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  bool _triedInit = false;
  String? _lastSnackPath; // 防止重复弹出
  late LiveViewViewModel _viewModel; // 新增：存储 ViewModel 引用

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 获取 ViewModel 引用并存储
    _viewModel = Provider.of<LiveViewViewModel>(context, listen: false);

    if (!_triedInit) {
      _viewModel.initializeCamera();
      // 使用存储的引用添加监听
      _viewModel.addListener(_handleRecordingFinished);
      _triedInit = true;
    }
  }

  @override
  void dispose() {
     // 移除 ViewModel 监听
     _viewModel.removeListener(_handleRecordingFinished);
     // IMPORTANT: Stop camera preview and streams when screen is disposed
     _viewModel.stopCameraPreviewAndStreams(); // Call the new method
    super.dispose();
  }

  void _handleRecordingFinished() {
    // 直接使用存储的 ViewModel 引用
    if (!_viewModel.isRecording && _viewModel.lastRecordedPath != null && _viewModel.lastRecordedPath != _lastSnackPath) {
      _lastSnackPath = _viewModel.lastRecordedPath;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('录像已保存'),
          action: SnackBarAction(
            label: '查看',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecordingPlayerScreen(
                    videoPath: _viewModel.lastRecordedPath!,
                    title: '最新录像',
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LiveViewViewModel>(context);
    final settingsViewModel = Provider.of<SettingsViewModel>(context); // Access SettingsViewModel
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('监控摄像头'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          if (viewModel.availableCameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: viewModel.isBusy
                  ? null
                  : () => viewModel.cycleSwitchCamera(),
              tooltip: viewModel.cameraSwitchTooltip,
            ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Builder(
        builder: (context) {
          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: colorScheme.error, size: 48),
                  const SizedBox(height: 12),
                  Text(viewModel.error!, style: TextStyle(color: colorScheme.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => viewModel.initializeCamera(),
                    child: const Text('重试'),
                  ),
                  const SizedBox(height: 8),
                  Text('请检查摄像头权限或硬件连接', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            );
          }
          if (!viewModel.isCameraInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 摄像头预览
              viewModel.controller != null && viewModel.isCameraInitialized
                ? Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    child: AspectRatio(
                      aspectRatio: viewModel.controller!.value.aspectRatio,
                      child: CameraPreview(viewModel.controller!),
                    ),
                  )
                : Center(child: Text('摄像头未初始化')),
              const SizedBox(height: 12),
              // 录像按钮
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: viewModel.isRecording ? Colors.red : colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  ),
                  icon: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: viewModel.isRecording
                          ? [BoxShadow(color: Colors.redAccent, blurRadius: 8, spreadRadius: 2)]
                          : [],
                    ),
                  ),
                  label: Text(viewModel.isRecording ? '停止录像' : '开始录像', style: const TextStyle(fontSize: 16)),
                  onPressed: viewModel.isBusy
                      ? null
                      : (viewModel.isRecording
                          ? () => viewModel.stopRecording()
                          : () => viewModel.startRecording()),
                ),
              ),
              const SizedBox(height: 16),
              // 推流按钮
              FilledButton(
                onPressed: viewModel.isBusy && !viewModel.isStreaming ? null : () => viewModel.toggleStreaming(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  viewModel.isStreaming ? '停止推流' : '开始推流',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // 二维码展示区
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: viewModel.qrData != null
                    ? Card(
                        key: const ValueKey('qr'),
                        color: colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text('扫码连接（Tailscale 内网）', style: TextStyle(fontWeight: FontWeight.bold)),
                              QrImageView(
                                data: viewModel.qrData!,
                                size: 180,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              SelectableText(viewModel.qrData!, style: TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      )
                    : Card(
                        key: const ValueKey('status'),
                        color: colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                viewModel.tailscaleStatus != 'connected'
                                    ? Icons.wifi_off
                                    : Icons.sync_problem,
                                color: viewModel.tailscaleStatus != 'connected'
                                    ? Colors.grey
                                    : Colors.orange,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                viewModel.statusMessage ?? '二维码暂不可用',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              if (viewModel.tailscaleStatus != 'connected')
                                ElevatedButton(
                                  onPressed: () {
                                    // 可引导用户打开 Tailscale App
                                  },
                                  child: const Text('打开 Tailscale'),
                                ),
                              if (viewModel.signalingStatus != 'started')
                                ElevatedButton(
                                  onPressed: () => viewModel.startWebRTCStreaming(),
                                  child: const Text('重试'),
                                ),
                            ],
                          ),
                        ),
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
              const SizedBox(height: 16),
              // WebRTC 推流按钮
              FilledButton(
                onPressed: viewModel.isBusy && !viewModel.isWebRTCStreaming ? null : () => viewModel.toggleWebRTCStreaming(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: colorScheme.secondary,
                ),
                child: Text(
                  viewModel.isWebRTCStreaming ? '停止 WebRTC 推流' : '开始 WebRTC 推流',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (viewModel.isWebRTCStreaming) ...[
                const SizedBox(height: 12),
                Card(
                  color: colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              viewModel.webrtcConnectionState == 'connected'
                                  ? Icons.check_circle
                                  : viewModel.webrtcConnectionState == 'connecting'
                                      ? Icons.sync
                                      : viewModel.webrtcConnectionState == 'failed'
                                          ? Icons.error
                                          : Icons.radio_button_unchecked,
                              color: viewModel.webrtcConnectionState == 'connected'
                                  ? Colors.green
                                  : viewModel.webrtcConnectionState == 'connecting'
                                      ? Colors.orange
                                      : viewModel.webrtcConnectionState == 'failed'
                                          ? Colors.red
                                          : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              viewModel.webrtcConnectionState == 'connected'
                                  ? 'WebRTC 已连接'
                                  : viewModel.webrtcConnectionState == 'connecting'
                                      ? 'WebRTC 连接中...'
                                      : viewModel.webrtcConnectionState == 'failed'
                                          ? 'WebRTC 连接失败'
                                          : 'WebRTC 未连接',
                              style: TextStyle(
                                color: viewModel.webrtcConnectionState == 'connected'
                                    ? Colors.green
                                    : viewModel.webrtcConnectionState == 'connecting'
                                        ? Colors.orange
                                        : viewModel.webrtcConnectionState == 'failed'
                                            ? Colors.red
                                            : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('本地 SDP (Offer)', style: TextStyle(fontWeight: FontWeight.bold)),
                        SelectableText(viewModel.localSdp ?? '生成中...'),
                        const SizedBox(height: 8),
                        const Text('本地 ICE Candidates'),
                        ...viewModel.localIceCandidates.map((c) => SelectableText(c.toString())).toList(),
                        const Divider(),
                      ],
                    ),
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
                  subtitle: Text(viewModel.tailscaleIp != null ? viewModel.tailscaleIp! : (viewModel.tailscaleStatus == 'connecting' ? '连接中...' : '未连接'),
                  style: TextStyle(color: viewModel.tailscaleStatus == 'connected' ? Colors.green : Colors.grey)),
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
                      trailing: Text(settingsViewModel.resolution),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.sensors, color: colorScheme.primary),
                      title: const Text('运动检测灵敏度'),
                      trailing: Text(settingsViewModel.motionSensitivityLabel),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.public, color: colorScheme.primary),
                      title: const Text('远程访问'),
                      trailing: Text(
                        viewModel.tailscaleStatus == 'connected'
                            ? '已启用'
                            : viewModel.tailscaleStatus == 'connecting'
                                ? '连接中...'
                                : '未连接',
                        style: TextStyle(
                          color: viewModel.tailscaleStatus == 'connected' ? Colors.green : Colors.grey
                        )
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 