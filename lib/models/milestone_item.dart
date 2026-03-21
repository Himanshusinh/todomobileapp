import 'package:hive/hive.dart';

part 'milestone_item.g.dart';

@HiveType(typeId: 26)
class MilestoneItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String parentGoalId;

  @HiveField(2)
  String title;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  int progressPercent;

  @HiveField(5)
  bool isCompleted;

  MilestoneItem({
    required this.id,
    required this.parentGoalId,
    required this.title,
    this.dueDate,
    this.progressPercent = 0,
    this.isCompleted = false,
  }) {
    progressPercent = progressPercent.clamp(0, 100);
  }
}
