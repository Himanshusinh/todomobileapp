import 'package:hive/hive.dart';

part 'sub_task.g.dart';

@HiveType(typeId: 1)
class SubTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}
