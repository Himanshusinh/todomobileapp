import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 10)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  int orderIndex;

  Habit({
    required this.id,
    required this.title,
    this.colorValue = 0xFF2196F3,
    this.orderIndex = 0,
  });
}
