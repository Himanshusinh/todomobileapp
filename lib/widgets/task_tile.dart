import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/screens/focus_mode_screen.dart';

class TaskTile extends StatelessWidget {
  final TaskItem task;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TaskTile({
    super.key,
    required this.task,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final theme = Theme.of(context);

    final blocked =
        task.dependencies.isNotEmpty &&
        task.dependencies.any((id) {
          final depTask = taskProvider
              .getTasksForDay(DateTime.now())
              .firstWhere(
                (t) => t.id == id,
                orElse: () => TaskItem(
                  id: '',
                  title: '',
                  description: '',
                  priority: TaskPriority.low,
                ),
              );
          if (depTask.id == '') return false;
          return !depTask.isCompleted;
        });

    final isOverdue =
        !task.isCompleted &&
        task.dueDate != null &&
        DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        ).isBefore(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        );

    String? countdownText;
    if (!task.isCompleted && task.dueDate != null && task.dueTime != null) {
      final now = DateTime.now();
      final due = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        task.dueTime!.hour,
        task.dueTime!.minute,
      );
      final diff = due.difference(now);
      if (diff.inSeconds > 0 && diff.inHours < 24) {
        countdownText = 'Due in ${diff.inHours}h ${diff.inMinutes % 60}m';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : isOverdue
            ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5)
            : Border.all(color: Colors.transparent),
        boxShadow: isOverdue
            ? [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Opacity(
        opacity: blocked ? 0.5 : 1.0,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onTap: blocked ? null : onTap,
          onLongPress: blocked ? null : onLongPress,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: isSelectionMode
              ? Checkbox(value: isSelected, onChanged: (_) => onTap())
              : Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.red : _getPriorityColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
          title: Row(
            children: [
              if (blocked)
                const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              if (blocked) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (countdownText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    countdownText,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOverdue)
                const Text(
                  'Overdue',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (blocked)
                const Text(
                  'Blocked by dependencies',
                  style: TextStyle(color: Colors.red, fontSize: 10),
                ),
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (task.dueDate != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isOverdue
                              ? Colors.red
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(task.dueDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverdue
                                ? Colors.red
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  if (task.startTime != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormat('HH:mm').format(task.startTime!)} - ${task.endTime != null ? DateFormat('HH:mm').format(task.endTime!) : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  if (task.recurringInterval != RecurringInterval.none)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.repeat,
                          size: 12,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.recurringInterval.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          trailing: !isSelectionMode
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        task.isFavorited ? Icons.star : Icons.star_border,
                        color: task.isFavorited ? Colors.amber : Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => taskProvider.toggleFavorite(task.id),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.center_focus_strong,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FocusModeScreen(task: task),
                        ),
                      ),
                    ),
                    Checkbox(
                      value: task.isCompleted,
                      onChanged: blocked
                          ? null
                          : (val) {
                              task.isCompleted = val ?? false;
                              taskProvider.updateTask(task);
                            },
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}
