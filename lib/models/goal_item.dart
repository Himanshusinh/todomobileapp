import 'package:hive/hive.dart';

part 'goal_item.g.dart';

/// 0 = monthly focus, 1 = yearly / long-term
@HiveType(typeId: 25)
class GoalItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  /// 0 monthly, 1 yearly
  @HiveField(3)
  int timeframe;

  @HiveField(4)
  int targetYear;

  /// 1–12 for monthly; ignored when yearly
  @HiveField(5)
  int? targetMonth;

  @HiveField(6)
  int progressPercent;

  GoalItem({
    required this.id,
    required this.title,
    this.description = '',
    this.timeframe = 1,
    required this.targetYear,
    this.targetMonth,
    this.progressPercent = 0,
  }) {
    progressPercent = progressPercent.clamp(0, 100);
  }
}
