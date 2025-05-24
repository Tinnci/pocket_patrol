import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../viewmodels/live_view_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = Provider.of<SettingsViewModel>(context);
    final liveViewViewModel = Provider.of<LiveViewViewModel>(context);
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
                    value: settingsViewModel.resolution,
                    items: settingsViewModel.availableResolutions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) settingsViewModel.setResolution(v);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('运动检测灵敏度'),
                  subtitle: Text('调节运动检测灵敏度 (${settingsViewModel.motionSensitivityLabel})'),
                  trailing: SizedBox(
                    width: 120,
                    child: Slider(
                      value: settingsViewModel.motionSensitivity,
                      min: 0,
                      max: 2,
                      divisions: 2,
                      label: settingsViewModel.motionSensitivityLabel,
                      onChanged: (v) => settingsViewModel.setMotionSensitivity(v),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('夜视'),
                  subtitle: const Text('启用夜视模式'),
                  trailing: Switch(
                    value: settingsViewModel.isNightVisionEnabled,
                    onChanged: (v) => settingsViewModel.setNightVisionEnabled(v),
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
                    value: settingsViewModel.isMotionDetectionRemindEnabled,
                    onChanged: (v) => settingsViewModel.setMotionDetectionRemindEnabled(v),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('声音提醒'),
                  subtitle: const Text('当检测到声音时发送提醒'),
                  trailing: Switch(
                    value: settingsViewModel.isSoundRemindEnabled,
                    onChanged: (v) => settingsViewModel.setSoundRemindEnabled(v),
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
                  leading: Icon(Icons.public, color: colorScheme.primary),
                  title: const Text('远程访问 (Tailscale)'),
                  subtitle: Text(liveViewViewModel.tailscaleIp != null
                      ? liveViewViewModel.tailscaleIp!
                      : (liveViewViewModel.tailscaleStatus == 'connecting'
                          ? '连接中...'
                          : '未连接')),
                  trailing: Text(
                    liveViewViewModel.tailscaleStatus == 'connected'
                        ? '已连接'
                        : liveViewViewModel.tailscaleStatus == 'connecting'
                            ? '连接中...'
                            : '未连接',
                    style: TextStyle(
                      color: liveViewViewModel.tailscaleStatus == 'connected'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
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
                value: settingsViewModel.useLightMode,
                onChanged: (v) => settingsViewModel.toggleTheme(v),
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