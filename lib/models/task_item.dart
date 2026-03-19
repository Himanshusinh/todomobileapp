import 'package:hive/hive.dart';
import 'package:todoapp/models/sub_task.dart';

part 'task_item.g.dart';

@HiveType(typeId: 2)
enum TaskPriority {
  @HiveField(0) low,
  @HiveField(1) medium,
  @HiveField(2) high,
  @HiveField(3) urgent
}

@HiveType(typeId: 3)
enum RecurringInterval {
  @HiveField(0) none,
  @HiveField(1) daily,
  @HiveField(2) weekly,
  @HiveField(3) monthly,
  @HiveField(4) custom
}

@HiveType(typeId: 0)
class TaskItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  TaskPriority priority;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  List<SubTask> subTasks;

  @HiveField(7)
  RecurringInterval recurringInterval;

  @HiveField(8)
  List<String> dependencies; // IDs of other TaskItems

  @HiveField(9)
  List<String> tags;

  @HiveField(10)
  int orderIndex;

  @HiveField(11)
  DateTime? dueTime;

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.isCompleted = false,
    List<SubTask>? subTasks,
    this.recurringInterval = RecurringInterval.none,
    List<String>? dependencies,
    List<String>? tags,
    this.orderIndex = 0,
    this.dueTime,
  })  : subTasks = subTasks ?? [],
        dependencies = dependencies ?? [],
        tags = tags ?? [];

  TaskItem clone() {
    return TaskItem(
      id: id,
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      isCompleted: isCompleted,
      subTasks: List<SubTask>.from(subTasks),
      recurringInterval: recurringInterval,
      dependencies: List<String>.from(dependencies),
      tags: List<String>.from(tags),
      orderIndex: orderIndex,
      dueTime: dueTime,
    );
  }
}
