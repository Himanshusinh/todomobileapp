import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/bucket_item.dart';
import 'package:todoapp/models/goal_item.dart';
import 'package:todoapp/models/kanban_item.dart';
import 'package:todoapp/models/milestone_item.dart';
import 'package:todoapp/models/okr_key_result.dart';
import 'package:todoapp/models/okr_objective.dart';
import 'package:todoapp/models/vision_item.dart';
import 'package:todoapp/providers/goals_provider.dart';

/// Dialog routes can rebuild for one more frame after [showDialog]'s future
/// completes; disposing controllers immediately triggers "used after disposed".
void _disposeControllersAfterDialog(List<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final c in controllers) {
      c.dispose();
    }
  });
}

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _selectedBoardId;
  int _mainTab = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(_onTab);
  }

  void _onTab() {
    if (_tabs.indexIsChanging) return;
    setState(() => _mainTab = _tabs.index);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTab);
    _tabs.dispose();
    super.dispose();
  }

  void _ensureBoard(GoalsProvider p) {
    if (_selectedBoardId == null && p.boards.isNotEmpty) {
      _selectedBoardId = p.boards.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, goals, _) {
        _ensureBoard(goals);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: TabBar(
                    controller: _tabs,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Goals'),
                      Tab(text: 'Boards'),
                      Tab(text: 'OKRs'),
                      Tab(text: 'Vision & Bucket'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _GoalsTab(onAddMilestone: _showMilestoneDialog),
                      _BoardsTab(
                        selectedBoardId: _selectedBoardId,
                        onSelectBoard: (id) =>
                            setState(() => _selectedBoardId = id),
                      ),
                      const _OkrsTab(),
                      const _VisionBucketTab(),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: _buildFab(context, goals),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFab(BuildContext context, GoalsProvider goals) {
    switch (_mainTab) {
      case 0:
        return FloatingActionButton(
          heroTag: 'fab_goals_milestones',
          onPressed: () => _showGoalDialog(context),
          child: const Icon(Icons.flag),
        );
      case 1:
        return FloatingActionButton(
          heroTag: 'fab_goals_kanban',
          onPressed: _selectedBoardId == null
              ? null
              : () => _showKanbanDialog(context, _selectedBoardId!),
          child: const Icon(Icons.add_card),
        );
      case 2:
        return FloatingActionButton(
          heroTag: 'fab_goals_okrs',
          onPressed: () => _showObjectiveDialog(context),
          child: const Icon(Icons.track_changes),
        );
      case 3:
        return FloatingActionButton(
          heroTag: 'fab_goals_vision',
          onPressed: () => _showVisionBucketMenu(context),
          child: const Icon(Icons.add),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showVisionBucketMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Add vision card'),
              onTap: () {
                Navigator.pop(ctx);
                _showVisionDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sailing),
              title: const Text('Add bucket list item'),
              onTap: () {
                Navigator.pop(ctx);
                _showBucketDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGoalDialog(BuildContext context) async {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    var timeframe = 1;
    var year = DateTime.now().year;
    int? month = DateTime.now().month;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descC,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Monthly')),
                    ButtonSegment(value: 1, label: Text('Yearly')),
                  ],
                  selected: {timeframe},
                  onSelectionChanged: (s) =>
                      setLocal(() => timeframe = s.first),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text('Year: $year'),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final y = await showDialog<int>(
                      context: ctx,
                      builder: (d) => SimpleDialog(
                        title: const Text('Target year'),
                        children: List.generate(5, (i) {
                          final yy = DateTime.now().year + i;
                          return SimpleDialogOption(
                            onPressed: () => Navigator.pop(d, yy),
                            child: Text('$yy'),
                          );
                        }),
                      ),
                    );
                    if (y != null) setLocal(() => year = y);
                  },
                ),
                if (timeframe == 0)
                  ListTile(
                    title: Text('Month: $month'),
                    trailing: const Icon(Icons.date_range),
                    onTap: () async {
                      final m = await showDialog<int>(
                        context: ctx,
                        builder: (d) => SimpleDialog(
                          title: const Text('Month'),
                          children: List.generate(12, (i) {
                            final mm = i + 1;
                            return SimpleDialogOption(
                              onPressed: () => Navigator.pop(d, mm),
                              child: Text(DateFormat.MMMM().format(
                                DateTime(2000, mm),
                              )),
                            );
                          }),
                        ),
                      );
                      if (m != null) setLocal(() => month = m);
                    },
                  ),
              ],
            ),
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
      ),
    );

    if (ok == true && titleC.text.trim().isNotEmpty && context.mounted) {
      context.read<GoalsProvider>().addGoal(
            title: titleC.text.trim(),
            description: descC.text.trim(),
            timeframe: timeframe,
            targetYear: year,
            targetMonth: timeframe == 0 ? month : null,
          );
    }
    _disposeControllersAfterDialog([titleC, descC]);
  }

  Future<void> _showMilestoneDialog(BuildContext context, String goalId) async {
    final titleC = TextEditingController();
    DateTime? due;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New milestone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              ListTile(
                title: Text(
                  due == null
                      ? 'Due date (optional)'
                      : DateFormat.yMMMd().format(due!),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.event),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: due ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setLocal(() => due = d);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && titleC.text.trim().isNotEmpty && context.mounted) {
      context.read<GoalsProvider>().addMilestone(
            goalId: goalId,
            title: titleC.text.trim(),
            dueDate: due,
          );
    }
    _disposeControllersAfterDialog([titleC]);
  }

  Future<void> _showKanbanDialog(BuildContext context, String boardId) async {
    final titleC = TextEditingController();
    final notesC = TextEditingController();
    var col = 0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('New card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: notesC,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                key: ValueKey(col),
                initialValue: col,
                decoration: const InputDecoration(labelText: 'Column'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('To Do')),
                  DropdownMenuItem(value: 1, child: Text('In Progress')),
                  DropdownMenuItem(value: 2, child: Text('Done')),
                ],
                onChanged: (v) => setLocal(() => col = v ?? 0),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && titleC.text.trim().isNotEmpty && context.mounted) {
      context.read<GoalsProvider>().addKanbanItem(
            boardId: boardId,
            title: titleC.text.trim(),
            notes: notesC.text.trim(),
            column: col,
          );
    }
    _disposeControllersAfterDialog([titleC, notesC]);
  }

  Future<void> _showObjectiveDialog(BuildContext context) async {
    final titleC = TextEditingController();
    final periodC = TextEditingController(
      text: '${DateTime.now().year} Q${((DateTime.now().month - 1) ~/ 3) + 1}',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New objective'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleC,
              decoration: const InputDecoration(labelText: 'Objective'),
            ),
            TextField(
              controller: periodC,
              decoration: const InputDecoration(
                labelText: 'Period (e.g. 2026 Q1)',
              ),
            ),
          ],
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

    if (ok == true && titleC.text.trim().isNotEmpty && context.mounted) {
      context.read<GoalsProvider>().addOkrObjective(
            title: titleC.text.trim(),
            period: periodC.text.trim(),
          );
    }
    _disposeControllersAfterDialog([titleC, periodC]);
  }

  Future<void> _showVisionDialog(BuildContext context) async {
    final titleC = TextEditingController();
    final capC = TextEditingController();
    String? path;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Vision card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: capC,
                  decoration: const InputDecoration(labelText: 'Caption'),
                  maxLines: 3,
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final x = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                    );
                    if (x != null) setLocal(() => path = x.path);
                  },
                  icon: const Icon(Icons.image),
                  label: Text(path == null ? 'Add image' : 'Image selected'),
                ),
              ],
            ),
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
      ),
    );

    if (ok == true && titleC.text.trim().isNotEmpty && context.mounted) {
      context.read<GoalsProvider>().addVisionItem(
            title: titleC.text.trim(),
            caption: capC.text.trim(),
            imagePath: path,
          );
    }
    _disposeControllersAfterDialog([titleC, capC]);
  }

  Future<void> _showBucketDialog(BuildContext context) async {
    final titleC = TextEditingController();
    final notesC = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bucket list'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleC,
              decoration: const InputDecoration(labelText: 'Dream / place / skill'),
            ),
            TextField(
              controller: notesC,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true && titleC.text.trim().isNotEmpty && context.mounted) {
      context.read<GoalsProvider>().addBucketItem(
            title: titleC.text.trim(),
            notes: notesC.text.trim(),
          );
    }
    _disposeControllersAfterDialog([titleC, notesC]);
  }
}

