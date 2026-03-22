import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todoapp/models/bill.dart';
import 'package:todoapp/models/subscription_item.dart';
import 'package:todoapp/providers/finance_provider.dart';
import 'package:todoapp/providers/goals_provider.dart';
import 'package:todoapp/providers/health_provider.dart';
import 'package:todoapp/providers/notes_provider.dart';
import 'package:todoapp/providers/shopping_provider.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/widgets/task_tile.dart';

/// One calendar mode at a time (single-select).
enum CalendarDataLayer {
  tasks,
  finance,
  health,
  goals,
  shopping,
  notes,
}

extension on CalendarDataLayer {
  String get shortLabel => switch (this) {
        CalendarDataLayer.tasks => 'Tasks',
        CalendarDataLayer.finance => 'Finance',
        CalendarDataLayer.health => 'Health',
        CalendarDataLayer.goals => 'Goals',
        CalendarDataLayer.shopping => 'Shop',
        CalendarDataLayer.notes => 'Journal',
      };

  String get detailHint => switch (this) {
        CalendarDataLayer.tasks => 'Tap a day to see tasks due.',
        CalendarDataLayer.finance => 'Tap a day for bills, subs & task spend.',
        CalendarDataLayer.health => 'Tap a day for habits, mood & workouts.',
        CalendarDataLayer.goals => 'Tap a day for milestones & focus goals.',
        CalendarDataLayer.shopping => 'Current shopping snapshot (not dated).',
        CalendarDataLayer.notes => 'Tap a day for journal entries.',
      };
}

/// Marker when the current mode has data on a day.
class CalendarMarker {
  const CalendarMarker();
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// Exactly one mode visible at a time.
  CalendarDataLayer _mode = CalendarDataLayer.tasks;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  static DateTime _dateOnly(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  TextScaler _calendarTextScaler(BuildContext context) {
    return MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.2,
    );
  }

  Color _layerColor(ColorScheme cs, CalendarDataLayer layer) {
    return switch (layer) {
      CalendarDataLayer.tasks => cs.primary,
      CalendarDataLayer.finance => cs.tertiary,
      CalendarDataLayer.health => const Color(0xFF2E7D32),
      CalendarDataLayer.goals => cs.secondary,
      CalendarDataLayer.shopping => const Color(0xFF00838F),
      CalendarDataLayer.notes => cs.tertiary,
    };
  }

  (DateTime start, DateTime end) _visiblePeriod() {
    final f = _focusedDay;
    switch (_calendarFormat) {
      case CalendarFormat.month:
        final start = DateTime(f.year, f.month, 1);
        final end = DateTime(f.year, f.month + 1, 0);
        return (_dateOnly(start), _dateOnly(end));
      case CalendarFormat.week:
        final mondayOffset = f.weekday - DateTime.monday;
        final start = _dateOnly(f.subtract(Duration(days: mondayOffset)));
        final end = start.add(const Duration(days: 6));
        return (start, end);
      case CalendarFormat.twoWeeks:
        final mondayOffset = f.weekday - DateTime.monday;
        final start = _dateOnly(f.subtract(Duration(days: mondayOffset)));
        final end = start.add(const Duration(days: 13));
        return (start, end);
    }
  }

  String _periodTitle(DateTime start, DateTime end) {
    if (_calendarFormat == CalendarFormat.month) {
      return DateFormat.yMMMM().format(start);
    }
    if (_sameDay(start, end)) {
      return DateFormat.yMMMd().format(start);
    }
    return '${DateFormat.MMMd().format(start)} – ${DateFormat.MMMd().format(end)}, ${end.year}';
  }

  Iterable<DateTime> _eachDay(DateTime start, DateTime end) sync* {
    var d = start;
    while (!d.isAfter(end)) {
      yield d;
      d = d.add(const Duration(days: 1));
    }
  }

