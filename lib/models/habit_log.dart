import 'package:hive/hive.dart';

part 'habit_log.g.dart';

@HiveType(typeId: 11)
class HabitLog extends HiveObject {
  @HiveField(0)
  String habitId;

  /// `yyyy-MM-dd` local calendar day.
  @HiveField(1)
  String dateKey;

  @HiveField(2)
  bool completed;

  HabitLog({
    required this.habitId,
    required this.dateKey,
    this.completed = true,
  });

  static String composeKey(String habitId, String dateKey) =>
      '${habitId}_$dateKey';
}