// —— Tab: Goals ——

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({required this.onAddMilestone});

  final void Function(BuildContext context, String goalId) onAddMilestone;

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, p, _) {
        final list = p.goals;
        if (list.isEmpty) {
          return Center(
            child: Text(
              'Set monthly or yearly goals.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final g = list[i];
            return _GoalCard(
              goal: g,
              onAddMilestone: () => onAddMilestone(context, g.id),
            );
          },
        );
      },
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onAddMilestone,
  });

  final GoalItem goal;
  final VoidCallback onAddMilestone;

  String _subtitle(GoalItem g) {
    final tf = g.timeframe == 0 ? 'Monthly' : 'Yearly';
    if (g.timeframe == 0 && g.targetMonth != null) {
      final m = DateFormat.MMMM().format(DateTime(2000, g.targetMonth!));
      return '$tf · $m ${g.targetYear}';
    }
    return '$tf · ${g.targetYear}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GoalsProvider>();
    final ms = p.milestonesForGoal(goal.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(goal.title),
        subtitle: Text(_subtitle(goal)),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (goal.description.isNotEmpty)
                  Text(
                    goal.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('${goal.progressPercent}%'),
                    Expanded(
                      child: Slider(
                        value: goal.progressPercent.toDouble(),
                        max: 100,
                        divisions: 20,
                        label: '${goal.progressPercent}%',
                        onChanged: (v) {
                          goal.progressPercent = v.round();
                          p.updateGoal(goal);
                        },
                      ),
                    ),
                  ],
                ),
                LinearProgressIndicator(
                  value: goal.progressPercent / 100,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Milestones',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onAddMilestone,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                    IconButton(
                      tooltip: 'Delete goal',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete goal?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true && context.mounted) {
                          p.deleteGoal(goal.id);
                        }
                      },
                    ),
                  ],
                ),
                ...ms.map((m) => _MilestoneTile(milestone: m)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone});

  final MilestoneItem milestone;

  @override
  Widget build(BuildContext context) {
    final p = context.read<GoalsProvider>();
    return ListTile(
      dense: true,
      title: Text(milestone.title),
      subtitle: Text(
        milestone.dueDate != null
            ? DateFormat.yMMMd().format(milestone.dueDate!)
            : 'No due date',
      ),
      leading: Checkbox(
        value: milestone.isCompleted,
        onChanged: (v) {
          milestone.isCompleted = v ?? false;
          if (milestone.isCompleted) milestone.progressPercent = 100;
          p.updateMilestone(milestone);
        },
      ),
      trailing: SizedBox(
        width: 120,
        child: Slider(
          value: milestone.progressPercent.toDouble(),
          max: 100,
          divisions: 10,
          label: '${milestone.progressPercent}%',
          onChanged: milestone.isCompleted
              ? null
              : (v) {
                  milestone.progressPercent = v.round();
                  p.updateMilestone(milestone);
                },
        ),
      ),
      onLongPress: () => p.deleteMilestone(milestone.id),
    );
  }
}

