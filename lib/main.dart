import 'package:flutter/material.dart';
import 'screens/live_view_screen.dart';
import 'screens/recordings_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const PocketPatrolApp());
}

class PocketPatrolApp extends StatefulWidget {
  const PocketPatrolApp({super.key});

  @override
  State<PocketPatrolApp> createState() => _PocketPatrolAppState();
}

class _PocketPatrolAppState extends State<PocketPatrolApp> {
  bool _useMaterial3 = true;
  ThemeMode _themeMode = ThemeMode.system;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _handleBrightnessChange(bool useLightMode) {
    setState(() {
      _themeMode = useLightMode ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Brightness platformBrightness = View.of(context).platformDispatcher.platformBrightness;
    final bool effectivelyLightMode = (_themeMode == ThemeMode.system && platformBrightness == Brightness.light) || _themeMode == ThemeMode.light;

    final List<Widget> _screens = [
      LiveViewScreen(),
      RecordingsScreen(),
      SettingsScreen(
        themeMode: _themeMode,
        useLightMode: effectivelyLightMode,
        handleBrightnessChange: _handleBrightnessChange,
      ),
    ];

    return MaterialApp(
      title: 'PocketPatrol',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: _useMaterial3,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: _useMaterial3,
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