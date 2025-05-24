import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<SettingsViewModel>(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('摄像头', colorScheme),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('分辨率'),
                  subtitle: const Text('选择摄像头分辨率'),
                  trailing: DropdownButton<String>(
                    value: viewModel.resolution,
                    items: const [
                      DropdownMenuItem(value: '720p', child: Text('720p')),
                      DropdownMenuItem(value: '1080p', child: Text('1080p')),
                      DropdownMenuItem(value: '4K', child: Text('4K')),
                    ],
                    onChanged: (v) {
                      if (v != null) viewModel.setResolution(v);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('运动检测灵敏度'),
                  subtitle: Text('调节运动检测灵敏度 (${viewModel.motionSensitivityLabel})'),
                  trailing: SizedBox(
                    width: 120,
                    child: Slider(
                      value: viewModel.motionSensitivity,
                      min: 0,
                      max: 2,
                      divisions: 2,
                      label: viewModel.motionSensitivityLabel,
                      onChanged: (v) => viewModel.setMotionSensitivity(v),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('夜视'),
                  subtitle: const Text('启用夜视模式'),
                  trailing: Switch(
                    value: viewModel.isNightVisionEnabled,
                    onChanged: (v) => viewModel.setNightVisionEnabled(v),
                  ),
                ),
              ],
            ),
          ),
          _sectionTitle('通知', colorScheme),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('移动侦测提醒'),
                  subtitle: const Text('当检测到运动时发送提醒'),
                  trailing: Switch(
                    value: viewModel.isMotionDetectionRemindEnabled,
                    onChanged: (v) => viewModel.setMotionDetectionRemindEnabled(v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('声音提醒'),
                  subtitle: const Text('当检测到声音时发送提醒'),
                  trailing: Switch(
                    value: viewModel.isSoundRemindEnabled,
                    onChanged: (v) => viewModel.setSoundRemindEnabled(v),
                  ),
                ),
              ],
            ),
          ),
          _sectionTitle('网络', colorScheme),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Wi-Fi'),
                  subtitle: const Text('当前连接的网络信息'),
                  trailing: Text('家庭网络', style: TextStyle(color: colorScheme.primary)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('远程访问'),
                  subtitle: const Text('通过 Tailscale 内网访问'),
                  trailing: Text('已启用', style: TextStyle(color: colorScheme.primary)),
                ),
              ],
            ),
          ),
          _sectionTitle('外观', colorScheme),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: const Text('浅色模式'),
              trailing: Switch(
                value: viewModel.useLightMode,
                onChanged: (v) => viewModel.toggleTheme(v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 