// —— Tab: Kanban ——

class _BoardsTab extends StatelessWidget {
  const _BoardsTab({
    required this.selectedBoardId,
    required this.onSelectBoard,
  });

  final String? selectedBoardId;
  final ValueChanged<String> onSelectBoard;

  static const _cols = ['To Do', 'In Progress', 'Done'];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GoalsProvider>();
    final boards = p.boards;
    if (boards.isEmpty) {
      return const Center(child: Text('No boards'));
    }
    final bid = selectedBoardId ?? boards.first.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(bid),
                  initialValue: bid,
                  decoration: const InputDecoration(
                    labelText: 'Project board',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: boards
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.title),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onSelectBoard(v);
                  },
                ),
              ),
              IconButton(
                tooltip: 'New board',
                onPressed: () => _newBoard(context),
                icon: const Icon(Icons.add_box_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(3, (col) {
              final items = p.itemsForBoard(bid, col);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          _cols[col],
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final k = items[i];
                            return _KanbanCard(item: k);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _newBoard(BuildContext context) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New board'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty && context.mounted) {
      context.read<GoalsProvider>().addBoard(c.text.trim());
    }
    _disposeControllersAfterDialog([c]);
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({required this.item});

  final KanbanItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.read<GoalsProvider>();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        title: Text(item.title),
        subtitle: item.notes.isEmpty ? null : Text(item.notes, maxLines: 2),
        isThreeLine: item.notes.isNotEmpty,
        trailing: PopupMenuButton<int>(
          onSelected: (col) => p.moveKanbanItem(item.id, col),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 0, child: Text('To Do')),
            PopupMenuItem(value: 1, child: Text('In Progress')),
            PopupMenuItem(value: 2, child: Text('Done')),
          ],
          child: const Icon(Icons.more_vert),
        ),
        onLongPress: () => p.deleteKanbanItem(item.id),
      ),
    );
  }
}

