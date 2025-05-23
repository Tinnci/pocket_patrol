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
                    const SizedBox(height: 16),
                    // WebRTC 推流按钮
                    FilledButton(
                      onPressed: () => viewModel.toggleWebRTCStreaming(),
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
                              const Text('本地 SDP (Offer)', style: TextStyle(fontWeight: FontWeight.bold)),
                              SelectableText(viewModel.localSdp ?? '生成中...'),
                              const SizedBox(height: 8),
                              const Text('本地 ICE Candidates'),
                              ...viewModel.localIceCandidates.map((c) => SelectableText(c.toString())).toList(),
                              const Divider(),
                              const Text('远端 SDP (Answer) 输入'),
                              _RemoteSdpInput(viewModel: viewModel),
                              const SizedBox(height: 8),
                              const Text('远端 ICE Candidate 输入'),
                              _RemoteIceInput(viewModel: viewModel),
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

// 组件：远端SDP输入
class _RemoteSdpInput extends StatefulWidget {
  final dynamic viewModel;
  const _RemoteSdpInput({required this.viewModel});
  @override
  State<_RemoteSdpInput> createState() => _RemoteSdpInputState();
}
class _RemoteSdpInputState extends State<_RemoteSdpInput> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: '粘贴远端SDP JSON'),
            minLines: 1,
            maxLines: 3,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () async {
            await widget.viewModel.setRemoteSdp(_controller.text);
            _controller.clear();
          },
        ),
      ],
    );
  }
}
// 组件：远端ICE输入
class _RemoteIceInput extends StatefulWidget {
  final dynamic viewModel;
  const _RemoteIceInput({required this.viewModel});
  @override
  State<_RemoteIceInput> createState() => _RemoteIceInputState();
}
class _RemoteIceInputState extends State<_RemoteIceInput> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: '粘贴远端ICE JSON'),
            minLines: 1,
            maxLines: 2,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: () async {
            await widget.viewModel.addRemoteIceCandidate(_controller.text);
            _controller.clear();
          },
        ),
      ],
    );
  }
} 