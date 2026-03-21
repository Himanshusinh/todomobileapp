import 'package:hive/hive.dart';

part 'mood_entry.g.dart';

/// 0 = very low … 4 = great
@HiveType(typeId: 12)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String dateKey;

  @HiveField(2)
  int moodLevel;

  @HiveField(3)
  String note;

  MoodEntry({
    required this.id,
    required this.dateKey,
    required this.moodLevel,
    this.note = '',
  });
}