  bool _dayHasHealthActivity(HealthProvider h, DateTime day) {
    final key = HealthProvider.dateKey(day);
    if (h.moodFor(key) != null) return true;
    if (h.sleepFor(key) != null) return true;
    if (h.mealsFor(key).isNotEmpty) return true;
    if (h.waterTotalMl(key) > 0) return true;
    for (final habit in h.habits) {
      if (h.isHabitDone(habit.id, key)) return true;
    }
    for (final w in h.workouts) {
      if (_sameDay(w.date, day)) return true;
    }
    for (final e in h.weightEntries) {
      if (_sameDay(e.date, day)) return true;
    }
    return false;
  }

  List<Bill> _billsOnDay(FinanceProvider f, DateTime day) {
    return f.bills
        .where((b) => _sameDay(_dateOnly(b.nextDueDate), day))
        .toList();
  }

  List<SubscriptionItem> _subsOnDay(FinanceProvider f, DateTime day) {
    return f.subscriptions
        .where((s) => _sameDay(_dateOnly(s.nextRenewalDate), day))
        .toList();
  }

  double _taskExpenseForDay(TaskProvider tp, DateTime day) {
    var sum = 0.0;
    for (final t in tp.allTasks) {
      if (t.dueDate == null) continue;
      if (!_sameDay(_dateOnly(t.dueDate!), day)) continue;
      final e = t.expenseAmount;
      if (e != null && e > 0) sum += e;
    }
    return sum;
  }

  bool _dayHasFinanceActivity(
    DateTime day,
    TaskProvider tasks,
    FinanceProvider finance,
  ) {
    if (_taskExpenseForDay(tasks, day) > 0) return true;
    if (_billsOnDay(finance, day).isNotEmpty) return true;
    if (_subsOnDay(finance, day).isNotEmpty) return true;
    return false;
  }

  List<CalendarMarker> _markersForDay(
    DateTime day,
    TaskProvider tasks,
    FinanceProvider finance,
    HealthProvider health,
    GoalsProvider goals,
    NotesProvider notes,
  ) {
    switch (_mode) {
      case CalendarDataLayer.tasks:
        if (tasks.getTasksForDay(day).isEmpty) return [];
        return [const CalendarMarker()];
      case CalendarDataLayer.finance:
        if (!_dayHasFinanceActivity(day, tasks, finance)) return [];
        return [const CalendarMarker()];
      case CalendarDataLayer.health:
        if (!_dayHasHealthActivity(health, day)) return [];
        return [const CalendarMarker()];
      case CalendarDataLayer.goals:
        final hasMilestone = goals.allMilestones.any(
          (m) =>
              m.dueDate != null &&
              _sameDay(_dateOnly(m.dueDate!), day) &&
              !m.isCompleted,
        );
        if (!hasMilestone) return [];
        return [const CalendarMarker()];
      case CalendarDataLayer.shopping:
        return [];
      case CalendarDataLayer.notes:
        if (notes.journalForDay(NotesProvider.dateKey(day)).isEmpty) {
          return [];
        }
        return [const CalendarMarker()];
    }
  }

