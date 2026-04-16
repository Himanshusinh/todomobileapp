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
    final cs = theme.colorScheme;
    final hasNote = task.noteMarkdown.trim().isNotEmpty;
    final hasAttach = notes.attachmentsForTask(task.id).isNotEmpty;
    final priorityColor = _getPriorityColor(context);

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

    final dueText = task.dueDate != null ? DateFormat('MMM d').format(task.dueDate!) : null;
    final timeText = task.startTime != null
        ? '${DateFormat('HH:mm').format(task.startTime!)}${task.endTime != null ? '–${DateFormat('HH:mm').format(task.endTime!)}' : ''}'
        : null;
    Widget? metaLine;
    final metaParts = <Widget>[
      if (countdownText != null)
        _InlineMeta(
          icon: Icons.timer_outlined,
          text: countdownText,
          color: cs.primary,
        ),
      if (dueText != null)
        _InlineMeta(
          icon: Icons.event_outlined,
          text: dueText,
          color: isOverdue ? cs.error : cs.primary,
        ),
      if (timeText != null)
        _InlineMeta(
          icon: Icons.schedule_rounded,
          text: timeText,
          color: cs.onSurfaceVariant,
        ),
      if (hasAttach)
        _InlineMeta(
          icon: Icons.attach_file,
          text: 'Files',
          color: cs.onSurfaceVariant,
        ),
      if (hasNote)
        _InlineMeta(
          icon: Icons.notes_outlined,
          text: 'Note',
          color: cs.onSurfaceVariant,
        ),
    ];
    if (metaParts.isNotEmpty) {
      metaLine = Wrap(
        spacing: 10,
        runSpacing: 2,
        children: metaParts,
      );
    }

    final row = Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: blocked ? null : onTap,
            onLongPress: blocked ? null : onLongPress,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isSelectionMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onTap(),
                      ),
                    )
                  else
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: blocked
                          ? null
                          : () {
                              task.isCompleted = !task.isCompleted;
                              taskProvider.updateTask(task);
                            },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              task.isCompleted ? cs.primary : Colors.transparent,
                          border: Border.all(
                            color: task.isCompleted
                                ? cs.primary
                                : cs.outlineVariant.withValues(alpha: 0.7),
                            width: 1.4,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 140),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: task.isCompleted
                              ? Icon(
                                  Icons.check_rounded,
                                  key: const ValueKey('done'),
                                  size: 14,
                                  color: cs.onPrimary,
                                )
                              : const SizedBox(key: ValueKey('empty')),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isOverdue ? cs.error : priorityColor,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutCubic,
                                style: theme.textTheme.titleSmall!.copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.isCompleted
                                      ? cs.onSurfaceVariant
                                      : cs.onSurface,
                                ),
                                child: Text(
                                  task.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.1,
                            ),
                          ),
                        ],
                        if (metaLine != null) ...[
                          const SizedBox(height: 5),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: metaLine,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isSelectionMode)
                    PopupMenuButton<String>(
                      tooltip: 'Task actions',
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                      onSelected: (v) {
                        switch (v) {
                          case 'favorite':
                            taskProvider.toggleFavorite(task.id);
                            return;
                          case 'focus':
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FocusModeScreen(task: task),
                              ),
                            );
                            return;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'favorite',
                          child: Row(
                            children: [
                              Icon(
                                task.isFavorited
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 18,
                                color: task.isFavorited
                                    ? Colors.amber
                                    : cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Text(task.isFavorited
                                  ? 'Unfavorite'
                                  : 'Favorite'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'focus',
                          child: Row(
                            children: [
                              Icon(
                                Icons.center_focus_strong,
                                size: 18,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 10),
                              const Text('Focus mode'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Divider(
            height: 1,
            thickness: 1,
            color: cs.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
      ],
    );

    if (isSelectionMode || blocked) return row;

    return Dismissible(
      key: ValueKey<String>('task_dismiss_${task.id}'),
      direction: DismissDirection.horizontal,
      movementDuration: const Duration(milliseconds: 180),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Right swipe: mark complete (keep the row).
          if (!task.isCompleted) {
            task.isCompleted = true;
            taskProvider.updateTask(task);
          }
          return false;
        }
        if (direction == DismissDirection.endToStart) {
          // Left swipe: delete.
          return true;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          taskProvider.deleteTask(task.id);
        }
      },
      background: Container(
        color: cs.primary.withValues(alpha: 0.10),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            Icon(Icons.check_rounded, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Done',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        color: cs.error.withValues(alpha: 0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: theme.textTheme.labelLarge?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: cs.error),
          ],
        ),
      ),
      child: row,
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.5, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
