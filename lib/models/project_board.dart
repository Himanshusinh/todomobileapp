import 'package:hive/hive.dart';

part 'project_board.g.dart';

@HiveType(typeId: 27)
class ProjectBoard extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  int sortOrder;

  ProjectBoard({
    required this.id,
    required this.title,
    this.colorValue = 0xFF1565C0,
    this.sortOrder = 0,
  });
}
