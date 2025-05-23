import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final bool useLightMode;
  final void Function(bool) handleBrightnessChange;

  const SettingsScreen({
    Key? key,
    required this.themeMode,
    required this.useLightMode,
    required this.handleBrightnessChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  subtitle: const Text('1280 x 720'),
                  trailing: Text('720p', style: TextStyle(color: colorScheme.primary)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('运动检测'),
                  subtitle: const Text('中'),
                  trailing: Text('中', style: TextStyle(color: colorScheme.primary)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('夜视'),
                  subtitle: const Text('关闭'),
                  trailing: Text('关闭', style: TextStyle(color: colorScheme.primary)),
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
                  subtitle: const Text('开启'),
                  trailing: Text('开启', style: TextStyle(color: colorScheme.primary)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('声音提醒'),
                  subtitle: const Text('关闭'),
                  trailing: Text('关闭', style: TextStyle(color: colorScheme.primary)),
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
                  subtitle: const Text('已连接'),
                  trailing: Text('家庭网络', style: TextStyle(color: colorScheme.primary)),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('远程访问'),
                  subtitle: const Text('已启用'),
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
                value: useLightMode,
                onChanged: handleBrightnessChange,
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