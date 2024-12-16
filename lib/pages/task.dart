class Task {
  final String id;
  final String title;
  final int difficulty;
  int level;
  final String imageUrl;

  Task({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.level,
    required this.imageUrl,
  });

  int get maxLevel => difficulty * 10;

  void levelUp() {
    if (level < maxLevel) {
      level++;
    }
  }
}