// —— Tab: OKRs ——

class _OkrsTab extends StatelessWidget {
  const _OkrsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, p, _) {
        final objs = p.okrObjectives;
        if (objs.isEmpty) {
          return Center(
            child: Text(
              'Add objectives and measurable key results.\nUse the + button.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: objs.length,
          itemBuilder: (context, i) {
            final o = objs[i];
            return _ObjectiveCard(objective: o);
          },
        );
      },
    );
  }
}

class _ObjectiveCard extends StatelessWidget {
  const _ObjectiveCard({required this.objective});

  final OkrObjective objective;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GoalsProvider>();
    final krs = p.keyResultsFor(objective.id);
    final prog = p.objectiveProgress(objective.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(objective.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (objective.periodLabel.isNotEmpty)
              Text(objective.periodLabel),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: prog),
            Text('${(prog * 100).round()}% from key results'),
          ],
        ),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _addKr(context, objective.id),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Key result'),
            ),
          ),
          ...krs.map((kr) => _KrTile(kr: kr)),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete objective'),
            onTap: () => p.deleteOkrObjective(objective.id),
          ),
        ],
      ),
    );
  }

  Future<void> _addKr(BuildContext context, String oid) async {
    final titleC = TextEditingController();
    final targetC = TextEditingController(text: '100');
    final currentC = TextEditingController(text: '0');
    final unitC = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Key result'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: currentC,
                decoration: const InputDecoration(labelText: 'Current'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: targetC,
                decoration: const InputDecoration(labelText: 'Target'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: unitC,
                decoration: const InputDecoration(
                  labelText: 'Unit (optional, e.g. %, users)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true &&
        titleC.text.trim().isNotEmpty &&
        context.mounted) {
      final t = double.tryParse(targetC.text) ?? 100;
      final c = double.tryParse(currentC.text) ?? 0;
      context.read<GoalsProvider>().addKeyResult(
            objectiveId: oid,
            title: titleC.text.trim(),
            target: t,
            current: c,
            unit: unitC.text.trim(),
          );
    }
    _disposeControllersAfterDialog([titleC, targetC, currentC, unitC]);
  }
}

class _KrTile extends StatelessWidget {
  const _KrTile({required this.kr});

  final OkrKeyResult kr;

  @override
  Widget build(BuildContext context) {
    final p = context.read<GoalsProvider>();
    final unit = kr.unit.isEmpty ? '' : ' ${kr.unit}';
    return ListTile(
      title: Text(kr.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${kr.current.toStringAsFixed(1)} / ${kr.target.toStringAsFixed(1)}$unit',
          ),
          Slider(
            value: kr.progress.clamp(0.0, 1.0),
            onChanged: (v) {
              kr.current = (v * kr.target).clamp(0.0, kr.target);
              p.updateKeyResult(kr);
            },
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => p.deleteKeyResult(kr.id),
      ),
    );
  }
}

// —— Tab: Vision + Bucket ——

class _VisionBucketTab extends StatelessWidget {
  const _VisionBucketTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<GoalsProvider>(
      builder: (context, p, _) {
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Text(
              'Vision board',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (p.visionItems.isEmpty)
              Text(
                'No cards yet — tap + → vision card.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: p.visionItems.length,
                  separatorBuilder: (context, _) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final v = p.visionItems[i];
                    return _VisionCard(item: v);
                  },
                ),
              ),
            const SizedBox(height: 24),
            Text(
              'Bucket list',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...p.bucketItems.map((b) => _BucketTile(item: b)),
          ],
        );
      },
    );
  }
}

class _VisionCard extends StatelessWidget {
  const _VisionCard({required this.item});

  final VisionItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.read<GoalsProvider>();
    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onLongPress: () => p.deleteVisionItem(item.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: item.imagePath != null &&
                        File(item.imagePath!).existsSync()
                    ? Image.file(
                        File(item.imagePath!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.auto_awesome,
                          size: 48,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (item.caption.isNotEmpty)
                      Text(
                        item.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BucketTile extends StatelessWidget {
  const _BucketTile({required this.item});

  final BucketItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.read<GoalsProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: item.isDone,
        onChanged: (_) => p.toggleBucketDone(item.id),
        title: Text(
          item.title,
          style: item.isDone
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        subtitle: item.notes.isEmpty ? null : Text(item.notes),
        secondary: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => p.deleteBucketItem(item.id),
        ),
      ),
    );
  }
}
