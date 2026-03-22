import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/providers/notes_provider.dart';
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

  Color _getPriorityColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (task.priority) {
      case TaskPriority.urgent:
        return cs.error;
      case TaskPriority.high:
        return const Color(0xFFFF6D00);
      case TaskPriority.medium:
        return cs.primary;
      case TaskPriority.low:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final notes = context.watch<NotesProvider>();
    final theme = Theme.of(context);
    final expense = task.expenseAmount;
    final hasNote = task.noteMarkdown.trim().isNotEmpty;
    final hasAttach = notes.attachmentsForTask(task.id).isNotEmpty;

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
                  noteMarkdown: '',
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
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : isOverdue
                ? Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.45),
                    width: 1.5,
                  )
                : Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (isOverdue)
            BoxShadow(
              color: theme.colorScheme.error.withValues(alpha: 0.12),
              blurRadius: 10,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Opacity(
        opacity: blocked ? 0.5 : 1.0,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                    color: isOverdue
                        ? theme.colorScheme.error
                        : _getPriorityColor(context),
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
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    countdownText,
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.primary,
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
                        Icon(
                          Icons.repeat,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.recurringInterval.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (expense != null && expense > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 12,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          NumberFormat.simpleCurrency(decimalDigits: 2).format(expense),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (hasNote)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note, size: 14, color: Colors.deepPurple),
                        SizedBox(width: 2),
                        Text('Note', style: TextStyle(fontSize: 10, color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  if (hasAttach)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_file,
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Files',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
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
                      icon: Icon(
                        Icons.center_focus_strong,
                        color: theme.colorScheme.primary,
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
