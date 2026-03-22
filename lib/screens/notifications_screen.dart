import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/screens/task_form_screen.dart';

/// Surfaces due-today and overdue tasks as notification-style alerts.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  /// For drawer badge — same rules as the list on this screen.
  static int countAlertTasks(TaskProvider tp) =>
      _alertTasks(tp.allTasks).length;

  static List<TaskItem> _alertTasks(List<TaskItem> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final list = all.where((t) {
      if (t.isCompleted) return false;
      final d = t.dueDate;
      if (d == null) return false;
      final day = DateTime(d.year, d.month, d.day);
      if (day.isBefore(today)) return true;
      return day.year == today.year &&
          day.month == today.month &&
          day.day == today.day;
    }).toList();
    list.sort((a, b) {
      final ad = a.dueDate!;
      final bd = b.dueDate!;
      return ad.compareTo(bd);
    });
    return list;
  }

  static bool _isOverdue(TaskItem t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = t.dueDate!;
    final day = DateTime(d.year, d.month, d.day);
    return day.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Consumer<TaskProvider>(
        builder: (context, tp, _) {
          final items = _alertTasks(tp.allTasks);
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                floating: false,
                pinned: true,
                expandedHeight: 132,
                backgroundColor: cs.surface,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  background: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.secondaryContainer.withValues(alpha: 0.5),
                          cs.surface,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primaryContainer.withValues(alpha: 0.35),
                        ),
                        child: Icon(
                          Icons.notifications_off_rounded,
                          size: 56,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'You\'re all caught up',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'No overdue or due-today tasks. We\'ll list reminders here when dates are set.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _buildSections(context, items),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static List<Widget> _buildSections(BuildContext context, List<TaskItem> items) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final overdue = items.where(_isOverdue).toList();
    final todayOnly = items.where((t) => !_isOverdue(t)).toList();
    final out = <Widget>[];

    if (overdue.isNotEmpty) {
      out.addAll([
        _SectionLabel(
          text: 'Overdue',
          color: cs.error,
          icon: Icons.error_outline_rounded,
        ),
        ...overdue.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationTaskCard(task: t, urgent: true),
          ),
        ),
        const SizedBox(height: 12),
      ]);
    }
    if (todayOnly.isNotEmpty) {
      out.addAll([
        _SectionLabel(
          text: 'Due today',
          color: cs.primary,
          icon: Icons.today_rounded,
        ),
        ...todayOnly.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationTaskCard(task: t, urgent: false),
          ),
        ),
      ]);
    }
    return out;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTaskCard extends StatelessWidget {
  const _NotificationTaskCard({
    required this.task,
    required this.urgent,
  });

  final TaskItem task;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final d = task.dueDate!;
    final dateStr = DateFormat.MMMd().format(d);

    return Material(
      color: urgent
          ? cs.errorContainer.withValues(alpha: 0.35)
          : cs.primaryContainer.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => TaskFormScreen(task: task),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: urgent
                      ? cs.error.withValues(alpha: 0.15)
                      : cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  urgent
                      ? Icons.priority_high_rounded
                      : Icons.event_rounded,
                  color: urgent ? cs.error : cs.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      urgent ? 'Was due $dateStr' : 'Due $dateStr',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: urgent ? cs.error : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
