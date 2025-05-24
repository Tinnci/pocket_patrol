import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/live_view_screen.dart';
import 'screens/recordings_screen.dart';
import 'screens/settings_screen.dart';
import 'services/camera_service.dart';
import 'services/recording_service.dart';
import 'services/settings_service.dart';
import 'viewmodels/live_view_viewmodel.dart';
import 'viewmodels/recordings_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';

void main() {
  // Create CameraService instance here to share
  final cameraService = CameraService();

  runApp(
    MultiProvider(
      providers: [
        // 先创建 SettingsViewModel
        ChangeNotifierProvider(
          create: (context) { // Use context here to access other providers
            final vm = SettingsViewModel(
              settingsService: SettingsService(),
              cameraService: cameraService, // Provide the shared CameraService instance
              // TODO: Provide other services here
            );
            // 在 ViewModel 创建时加载所有设置
            vm.loadSettings();
            return vm;
          },
        ),
        // 再创建 LiveViewViewModel，此时可以访问 SettingsViewModel
        ChangeNotifierProvider(
          // Provide the shared CameraService instance
          create: (context) => LiveViewViewModel(
            cameraService: cameraService,
            settingsViewModel: Provider.of<SettingsViewModel>(context, listen: false), // Get SettingsViewModel
          ),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final vm = RecordingsViewModel(recordingService: RecordingService());
            // 自动加载录像列表最佳实践：构造后立即加载
            vm.loadRecordings();
            return vm;
          },
        ),
      ],
      child: const PocketPatrolApp(),
    ),
  );
}

class PocketPatrolApp extends StatefulWidget {
  const PocketPatrolApp({super.key});

  @override
  State<PocketPatrolApp> createState() => _PocketPatrolAppState();
}

class _PocketPatrolAppState extends State<PocketPatrolApp> {
  bool _useMaterial3 = true; // TODO: This should likely be driven by settingsViewModel
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsViewModel = Provider.of<SettingsViewModel>(context);

    final List<Widget> _screens = [
      LiveViewScreen(),
      RecordingsScreen(),
      SettingsScreen(),
    ];

    return MaterialApp(
      title: 'PocketPatrol',
      debugShowCheckedModeBanner: false,
      themeMode: settingsViewModel.themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: _useMaterial3, // TODO: Use settingsViewModel
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: _useMaterial3, // TODO: Use settingsViewModel
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home),
              label: '主页',
            ),
            NavigationDestination(
              icon: Icon(Icons.videocam),
              label: '录像',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      ),
    );
  }
}

// 可以暂时移除或注释掉 MyHomePage，因为 DeviceScanScreen 现在是主屏幕
/*
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReachCtrl Home'),
      ),
      body: const Center(
        child: Text(
          'Welcome to ReachCtrl!\nBLE Mouse/Touchpad with Haptics',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
*/ 