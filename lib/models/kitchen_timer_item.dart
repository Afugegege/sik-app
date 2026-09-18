class KitchenTimerItem {
  final String id;
  final String label;
  final int totalSeconds;
  int secondsRemaining;
  bool isRunning;
  bool isFinished;

  KitchenTimerItem({
    required this.id,
    required this.label,
    required this.totalSeconds,
    required this.secondsRemaining,
    this.isRunning = false,
    this.isFinished = false,
  });

  KitchenTimerItem copyWith({
    String? id,
    String? label,
    int? totalSeconds,
    int? secondsRemaining,
    bool? isRunning,
    bool? isFinished,
  }) {
    return KitchenTimerItem(
      id: id ?? this.id,
      label: label ?? this.label,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRunning: isRunning ?? this.isRunning,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}
