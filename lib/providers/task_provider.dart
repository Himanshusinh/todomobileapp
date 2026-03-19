import 'package:flutter/foundation.dart' hide Category;
import 'package:hive/hive.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/models/sub_task.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:uuid/uuid.dart';

enum TaskFilter { all, today, week, upcoming, overdue, suggested }

class TaskProvider extends ChangeNotifier {
  final Box<TaskItem> _taskBox = Hive.box<TaskItem>('tasks');
  final Box<Category> _categoryBox = Hive.box<Category>('categories');
  final _uuid = const Uuid();

  String? _selectedCategoryId;
  String? get selectedCategoryId => _selectedCategoryId;

  TaskFilter _selectedFilter = TaskFilter.all;
  TaskFilter get selectedFilter => _selectedFilter;

  void selectCategory(String? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  void selectFilter(TaskFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  List<Category> get categories => _categoryBox.values.toList();

  List<TaskItem> get tasks {
    var list = _taskBox.values.toList();
    
    // Apply Category Filter
    if (_selectedCategoryId != null) {
      list = list.where((t) => t.categoryId == _selectedCategoryId).toList();
    }

    // Apply Smart Filter
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    switch (_selectedFilter) {
      case TaskFilter.today:
        list = list.where((t) {
          if (t.dueDate == null) return false;
          final d = t.dueDate!;
          return d.year == today.year && d.month == today.month && d.day == today.day;
        }).toList();
        break;
      case TaskFilter.week:
        list = list.where((t) {
          if (t.dueDate == null) return false;
          return t.dueDate!.isAfter(today.subtract(const Duration(seconds: 1))) && 
                 t.dueDate!.isBefore(nextWeek.add(const Duration(days: 1)));
        }).toList();
        break;
      case TaskFilter.upcoming:
        list = list.where((t) => t.dueDate != null && t.dueDate!.isAfter(today)).toList();
        break;
      case TaskFilter.overdue:
        list = list.where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(today)).toList();
        break;
      case TaskFilter.suggested:
        list = getSuggestedTasks();
        break;
      case TaskFilter.all:
        break;
    }

    if (_selectedFilter != TaskFilter.suggested) {
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }
    return list;
  }

  List<TaskItem> getSuggestedTasks() {
    final allTasks = _taskBox.values.where((t) => !t.isCompleted).toList();
    
    // Smart Priority: Deadline > Priority > Favorite
    allTasks.sort((a, b) {
      // 1. Deadline (Closest first)
      if (a.dueDate != null && b.dueDate != null) {
        if (a.dueDate != b.dueDate) return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }

      // 2. Priority
      if (a.priority != b.priority) {
        return b.priority.index.compareTo(a.priority.index); // Higher enum index is higher priority
      }

      // 3. Favorite
      if (a.isFavorited != b.isFavorited) {
        return a.isFavorited ? -1 : 1;
      }

      return 0;
    });

    return allTasks.take(5).toList();
  }

  void toggleFavorite(String taskId) {
    final task = _taskBox.get(taskId);
    if (task != null) {
      task.isFavorited = !task.isFavorited;
      _taskBox.put(taskId, task);
      notifyListeners();
    }
  }

  void updateTimeSpent(String taskId, int minutes) {
    final task = _taskBox.get(taskId);
    if (task != null) {
      task.actualMinutes = (task.actualMinutes ?? 0) + minutes;
      _taskBox.put(taskId, task);
      notifyListeners();
    }
  }

  void autoPrioritize() {
    final list = _taskBox.values.toList();
    list.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      return b.priority.index.compareTo(a.priority.index);
    });

    for (int i = 0; i < list.length; i++) {
      list[i].orderIndex = i;
      _taskBox.put(list[i].id, list[i]);
    }
    notifyListeners();
  }

  // Get tasks for a specific day (used by Calendar)
  List<TaskItem> getTasksForDay(DateTime day) {
    return _taskBox.values.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == day.year && 
             t.dueDate!.month == day.month && 
             t.dueDate!.day == day.day;
    }).toList();
  }

  void addCategory(Category category) {
    _categoryBox.put(category.id, category);
    notifyListeners();
  }

  void deleteCategory(String id) {
    _categoryBox.delete(id);
    for (var task in _taskBox.values.where((t) => t.categoryId == id)) {
      task.categoryId = null;
      _taskBox.put(task.id, task);
    }
    if (_selectedCategoryId == id) _selectedCategoryId = null;
    notifyListeners();
  }

  void addTask(TaskItem task) {
    if (task.orderIndex == 0 && _taskBox.isNotEmpty) {
      task.orderIndex = _taskBox.values.isEmpty ? 0 : _taskBox.values.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
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
      subTasks: completedTask.subTasks.map<SubTask>((st) => SubTask(id: _uuid.v4(), title: st.title, isCompleted: false)).toList(),
      recurringInterval: originalInterval,
      dependencies: completedTask.dependencies,
      tags: completedTask.tags,
      orderIndex: _taskBox.values.isEmpty ? 0 : _taskBox.values.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b) + 1,
      categoryId: completedTask.categoryId,
      startTime: completedTask.startTime,
      endTime: completedTask.endTime,
      durationMinutes: completedTask.durationMinutes,
      estimatedMinutes: completedTask.estimatedMinutes,
      actualMinutes: 0,
      isFavorited: completedTask.isFavorited,
    );
    
    _taskBox.put(newTask.id, newTask);
    notifyListeners();
  }
}
