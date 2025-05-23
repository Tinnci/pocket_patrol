class RecordingItem {
  final String title;
  final String time;
  final String thumb;
  final String path;

  RecordingItem({required this.title, required this.time, required this.thumb, required this.path});
}

/// 封装录像相关底层操作
class RecordingService {
  // TODO: 实现获取录像列表、删除、播放等方法

  Future<List<RecordingItem>> getRecordings() async {
    // TODO: 实际应从本地存储读取，这里先用假数据
    return [
      RecordingItem(
        title: '前门',
        time: '2024-01-20 14:30',
        thumb: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAjFuh_c7xl4iM1Hkg48-vjmdhdNiYndBkkJcnGVA3ow_iudxjj6jEB28uYs2gv9FPqWD5jTtsUdzTJVDfI4VYNqKW9DvO5I3fTe93pRv2tR39Lgr31nIfRpRWNKlmEmfeL5JPlDhJsPWtRHhAPlmIoZbCxRLZj3wR9Z6LlPUhuOh5RrYDkb50W9in4ihCkujnkQDZPMNJzXZ1TOJBoKnUZo6kAi3j3RPBJvgybyi0epmGK0dgYOWJU0oOvS0HUlVporIc4E96hhlY',
        path: '/recordings/front_door.mp4',
      ),
      RecordingItem(
        title: '后院',
        time: '2024-01-20 10:15',
        thumb: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBczxIKtsEu5XSwr7G-QwhfMUtedX8HSio8MtVMNoer4ThVISk9SWYGfIbIQRZ2SaHcebzJRMMGgTc7fGaLQmgjqlaUpu2WEYDQFN9TAEHB5Fr278Su8lI0wcATjuKxN-o1QLmIl3xkSspxkrR1c1eu2v0c6eypseTGlxpIVZP3mnvXbkIMcB6Hs6u_CO7KdzFTS-WdKfI6TQpN6k2sghiZcUClliK1D8vhF70Go2LK4YX3hK8mjvosiCgdDDW1R2_rLQfB2sS3rRU',
        path: '/recordings/backyard.mp4',
      ),
      RecordingItem(
        title: '客厅',
        time: '2024-01-19 22:45',
        thumb: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCfec09uQSl8RMLK-5ENbUiEMcY5WsAmbJybQ5sYl8CRf8OJYN554bkfZtOHccYlt0Ob1Ggrh-v7sBJ-Qhke1Tzb3XXzqaMN0TQmrLaXc4jeHHn6ZJltK_DlIKHinCd3OnESsW8bESml8fvE_bugzeeQeWsYdO_rdEzZKGwO8MBQopdsQztPGuaV0lxo-uWm2WVo4YRxJ4CPiBi4WwMqJVYaT8oH5_pnIyYCWtQMJ7MdKXT_zAZ6jEIE9BG6mOqAawPxwCEBYJdV-U',
        path: '/recordings/living_room.mp4',
      ),
    ];
  }

  Future<void> deleteRecording(String path) async {
    // TODO: 删除指定录像
  }

  // 其他录像操作...
} 