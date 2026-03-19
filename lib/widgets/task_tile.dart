import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';

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
    final theme = Theme.of(context);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    // Check if any dependency is NOT completed
    final blocked = task.dependencies.any((depId) {
      final depTask = taskProvider.tasks.firstWhere((t) => t.id == depId, orElse: () => TaskItem(id: '', title: '', isCompleted: true));
      return !depTask.isCompleted;
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected 
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: isSelected 
          ? Border.all(color: theme.colorScheme.primary, width: 2)
          : Border.all(color: Colors.transparent),
      ),
      child: Opacity(
        opacity: blocked ? 0.5 : 1.0,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onTap: blocked ? null : onTap,
          onLongPress: blocked ? null : onLongPress,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: isSelectionMode
              ? Checkbox(value: isSelected, onChanged: (_) => onTap())
              : Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
          title: Row(
            children: [
              if (blocked) const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              if (blocked) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (blocked)
                const Text('Blocked by dependencies', style: TextStyle(color: Colors.red, fontSize: 10)),
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (task.dueDate != null) ...[
                    Icon(Icons.calendar_today, size: 12, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d').format(task.dueDate!),
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (task.recurringInterval != RecurringInterval.none) ...[
                    const Icon(Icons.repeat, size: 12, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      task.recurringInterval.name.toUpperCase(),
                      style: const TextStyle(fontSize: 9, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: !isSelectionMode 
            ? Checkbox(
                value: task.isCompleted,
                onChanged: blocked ? null : (val) {
                  task.isCompleted = val ?? false;
                  task.save();
                },
              )
            : null,
        ),
      ),
    );
  }
}
