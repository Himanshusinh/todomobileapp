import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:todoapp/models/sub_task.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  final Box<TaskItem> _taskBox = Hive.box<TaskItem>('tasks');
  final _uuid = const Uuid();

  List<TaskItem> get tasks {
    final list = _taskBox.values.toList();
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  void addTask(TaskItem task) {
    if (task.orderIndex == 0 && _taskBox.isNotEmpty) {
      task.orderIndex = tasks.last.orderIndex + 1;
    }
    _taskBox.put(task.id, task);
    notifyListeners();
  }

  void updateTask(TaskItem task) {
    final wasCompleted = _taskBox.get(task.id)?.isCompleted ?? false;
    _taskBox.put(task.id, task);
    
    if (!wasCompleted && task.isCompleted && task.recurringInterval != RecurringInterval.none) {
      _generateNextRecurringTask(task);
    }
    notifyListeners();
  }

  void deleteTask(String id) {
    _taskBox.delete(id);
    notifyListeners();
  }

  void reorderTasks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = tasks.removeAt(oldIndex);
    final currentTasks = tasks;
    currentTasks.insert(newIndex, item);
    
    for (int i = 0; i < currentTasks.length; i++) {
      currentTasks[i].orderIndex = i;
      _taskBox.put(currentTasks[i].id, currentTasks[i]);
    }
    notifyListeners();
  }

  void completeAll(List<String> ids) {
    for (final id in ids) {
      final t = _taskBox.get(id);
      if (t != null) {
        t.isCompleted = true;
        _taskBox.put(id, t);
      }
    }
    notifyListeners();
  }

  void deleteAll(List<String> ids) {
    for (final id in ids) {
      _taskBox.delete(id);
    }
    notifyListeners();
  }

  void _generateNextRecurringTask(TaskItem completedTask) {
    DateTime nextDate;
    final baseDate = completedTask.dueDate ?? DateTime.now();
    switch (completedTask.recurringInterval) {
      case RecurringInterval.daily:
        nextDate = baseDate.add(const Duration(days: 1));
        break;
      case RecurringInterval.weekly:
        nextDate = baseDate.add(const Duration(days: 7));
        break;
      case RecurringInterval.monthly:
        nextDate = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
        break;
      default:
        return;
    }

    final originalInterval = completedTask.recurringInterval;
    
    // Unset recurring on the old one to prevent duplicates if toggled back and forth
    completedTask.recurringInterval = RecurringInterval.none;
    _taskBox.put(completedTask.id, completedTask);

    final newTask = TaskItem(
      id: _uuid.v4(),
      title: completedTask.title,
      description: completedTask.description,
      priority: completedTask.priority,
      dueDate: nextDate,
      dueTime: completedTask.dueTime,
      isCompleted: false,
      subTasks: completedTask.subTasks.map<SubTask>((st) => SubTask(id: _uuid.v4(), title: st.title)).toList(),
      recurringInterval: originalInterval,
      dependencies: completedTask.dependencies,
      tags: completedTask.tags,
      orderIndex: _taskBox.isNotEmpty ? tasks.last.orderIndex + 1 : 0,
    );
    
    _taskBox.put(newTask.id, newTask);
  }
}
