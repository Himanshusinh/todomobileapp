import 'package:hive/hive.dart';

part 'water_day.g.dart';

/// Total ml for a calendar day; box key = [dateKey].
@HiveType(typeId: 17)
class WaterDay extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  int totalMl;

  WaterDay({
    required this.id,
    this.totalMl = 0,
  });
}
