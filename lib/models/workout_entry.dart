import 'package:hive/hive.dart';

part 'workout_entry.g.dart';

@HiveType(typeId: 14)
class WorkoutEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  String title;

  @HiveField(3)
  int durationMinutes;

  @HiveField(4)
  String notes;

  WorkoutEntry({
    required this.id,
    required this.date,
    required this.title,
    this.durationMinutes = 0,
    this.notes = '',
  });
}
