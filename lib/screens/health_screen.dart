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

class _HealthScreenState extends State<HealthScreen> {
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _day = DateTime(n.year, n.month, n.day);
  }

  String get _key => HealthProvider.dateKey(_day);

  void _shiftDay(int delta) {
    setState(() {
      _day = _day.add(Duration(days: delta));
    });
  }

  static const _moodLabels = ['Rough', 'Low', 'Okay', 'Good', 'Great'];
  static const _mealLabels = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  Widget build(BuildContext context) {
    final h = context.watch<HealthProvider>();
    final theme = Theme.of(context);

    final appBarBg =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: appBarBg,
          elevation: 0,
          child: SafeArea(
            top: false,
            bottom: false,
            child: AppBar(
              primary: false,
              toolbarHeight: 48,
              automaticallyImplyLeading: false,
              title: const Text('Health & Habits'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.today_outlined),
                  tooltip: 'Today',
                  onPressed: () {
                    final n = DateTime.now();
                    setState(() => _day = DateTime(n.year, n.month, n.day));
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'habit') _promptHabit(context);
                    if (v == 'workout') _promptWorkout(context);
                    if (v == 'grocery') _promptGrocery(context);
                    if (v == 'weight') _promptWeight(context);
                    if (v == 'goal') _promptFitnessGoal(context);
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'habit', child: Text('New habit')),
                    PopupMenuItem(value: 'workout', child: Text('Log workout')),
                    PopupMenuItem(value: 'grocery', child: Text('Add grocery item')),
                    PopupMenuItem(value: 'weight', child: Text('Log weight')),
                    PopupMenuItem(value: 'goal', child: Text('Fitness goal')),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          _DateStrip(day: _day, onPrev: () => _shiftDay(-1), onNext: () => _shiftDay(1)),
          const SizedBox(height: 20),
          Text('Daily habits', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Tap to mark ${_key == h.todayKey ? 'today' : 'this day'}. Streak counts up to today.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (h.habits.isEmpty)
            const Text('No habits yet.')
          else
            ...h.habits.map((habit) => _HabitRow(
                  habit: habit,
                  dateKey: _key,
                  streak: h.streakForHabit(habit.id, _day),
                  done: h.isHabitDone(habit.id, _key),
                  onToggle: () => h.toggleHabitDay(habit.id, _key),
                  onDelete: () => _confirmDeleteHabit(context, habit),
                )),
          const SizedBox(height: 24),
          Text('Mood', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _MoodRow(
            dateKey: _key,
            current: h.moodFor(_key)?.moodLevel,
            onPick: (level) => _moodNoteDialog(context, level),
          ),
          if (h.moodFor(_key)?.note.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(h.moodFor(_key)!.note, style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 24),
          Text('Water', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _WaterCard(dateKey: _key, health: h),
          const SizedBox(height: 24),
          Text('Sleep', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SleepCard(dateKey: _key, health: h),
          const SizedBox(height: 24),
          Text('Meals', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(
            4,
            (i) => _MealSlotRow(
              key: ValueKey('${_key}_meal_$i'),
              dateKey: _key,
              mealType: i,
              label: _mealLabels[i],
              health: h,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Workouts',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () => _promptWorkout(context),
                child: const Text('Log'),
              ),
            ],
          ),
          if (h.workouts.isEmpty)
            Text('No workouts yet.', style: theme.textTheme.bodySmall)
          else
            ...h.workouts.take(12).map((w) => Card(
                  child: ListTile(
                    title: Text(w.title),
                    subtitle: Text(
                      '${DateFormat('MMM d').format(w.date)} · ${w.durationMinutes} min',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => h.deleteWorkout(w.id),
                    ),
                  ),
                )),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Grocery list',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  h.clearCheckedGroceries();
                },
                child: const Text('Clear done'),
              ),
            ],
          ),
          if (h.groceryItems.isEmpty)
            Text('Add items you need from the menu.', style: theme.textTheme.bodySmall)
          else
            ...h.groceryItems.map(
              (g) => CheckboxListTile(
                value: g.isChecked,
                onChanged: (_) => h.toggleGrocery(g.id),
                title: Text(
                  g.title,
                  style: TextStyle(
                    decoration: g.isChecked ? TextDecoration.lineThrough : null,
                    color: g.isChecked ? theme.hintColor : null,
                  ),
                ),
                secondary: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => h.deleteGrocery(g.id),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('Weight & fitness goals', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (h.latestWeightKg != null)
            Text(
              'Latest: ${h.latestWeightKg!.toStringAsFixed(1)} kg',
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _promptWeight(context),
                icon: const Icon(Icons.monitor_weight_outlined),
                label: const Text('Log weight'),
              ),
              TextButton.icon(
                onPressed: () => _promptFitnessGoal(context),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Add goal'),
              ),
            ],
          ),
          if (h.fitnessGoals.isEmpty)
            Text('Set a target weight to see progress.', style: theme.textTheme.bodySmall)
          else
            ...h.fitnessGoals.map((g) {
              final current = h.latestWeightKg;
              final p = g.progressToward(current);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(g.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => h.deleteFitnessGoal(g.id),
                          ),
                        ],
                      ),
                      Text('Target: ${g.targetWeightKg.toStringAsFixed(1)} kg'),
                      if (g.startWeightKg != null)
                        Text('Started: ${g.startWeightKg!.toStringAsFixed(1)} kg'),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(value: p, minHeight: 8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        current != null
                            ? 'Progress: ${(p * 100).toStringAsFixed(0)}%  (now ${current.toStringAsFixed(1)} kg)'
                            : 'Log weight to track progress',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (h.weightEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Recent weigh-ins', style: theme.textTheme.labelLarge),
            ...h.weightEntries.take(5).map(
                  (e) => ListTile(
                    dense: true,
                    title: Text('${e.weightKg.toStringAsFixed(1)} kg'),
                    subtitle: Text(DateFormat('MMM d, y').format(e.date)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => h.deleteWeight(e.id),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 24),
            ],
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
        title: Text('Mood: ${_moodLabels[level]}'),
        content: TextField(
          controller: note,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
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
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
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
                        radius: 18,
                        child: sel ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
    DateTime d = _day;
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
              const Text('Log workout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'What did you do?')),
              TextField(
                controller: dur,
                decoration: const InputDecoration(labelText: 'Minutes'),
                keyboardType: TextInputType.number,
              ),
              ListTile(
                title: Text(DateFormat('MMM d, y').format(d)),
                trailing: const Icon(Icons.calendar_today),
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
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes')),
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
          decoration: const InputDecoration(labelText: 'Item', border: OutlineInputBorder()),
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
              const Text('Log weight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(
                controller: w,
                decoration: const InputDecoration(labelText: 'kg', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              ListTile(
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
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(
              controller: target,
              decoration: const InputDecoration(labelText: 'Target weight (kg)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            Text(
              'Start weight defaults to your latest log if any.',
              style: Theme.of(ctx).textTheme.bodySmall,
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

class _DateStrip extends StatelessWidget {
  final DateTime day;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DateStrip({
    required this.day,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text(
            DateFormat('EEEE, MMM d').format(day),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final String dateKey;
  final int streak;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HabitRow({
    required this.habit,
    required this.dateKey,
    required this.streak,
    required this.done,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(habit.colorValue);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(Icons.check, color: color),
        ),
        title: Text(habit.title),
        subtitle: Text('Streak: $streak day${streak == 1 ? '' : 's'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
            Checkbox(value: done, onChanged: (_) => onToggle()),
          ],
        ),
        onTap: onToggle,
      ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  final String dateKey;
  final int? current;
  final ValueChanged<int> onPick;

  const _MoodRow({
    required this.dateKey,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    const moodIcons = [
      Icons.sentiment_very_dissatisfied_rounded,
      Icons.sentiment_dissatisfied_rounded,
      Icons.sentiment_neutral_rounded,
      Icons.sentiment_satisfied_rounded,
      Icons.sentiment_very_satisfied_rounded,
    ];
    const moodColors = [
      Color(0xFFE57373),
      Color(0xFFFFB74D),
      Color(0xFF90A4AE),
      Color(0xFF81C784),
      Color(0xFF4CAF50),
    ];
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 8,
      runSpacing: 8,
      children: List.generate(5, (i) {
        final sel = current == i;
        return InkWell(
          onTap: () => onPick(i),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sel ? Theme.of(context).colorScheme.primaryContainer : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sel ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              moodIcons[i],
              size: 30,
              color: sel ? Theme.of(context).colorScheme.primary : moodColors[i],
            ),
          ),
        );
      }),
    );
  }
}

class _SleepCard extends StatefulWidget {
  final String dateKey;
  final HealthProvider health;

  const _SleepCard({required this.dateKey, required this.health});

  @override
  State<_SleepCard> createState() => _SleepCardState();
}

class _SleepCardState extends State<_SleepCard> {
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
  void didUpdateWidget(covariant _SleepCard oldWidget) {
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _hours,
              decoration: const InputDecoration(
                labelText: 'Hours slept',
                border: OutlineInputBorder(),
                hintText: 'e.g. 7.5',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Text('Sleep quality (optional)', style: Theme.of(context).textTheme.labelMedium),
            Row(
              children: List.generate(5, (i) {
                final v = i + 1;
                final sel = _quality == v;
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: ChoiceChip(
                    label: Text('$v'),
                    selected: sel,
                    onSelected: (_) => setState(() => _quality = sel ? null : v),
                  ),
                );
              }),
            ),
            FilledButton(
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

class _WaterCard extends StatelessWidget {
  final String dateKey;
  final HealthProvider health;

  const _WaterCard({required this.dateKey, required this.health});

  @override
  Widget build(BuildContext context) {
    final total = health.waterTotalMl(dateKey);
    final goal = HealthProvider.defaultWaterGoalMl;
    final p = goal > 0 ? (total / goal).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$total / $goal ml'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: p, minHeight: 10),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => health.addWaterMl(dateKey, HealthProvider.waterGlassMl),
                  child: Text('+${HealthProvider.waterGlassMl} ml (glass)'),
                ),
                OutlinedButton(
                  onPressed: () => health.addWaterMl(dateKey, 500),
                  child: const Text('+500 ml'),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final c = TextEditingController(text: total.toString());
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Set total ml'),
                        content: TextField(
                          controller: c,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Set')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      final v = int.tryParse(c.text) ?? 0;
                      health.setWaterMl(dateKey, v);
                    }
                  },
                  child: const Text('Set total'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MealSlotRow extends StatefulWidget {
  final String dateKey;
  final int mealType;
  final String label;
  final HealthProvider health;

  const _MealSlotRow({
    super.key,
    required this.dateKey,
    required this.mealType,
    required this.label,
    required this.health,
  });

  @override
  State<_MealSlotRow> createState() => _MealSlotRowState();
}

class _MealSlotRowState extends State<_MealSlotRow> {
  late TextEditingController _c;

  String _initialText() {
    final meals = widget.health.mealsFor(widget.dateKey).where((m) => m.mealType == widget.mealType);
    return meals.isEmpty ? '' : meals.first.description;
  }

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: _initialText());
  }

  @override
  void didUpdateWidget(covariant _MealSlotRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateKey != widget.dateKey) {
      _c.dispose();
      _c = TextEditingController(text: _initialText());
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: TextField(
              controller: _c,
              decoration: const InputDecoration(
                hintText: 'Plan…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _save(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  void _save() {
    widget.health.setMeal(widget.dateKey, widget.mealType, _c.text);
    FocusScope.of(context).unfocus();
  }
}
