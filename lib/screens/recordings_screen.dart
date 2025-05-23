import 'package:flutter/material.dart';

class RecordingsScreen extends StatelessWidget {
  const RecordingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final recordings = [
      {
        'title': '前门',
        'time': '2024-01-20 14:30',
        'thumb': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAjFuh_c7xl4iM1Hkg48-vjmdhdNiYndBkkJcnGVA3ow_iudxjj6jEB28uYs2gv9FPqWD5jTtsUdzTJVDfI4VYNqKW9DvO5I3fTe93pRv2tR39Lgr31nIfRpRWNKlmEmfeL5JPlDhJsPWtRHhAPlmIoZbCxRLZj3wR9Z6LlPUhuOh5RrYDkb50W9in4ihCkujnkQDZPMNJzXZ1TOJBoKnUZo6kAi3j3RPBJvgybyi0epmGK0dgYOWJU0oOvS0HUlVporIc4E96hhlY',
      },
      {
        'title': '后院',
        'time': '2024-01-20 10:15',
        'thumb': 'https://lh3.googleusercontent.com/aida-public/AB6AXuBczxIKtsEu5XSwr7G-QwhfMUtedX8HSio8MtVMNoer4ThVISk9SWYGfIbIQRZ2SaHcebzJRMMGgTc7fGaLQmgjqlaUpu2WEYDQFN9TAEHB5Fr278Su8lI0wcATjuKxN-o1QLmIl3xkSspxkrR1c1eu2v0c6eypseTGlxpIVZP3mnvXbkIMcB6Hs6u_CO7KdzFTS-WdKfI6TQpN6k2sghiZcUClliK1D8vhF70Go2LK4YX3hK8mjvosiCgdDDW1R2_rLQfB2sS3rRU',
      },
      {
        'title': '客厅',
        'time': '2024-01-19 22:45',
        'thumb': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCfec09uQSl8RMLK-5ENbUiEMcY5WsAmbJybQ5sYl8CRf8OJYN554bkfZtOHccYlt0Ob1Ggrh-v7sBJ-Qhke1Tzb3XXzqaMN0TQmrLaXc4jeHHn6ZJltK_DlIKHinCd3OnESsW8bESml8fvE_bugzeeQeWsYdO_rdEzZKGwO8MBQopdsQztPGuaV0lxo-uWm2WVo4YRxJ4CPiBi4WwMqJVYaT8oH5_pnIyYCWtQMJ7MdKXT_zAZ6jEIE9BG6mOqAawPxwCEBYJdV-U',
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('录像列表'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recordings.length,
        itemBuilder: (context, index) {
          final rec = recordings[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  rec['thumb']!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(rec['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(rec['time']!, style: TextStyle(color: colorScheme.onSurfaceVariant)),
              trailing: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
} 