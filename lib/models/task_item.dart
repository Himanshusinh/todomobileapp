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
  int? _orderIndex;
  int get orderIndex => _orderIndex ?? 0;
  set orderIndex(int value) => _orderIndex = value;

  @HiveField(11)
  DateTime? dueTime;

  @HiveField(12)
  String? categoryId;

  @HiveField(13)
  DateTime? startTime;

  @HiveField(14)
  DateTime? endTime;

  @HiveField(15)
  int? durationMinutes;

  @HiveField(16)
  int? estimatedMinutes;

  @HiveField(17)
  int? actualMinutes;

  @HiveField(18)
  bool? _isFavorited;
  bool get isFavorited => _isFavorited ?? false;
  set isFavorited(bool value) => _isFavorited = value;

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
    int orderIndex = 0,
    this.dueTime,
    this.categoryId,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.estimatedMinutes,
    this.actualMinutes,
    bool isFavorited = false,
  })  : _orderIndex = orderIndex,
        _isFavorited = isFavorited,
        subTasks = subTasks ?? [],
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
      categoryId: categoryId,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      estimatedMinutes: estimatedMinutes,
      actualMinutes: actualMinutes,
      isFavorited: isFavorited,
    );
  }
}
