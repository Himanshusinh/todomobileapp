import 'package:hive/hive.dart';

part 'kanban_item.g.dart';

/// column: 0 To Do, 1 In Progress, 2 Done
@HiveType(typeId: 28)
class KanbanItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String boardId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String notes;

  @HiveField(4)
  int column;

  @HiveField(5)
  int orderIndex;

  KanbanItem({
    required this.id,
    required this.boardId,
    required this.title,
    this.notes = '',
    this.column = 0,
    this.orderIndex = 0,
  }) {
    column = column.clamp(0, 2);
  }
}
