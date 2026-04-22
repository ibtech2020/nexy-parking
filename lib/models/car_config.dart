import 'package:hive/hive.dart';

part 'car_config.g.dart';

@HiveType(typeId: 1)
class CarConfig extends HiveObject {
  @HiveField(0)
  String carId;

  @HiveField(1)
  int colorIndex;

  @HiveField(2)
  int engineUpgrade; // 0-3

  @HiveField(3)
  int handlingUpgrade; // 0-3

  @HiveField(4)
  int brakeUpgrade; // 0-3

  @HiveField(5)
  bool owned;

  CarConfig({
    required this.carId,
    this.colorIndex = 0,
    this.engineUpgrade = 0,
    this.handlingUpgrade = 0,
    this.brakeUpgrade = 0,
    this.owned = false,
  });

  double get engineBonus => engineUpgrade * 0.08;
  double get handlingBonus => handlingUpgrade * 0.07;
  double get brakeBonus => brakeUpgrade * 0.06;

  /// Upgrade costs
  static const List<int> upgradeCosts = [0, 500, 1200, 2500];
}