  Widget _buildModeSelector(ThemeData theme, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'Show',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: CalendarDataLayer.values.map((layer) {
              final selected = _mode == layer;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    layer.shortLabel,
                    style: TextStyle(
                      color: selected ? cs.onPrimary : cs.onSurface,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _mode = layer),
                  showCheckmark: false,
                  selectedColor: cs.primary,
                  backgroundColor: cs.surfaceContainerLow,
                  disabledColor: cs.surfaceContainerHighest,
                  side: BorderSide(
                    color: selected
                        ? cs.primary
                        : cs.outline.withValues(alpha: 0.45),
                    width: selected ? 1.5 : 1,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            _mode.detailHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSummary(
    BuildContext context,
    TaskProvider taskProvider,
    FinanceProvider finance,
    HealthProvider health,
    GoalsProvider goals,
    NotesProvider notes,
    ColorScheme cs,
  ) {
    final (start, end) = _visiblePeriod();
    final title = _periodTitle(start, end);
    final theme = Theme.of(context);
    final money0 = NumberFormat.simpleCurrency(decimalDigits: 0);
    final money2 = NumberFormat.simpleCurrency(decimalDigits: 2);

    String line;
    switch (_mode) {
      case CalendarDataLayer.tasks:
        var n = 0;
        for (final d in _eachDay(start, end)) {
          n += taskProvider.getTasksForDay(d).length;
        }
        line = '$n tasks due in $title';
      case CalendarDataLayer.finance:
        var payCount = 0;
        var paySum = 0.0;
        var taskSpend = 0.0;
        for (final d in _eachDay(start, end)) {
          taskSpend += _taskExpenseForDay(taskProvider, d);
          for (final b in _billsOnDay(finance, d)) {
            payCount++;
            paySum += b.amount;
          }
          for (final s in _subsOnDay(finance, d)) {
            payCount++;
            paySum += s.amount;
          }
        }
        line =
            '${money2.format(taskSpend)} from tasks with due dates · '
            '$payCount scheduled payments ${money0.format(paySum)} · '
            '$title';
      case CalendarDataLayer.health:
        var days = 0;
        for (final d in _eachDay(start, end)) {
          if (_dayHasHealthActivity(health, d)) days++;
        }
        line = '$days days with health activity · $title';
      case CalendarDataLayer.goals:
        var n = 0;
        for (final d in _eachDay(start, end)) {
          n += goals.allMilestones.where(
            (m) =>
                m.dueDate != null &&
                _sameDay(_dateOnly(m.dueDate!), d) &&
                !m.isCompleted,
          ).length;
        }
        line = '$n open milestones due · $title';
      case CalendarDataLayer.shopping:
        line = 'Shopping lists are not tied to dates — see details below.';
      case CalendarDataLayer.notes:
        var days = 0;
        for (final d in _eachDay(start, end)) {
          if (notes.journalForDay(NotesProvider.dateKey(d)).isNotEmpty) {
            days++;
          }
        }
        line = '$days days with journal entries · $title';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_mode.shortLabel} · $title',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            line,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayDetail(
    BuildContext context,
    DateTime day,
    TaskProvider taskProvider,
    FinanceProvider finance,
    HealthProvider health,
    GoalsProvider goals,
    ShoppingProvider shop,
    NotesProvider notes,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final key = HealthProvider.dateKey(day);
    final journalKey = NotesProvider.dateKey(day);
    final (rangeStart, rangeEnd) = _visiblePeriod();
    final money2 = NumberFormat.simpleCurrency(decimalDigits: 2);

    Widget dateHeader() => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            DateFormat.yMMMMEEEEd().format(day),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        );

    switch (_mode) {
      case CalendarDataLayer.tasks:
        final list = taskProvider.getTasksForDay(day);
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            dateHeader(),
            if (list.isEmpty)
              _emptyLine(context, 'No tasks due on this day.')
            else
              ...list.map(
                (t) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TaskTile(
                    key: ValueKey(t.id),
                    task: t,
                    isSelectionMode: false,
                    isSelected: false,
                    onTap: () {},
                    onLongPress: () {},
                  ),
                ),
              ),
          ],
        );

      case CalendarDataLayer.finance:
        final bills = _billsOnDay(finance, day);
        final subs = _subsOnDay(finance, day);
        final y = day.year;
        final m = day.month;
        final budget = finance.budgetForMonth(y, m);
        final monthTaskSpend = finance.spentFromTasksForMonth(y, m);
        final limit = budget?.limitAmount ?? 0;
        final pct =
            limit > 0 ? (monthTaskSpend / limit).clamp(0.0, 1.0) : 0.0;
        final tasksWithSpend = taskProvider.allTasks.where((t) {
          if (t.dueDate == null) return false;
          if (!_sameDay(_dateOnly(t.dueDate!), day)) return false;
          return t.expenseAmount != null && t.expenseAmount! > 0;
        }).toList();
        final dayTaskSpend = _taskExpenseForDay(taskProvider, day);
        var rangeTaskSpend = 0.0;
        var rangePaySum = 0.0;
        var rangePayCount = 0;
        for (final d in _eachDay(rangeStart, rangeEnd)) {
          rangeTaskSpend += _taskExpenseForDay(taskProvider, d);
          for (final b in _billsOnDay(finance, d)) {
            rangePayCount++;
            rangePaySum += b.amount;
          }
          for (final s in _subsOnDay(finance, d)) {
            rangePayCount++;
            rangePaySum += s.amount;
          }
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            dateHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visible range (${_periodTitle(rangeStart, rangeEnd)})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Task spend (by due date in range): ${money2.format(rangeTaskSpend)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Scheduled payments in range: $rangePayCount · '
                        '${money2.format(rangePaySum)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'This day',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (dayTaskSpend > 0 || tasksWithSpend.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'From tasks · ${money2.format(dayTaskSpend)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              ...tasksWithSpend.map(
                (t) => ListTile(
                  dense: true,
                  leading: Icon(Icons.task_alt_outlined, color: cs.primary),
                  title: Text(t.title),
                  trailing: Text(money2.format(t.expenseAmount ?? 0)),
                ),
              ),
            ],
            if (bills.isEmpty && subs.isEmpty && dayTaskSpend <= 0)
              _emptyLine(
                context,
                'No bills, subscriptions, or task expenses on this day.',
              ),
            for (final b in bills)
              ListTile(
                dense: true,
                leading: Icon(Icons.receipt_long, color: cs.tertiary),
                title: Text(b.title),
                subtitle: Text('Bill · ${money2.format(b.amount)}'),
              ),
            for (final s in subs)
              ListTile(
                dense: true,
                leading: Icon(Icons.subscriptions_outlined, color: cs.tertiary),
                title: Text(s.name),
                subtitle: Text(
                  '${s.cycle == SubscriptionCycle.monthly ? 'Monthly' : 'Yearly'} · ${money2.format(s.amount)}',
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat.yMMMM().format(day)} budget',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Task-linked spend this month: ${money2.format(monthTaskSpend)}'
                        '${limit > 0 ? ' · Limit ${money2.format(limit)} (${(pct * 100).round()}%)' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

      case CalendarDataLayer.health:
        final mood = health.moodFor(key);
        final sleep = health.sleepFor(key);
        final water = health.waterTotalMl(key);
        final meals = health.mealsFor(key);
        final workouts = health.workouts.where((w) => _sameDay(w.date, day)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        var habitsDone = 0;
        for (final h in health.habits) {
          if (health.isHabitDone(h.id, key)) habitsDone++;
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            dateHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Habits: $habitsDone / ${health.habits.length} done',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (mood != null)
                    Text(
                      'Mood: ${mood.moodLevel + 1}/5',
                      style: theme.textTheme.bodyLarge,
                    ),
                  if (sleep != null)
                    Text(
                      'Sleep: ${sleep.hoursSlept} h',
                      style: theme.textTheme.bodyLarge,
                    ),
                  if (water > 0)
                    Text('Water: $water ml', style: theme.textTheme.bodyLarge),
                  if (meals.isNotEmpty)
                    Text(
                      'Meals logged: ${meals.length}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (workouts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Workouts', style: theme.textTheme.titleSmall),
                    ...workouts.map(
                      (w) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.fitness_center, size: 20),
                        title: Text(w.title),
                        subtitle: Text('${w.durationMinutes} min'),
                      ),
                    ),
                  ],
                  if (!_dayHasHealthActivity(health, day))
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Nothing logged for this day.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );

      case CalendarDataLayer.goals:
        final milestones = goals.allMilestones
            .where(
              (m) =>
                  m.dueDate != null &&
                  _sameDay(_dateOnly(m.dueDate!), day),
            )
            .toList();
        final monthGoals = goals.goals.where((g) {
          if (g.timeframe == 0) {
            return g.targetYear == day.year && g.targetMonth == day.month;
          }
          return g.targetYear == day.year;
        }).toList();

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            dateHeader(),
            if (milestones.isEmpty)
              _emptyLine(context, 'No milestones on this day.')
            else
              ...milestones.map((m) {
                String parentTitle = 'Goal';
                for (final g in goals.goals) {
                  if (g.id == m.parentGoalId) {
                    parentTitle = g.title;
                    break;
                  }
                }
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.flag_circle_outlined),
                  title: Text(m.title),
                  subtitle: Text(parentTitle),
                  trailing: m.isCompleted
                      ? Icon(Icons.check_circle, color: cs.primary)
                      : Text('${m.progressPercent}%'),
                );
              }),
            if (monthGoals.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'Goals for this month / year',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ...monthGoals.map(
                (g) => ListTile(
                  dense: true,
                  title: Text(g.title),
                  subtitle: Text(
                    g.timeframe == 0 ? 'Monthly focus' : 'Yearly focus',
                  ),
                  trailing: Text('${g.progressPercent}%'),
                ),
              ),
            ],
          ],
        );

      case CalendarDataLayer.shopping:
        final items = shop.shoppingItems();
        final unchecked = items.where((e) => !e.isChecked).length;
        final inv = shop.inventoryItems();
        final wish = shop.wishlistItems();
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            dateHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shopping list',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text('${items.length} items · $unchecked left to buy'),
                      const SizedBox(height: 12),
                      Text(
                        'Inventory: ${inv.length} items',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Wishlist: ${wish.length} items',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Lists are not tied to calendar dates — this is your live snapshot.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

      case CalendarDataLayer.notes:
        final entries = notes.journalForDay(journalKey);
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            dateHeader(),
            if (entries.isEmpty)
              _emptyLine(context, 'No journal entries on this day.')
            else
              ...entries.map(
                (e) => Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: Text(e.title.isEmpty ? 'Entry' : e.title),
                    subtitle: Text(
                      e.bodyMarkdown,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
          ],
        );
    }
  }

  Widget _emptyLine(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final canPop = Navigator.of(context).canPop();

    final taskProvider = context.watch<TaskProvider>();
    final finance = context.watch<FinanceProvider>();
    final health = context.watch<HealthProvider>();
    final goals = context.watch<GoalsProvider>();
    final shop = context.watch<ShoppingProvider>();
    final notes = context.watch<NotesProvider>();

    final dayStyle = TextStyle(
      color: cs.onSurface,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    );
    final weekendStyle = TextStyle(
      color: cs.onSurfaceVariant,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
    );
    final outsideStyle = TextStyle(
      color: cs.onSurfaceVariant.withValues(alpha: 0.45),
      fontSize: 14,
      decoration: TextDecoration.none,
    );
    final onPrimaryDay = TextStyle(
      color: cs.onPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none,
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Today',
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = _focusedDay;
            }),
          ),
        ],
      ),
      body: Material(
        color: cs.surface,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: _calendarTextScaler(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModeSelector(theme, cs),
              TableCalendar<CalendarMarker>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2100, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  rowHeight: 46,
                  daysOfWeekHeight: 36,
                  selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focused) {
                    setState(() => _focusedDay = focused);
                  },
                  eventLoader: (day) => _markersForDay(
                    day,
                    taskProvider,
                    finance,
                    health,
                    goals,
                    notes,
                  ),
                  calendarBuilders: CalendarBuilders<CalendarMarker>(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _layerColor(cs, _mode),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 1,
                    markerDecoration: const BoxDecoration(shape: BoxShape.circle),
                    cellMargin: const EdgeInsets.all(4),
                    outsideDaysVisible: true,
                    defaultTextStyle: dayStyle,
                    weekendTextStyle: weekendStyle,
                    outsideTextStyle: outsideStyle,
                    disabledTextStyle: outsideStyle,
                    holidayTextStyle: weekendStyle,
                    selectedTextStyle: onPrimaryDay,
                    todayTextStyle: onPrimaryDay,
                    selectedDecoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: cs.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: cs.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                    formatButtonDecoration: BoxDecoration(
                      border: Border.all(
                        color: cs.outline.withValues(alpha: 0.35),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leftChevronIcon:
                        Icon(Icons.chevron_left, color: cs.primary, size: 28),
                    rightChevronIcon:
                        Icon(Icons.chevron_right, color: cs.primary, size: 28),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                    weekendStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              _buildPeriodSummary(
                context,
                taskProvider,
                finance,
                health,
                goals,
                notes,
                cs,
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              Expanded(
                child: _buildDayDetail(
                  context,
                  _selectedDay ?? _focusedDay,
                  taskProvider,
                  finance,
                  health,
                  goals,
                  shop,
                  notes,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
