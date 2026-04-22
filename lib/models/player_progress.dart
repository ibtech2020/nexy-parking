import 'package:hive/hive.dart';

part 'player_progress.g.dart';

@HiveType(typeId: 0)
class PlayerProgress extends HiveObject {
  @HiveField(0)
  int totalScore;

  @HiveField(1)
  int coins;

  @HiveField(2)
  List<int> unlockedLevels;

  @HiveField(3)
  List<int> levelStars;

  @HiveField(4)
  List<int> levelBestTimes;

  @HiveField(5)
  List<int> levelBestScores;

  @HiveField(6)
  String selectedCarId;

  @HiveField(7)
  int selectedColorIndex;

  PlayerProgress({
    this.totalScore = 0,
    this.coins = 0,
    this.unlockedLevels = const [0],
    this.levelStars = const [],
    this.levelBestTimes = const [],
    this.levelBestScores = const [],
    this.selectedCarId = 'sedan',
    this.selectedColorIndex = 0,
  });

  factory PlayerProgress.fresh() => PlayerProgress(
    totalScore: 0,
    coins: 500,
    unlockedLevels: [0],
    levelStars: List.filled(10, 0),
    levelBestTimes: List.filled(10, 0),
    levelBestScores: List.filled(10, 0),
    selectedCarId: 'sedan',
    selectedColorIndex: 0,
  );

  void recordLevelResult({
    required int levelId,
    required int stars,
    required int score,
    required int timeSeconds,
  }) {
    if (levelId < levelStars.length) {
      if (stars > levelStars[levelId]) levelStars[levelId] = stars;
    }
    if (levelId < levelBestScores.length) {
      if (score > levelBestScores[levelId]) levelBestScores[levelId] = score;
    }
    if (levelId < levelBestTimes.length) {
      if (levelBestTimes[levelId] == 0 || timeSeconds < levelBestTimes[levelId]) {
        levelBestTimes[levelId] = timeSeconds;
      }
    }
    totalScore += score;
    coins += score ~/ 10;

    final nextLevel = levelId + 1;
    if (!unlockedLevels.contains(nextLevel)) {
      unlockedLevels = [...unlockedLevels, nextLevel];
    }
    save();
  }
}
