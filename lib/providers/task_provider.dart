import 'package:flutter/foundation.dart' hide Category;
import 'package:hive/hive.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/models/sub_task.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  final Box<TaskItem> _taskBox = Hive.box<TaskItem>('tasks');
  final Box<Category> _categoryBox = Hive.box<Category>('categories');
  final _uuid = const Uuid();

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  void selectCategory(String? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  List<Category> get categories => _categoryBox.values.toList();

  List<TaskItem> get tasks {
    var list = _taskBox.values.toList();
    if (_selectedCategoryId != null) {
      list = list.where((t) => t.categoryId == _selectedCategoryId).toList();
    }
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  void addCategory(Category category) {
    _categoryBox.put(category.id, category);
    notifyListeners();
  }

  void deleteCategory(String id) {
    _categoryBox.delete(id);
    // Unset categoryId for tasks in this category
    for (var task in _taskBox.values.where((t) => t.categoryId == id)) {
      task.categoryId = null;
      _taskBox.put(task.id, task);
    }
    if (_selectedCategoryId == id) _selectedCategoryId = null;
    notifyListeners();
  }

  void addTask(TaskItem task) {
    if (task.orderIndex == 0 && _taskBox.isNotEmpty) {
      task.orderIndex = tasks.isNotEmpty ? tasks.last.orderIndex + 1 : 0;
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
    final currentTasks = tasks;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = currentTasks.removeAt(oldIndex);
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
      orderIndex: _taskBox.isNotEmpty ? _taskBox.values.toList().last.orderIndex + 1 : 0,
      categoryId: completedTask.categoryId,
    );
    
    _taskBox.put(newTask.id, newTask);
    notifyListeners();
  }
}
