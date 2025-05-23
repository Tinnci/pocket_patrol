import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/recordings_viewmodel.dart';
import 'recording_player_screen.dart';

class RecordingsScreen extends StatelessWidget {
  const RecordingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = Provider.of<RecordingsViewModel>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('录像列表'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: Builder(
        builder: (context) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.error != null) {
            return Center(child: Text(viewModel.error!, style: TextStyle(color: colorScheme.error)));
          }
          if (viewModel.recordings.isEmpty) {
            return Center(child: Text('暂无本地录像', style: TextStyle(color: colorScheme.onSurfaceVariant)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.recordings.length,
            itemBuilder: (context, index) {
              final rec = viewModel.recordings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.videocam, color: colorScheme.primary, size: 40),
                  title: Text(rec.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(rec.time, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  trailing: Icon(Icons.play_arrow, color: colorScheme.primary),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecordingPlayerScreen(videoPath: rec.path, title: rec.title),
                      ),
                    );
                  },
                  onLongPress: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('删除确认'),
                        content: Text('确定要删除该录像吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('删除', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await viewModel.deleteRecording(rec.path);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已删除')));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
} 