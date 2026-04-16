import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/habit.dart';
import 'package:todoapp/providers/health_provider.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Calendar day for health data (always “today”).
  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String get _key => HealthProvider.dateKey(_today);

  static const _moodLabels = ['Rough', 'Low', 'Okay', 'Good', 'Great'];

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HealthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'Activity'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _TodayTab(
                    dateKey: _key,
                    day: _today,
                    health: h,
                    onMoodNote: (level) => _moodNoteDialog(context, level),
                    onDeleteHabit: (habit) => _confirmDeleteHabit(context, habit),
                  ),
                  _ActivityTab(
                    health: h,
                    onPromptWorkout: () => _promptWorkout(context),
                    onPromptGrocery: () => _promptGrocery(context),
                    onPromptWeight: () => _promptWeight(context),
                    onPromptGoal: () => _promptFitnessGoal(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: PopupMenuButton<String>(
              tooltip: 'Add',
              offset: const Offset(0, -8),
              onSelected: (v) {
                if (v == 'habit') _promptHabit(context);
                if (v == 'workout') _promptWorkout(context);
                if (v == 'grocery') _promptGrocery(context);
                if (v == 'weight') _promptWeight(context);
                if (v == 'goal') _promptFitnessGoal(context);
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'habit', child: Text('Habit')),
                PopupMenuItem(value: 'workout', child: Text('Workout')),
                PopupMenuItem(value: 'grocery', child: Text('Grocery item')),
                PopupMenuItem(value: 'weight', child: Text('Weight')),
                PopupMenuItem(value: 'goal', child: Text('Fitness goal')),
              ],
              child: Material(
                color: cs.primary,
                elevation: 3,
                shadowColor: Colors.black26,
                shape: const CircleBorder(),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.add_rounded, color: cs.onPrimary, size: 28),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _moodNoteDialog(BuildContext context, int level) async {
    final h = context.read<HealthProvider>();
    final note = TextEditingController(text: h.moodFor(_key)?.note ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mood · ${_moodLabels[level]}'),
        content: TextField(
          controller: note,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      h.setMood(_key, level, note.text.trim());
    }
  }

  Future<void> _promptHabit(BuildContext context) async {
    final h = context.read<HealthProvider>();
    final title = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        var color = 0xFF2196F3;
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('New habit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    (0xFF2196F3, Colors.blue),
                    (0xFF4CAF50, Colors.green),
                    (0xFF9C27B0, Colors.purple),
                    (0xFFFF9800, Colors.orange),
                    (0xFF009688, Colors.teal),
                    (0xFFE91E63, Colors.pink),
                  ].map((pair) {
                    final (argb, c) = pair;
                    final sel = color == argb;
                    return GestureDetector(
                      onTap: () => setSt(() => color = argb),
                      child: CircleAvatar(
                        backgroundColor: c,
                        radius: 16,
                        child: sel
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (title.text.trim().isNotEmpty) {
                    h.addHabit(title.text.trim(), color);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptWorkout(BuildContext context) async {
    final h = context.read<HealthProvider>();
    final title = TextEditingController();
    final dur = TextEditingController(text: '30');
    final notes = TextEditingController();
    DateTime d = _today;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log workout',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'What did you do?'),
              ),
              TextField(
                controller: dur,
                decoration: const InputDecoration(labelText: 'Minutes'),
                keyboardType: TextInputType.number,
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat('MMM d, y').format(d)),
                trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: d,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setSt(() => d = picked);
                },
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final dm = int.tryParse(dur.text) ?? 0;
                  if (title.text.trim().isEmpty) return;
                  h.addWorkout(title.text.trim(), d, dm, notes: notes.text.trim());
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptGrocery(BuildContext context) async {
    final h = context.read<HealthProvider>();
    final t = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grocery item'),
        content: TextField(
          controller: t,
          decoration: const InputDecoration(labelText: 'Item'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (t.text.trim().isNotEmpty) {
                h.addGrocery(t.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _promptWeight(BuildContext context) async {
    final h = context.read<HealthProvider>();
    final w = TextEditingController();
    DateTime d = DateTime.now();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log weight',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: w,
                decoration: const InputDecoration(labelText: 'kg'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(DateFormat('MMM d, y').format(d)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: d,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setSt(() => d = picked);
                },
              ),
              FilledButton(
                onPressed: () {
                  final kg = double.tryParse(w.text.replaceAll(',', '')) ?? 0;
                  if (kg <= 0) return;
                  h.addWeight(d, kg);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptFitnessGoal(BuildContext context) async {
    final h = context.read<HealthProvider>();
    final title = TextEditingController();
    final target = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fitness goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: target,
              decoration: const InputDecoration(labelText: 'Target weight (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            Text(
              'Start weight uses your latest log if any.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final tg = double.tryParse(target.text.replaceAll(',', '')) ?? 0;
              if (title.text.trim().isEmpty || tg <= 0) return;
              h.addFitnessGoal(title.text.trim(), tg);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteHabit(BuildContext context, Habit habit) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('Remove "${habit.title}" and its history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<HealthProvider>().deleteHabit(habit.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({
    required this.dateKey,
    required this.day,
    required this.health,
    required this.onMoodNote,
    required this.onDeleteHabit,
  });

  final String dateKey;
  final DateTime day;
  final HealthProvider health;
  final Future<void> Function(int level) onMoodNote;
  final void Function(Habit habit) onDeleteHabit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      children: [
        _SectionLabel(
          icon: Icons.check_circle_outline_rounded,
          label: 'Habits',
          subtitle: 'Tap to complete today',
        ),
        const SizedBox(height: 6),
        if (health.habits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No habits — use + to add one.',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else
          ...health.habits.map((habit) {
            return _HabitRow(
              habit: habit,
              dateKey: dateKey,
              streak: health.streakForHabit(habit.id, day),
              done: health.isHabitDone(habit.id, dateKey),
              onToggle: () => health.toggleHabitDay(habit.id, dateKey),
              onDelete: () => onDeleteHabit(habit),
            );
          }),
        const SizedBox(height: 14),
        _SectionLabel(icon: Icons.mood_rounded, label: 'Mood'),
        const SizedBox(height: 6),
        _MoodRow(
          current: health.moodFor(dateKey)?.moodLevel,
          onPick: onMoodNote,
        ),
        if (health.moodFor(dateKey)?.note.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text(
            health.moodFor(dateKey)!.note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ],
        const SizedBox(height: 14),
        _SectionLabel(icon: Icons.water_drop_outlined, label: 'Water'),
        const SizedBox(height: 6),
        _WaterBlock(dateKey: dateKey, health: health),
        const SizedBox(height: 14),
        _SectionLabel(icon: Icons.bedtime_outlined, label: 'Sleep'),
        const SizedBox(height: 6),
        _SleepBlock(dateKey: dateKey, health: health),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({
    required this.health,
    required this.onPromptWorkout,
    required this.onPromptGrocery,
    required this.onPromptWeight,
    required this.onPromptGoal,
  });

  final HealthProvider health;
  final VoidCallback onPromptWorkout;
  final VoidCallback onPromptGrocery;
  final VoidCallback onPromptWeight;
  final VoidCallback onPromptGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Workouts',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: onPromptWorkout,
              child: const Text('Add'),
            ),
          ],
        ),
        if (health.workouts.isEmpty)
          Text(
            'No workouts logged.',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          )
        else
          ...health.workouts.take(20).map(
                (w) => _PlainRow(
                  title: w.title,
                  subtitle: '${DateFormat('MMM d').format(w.date)} · ${w.durationMinutes} min',
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: () => health.deleteWorkout(w.id),
                  ),
                ),
              ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Grocery',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: onPromptGrocery,
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: health.clearCheckedGroceries,
              child: const Text('Clear done'),
            ),
          ],
        ),
        if (health.groceryItems.isEmpty)
          Text(
            'Nothing on the list.',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          )
        else
          ...health.groceryItems.map(
            (g) => CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: g.isChecked,
              onChanged: (_) => health.toggleGrocery(g.id),
              title: Text(
                g.title,
                style: TextStyle(
                  decoration: g.isChecked ? TextDecoration.lineThrough : null,
                  color: g.isChecked ? cs.onSurfaceVariant : null,
                ),
              ),
              secondary: IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => health.deleteGrocery(g.id),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Weight & goals',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(onPressed: onPromptWeight, child: const Text('Weight')),
            TextButton(onPressed: onPromptGoal, child: const Text('Goal')),
          ],
        ),
        if (health.latestWeightKg != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Latest: ${health.latestWeightKg!.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        if (health.fitnessGoals.isEmpty)
          Text(
            'Add a goal to track progress.',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          )
        else
          ...health.fitnessGoals.map((g) {
            final current = health.latestWeightKg;
            final p = g.progressToward(current);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            onPressed: () => health.deleteFitnessGoal(g.id),
                          ),
                        ],
                      ),
                      Text(
                        'Target ${g.targetWeightKg.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (g.startWeightKg != null)
                        Text(
                          'Started ${g.startWeightKg!.toStringAsFixed(1)} kg',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: p,
                          minHeight: 6,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current != null
                            ? '${(p * 100).toStringAsFixed(0)}% · now ${current.toStringAsFixed(1)} kg'
                            : 'Log weight to track',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        if (health.weightEntries.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Recent weigh-ins',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
          ...health.weightEntries.take(5).map(
                (e) => _PlainRow(
                  title: '${e.weightKg.toStringAsFixed(1)} kg',
                  subtitle: DateFormat('MMM d, y').format(e.date),
                  trailing: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    onPressed: () => health.deleteWeight(e.id),
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary.withValues(alpha: 0.9)),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _PlainRow extends StatelessWidget {
  const _PlainRow({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ? trailing,
            ],
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.28)),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.dateKey,
    required this.streak,
    required this.done,
    required this.onToggle,
    required this.onDelete,
  });

  final Habit habit;
  final String dateKey;
  final int streak;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = Color(habit.colorValue);
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? color.withValues(alpha: 0.35)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                      border: Border.all(
                        color: done ? color : cs.outlineVariant.withValues(alpha: 0.4),
                        width: 1.25,
                      ),
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : null,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$streak-day streak',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline_rounded, size: 20, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.28)),
      ],
    );
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.current,
    required this.onPick,
  });

  final int? current;
  final Future<void> Function(int level) onPick;

  static const _icons = [
    Icons.sentiment_very_dissatisfied_rounded,
    Icons.sentiment_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_satisfied_rounded,
    Icons.sentiment_very_satisfied_rounded,
  ];

  static const _colors = [
    Color(0xFFE57373),
    Color(0xFFFFB74D),
    Color(0xFF90A4AE),
    Color(0xFF81C784),
    Color(0xFF4CAF50),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (i) {
        final sel = current == i;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: sel ? cs.primaryContainer.withValues(alpha: 0.45) : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => onPick(i),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Icon(
                    _icons[i],
                    size: 26,
                    color: sel ? cs.primary : _colors[i],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SleepBlock extends StatefulWidget {
  const _SleepBlock({required this.dateKey, required this.health});

  final String dateKey;
  final HealthProvider health;

  @override
  State<_SleepBlock> createState() => _SleepBlockState();
}

class _SleepBlockState extends State<_SleepBlock> {
  late TextEditingController _hours;
  late int? _quality;

  @override
  void initState() {
    super.initState();
    final existing = widget.health.sleepFor(widget.dateKey);
    _hours = TextEditingController(
      text: existing != null ? existing.hoursSlept.toStringAsFixed(1) : '',
    );
    _quality = existing?.quality;
  }

  @override
  void didUpdateWidget(covariant _SleepBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateKey != widget.dateKey) {
      _hours.dispose();
      final existing = widget.health.sleepFor(widget.dateKey);
      _hours = TextEditingController(
        text: existing != null ? existing.hoursSlept.toStringAsFixed(1) : '',
      );
      _quality = existing?.quality;
    }
  }

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _hours,
              decoration: const InputDecoration(
                labelText: 'Hours',
                hintText: 'e.g. 7.5',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 6),
            Text(
              'Quality (optional)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(5, (i) {
                final v = i + 1;
                final sel = _quality == v;
                return FilterChip(
                  label: Text('$v'),
                  selected: sel,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _quality = sel ? null : v),
                );
              }),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                final h = double.tryParse(_hours.text.replaceAll(',', '')) ?? 0;
                if (h <= 0 || h > 24) return;
                widget.health.setSleep(widget.dateKey, h, quality: _quality);
              },
              child: const Text('Save sleep'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterBlock extends StatelessWidget {
  const _WaterBlock({required this.dateKey, required this.health});

  final String dateKey;
  final HealthProvider health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = health.waterTotalMl(dateKey);
    final goal = HealthProvider.defaultWaterGoalMl;
    final p = goal > 0 ? (total / goal).clamp(0.0, 1.0) : 0.0;

    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$total',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  ' / $goal ml',
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final c = TextEditingController(text: total.toString());
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Set total (ml)'),
                        content: TextField(
                          controller: c,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Set'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      final v = int.tryParse(c.text) ?? 0;
                      health.setWaterMl(dateKey, v);
                    }
                  },
                  child: const Text('Set'),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => health.addWaterMl(dateKey, HealthProvider.waterGlassMl),
                    child: Text('+${HealthProvider.waterGlassMl} ml'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => health.addWaterMl(dateKey, 500),
                    child: const Text('+500 ml'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
