import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/bill.dart';
import 'package:todoapp/models/savings_goal.dart';
import 'package:todoapp/models/subscription_item.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/finance_provider.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/screens/task_form_screen.dart';

/// Finance: tabs (Overview / Subscriptions / Goals), compact lists, quick add sheets.
class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!mounted) return;
      // Rebuild so the + button changes behavior per-tab.
      setState(() {});
    });
    final n = DateTime.now();
    _viewMonth = DateTime(n.year, n.month);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    });
  }

  void _fabMenu(FinanceProvider finance) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Bill'),
              onTap: () {
                Navigator.pop(ctx);
                _addBillSheet(finance);
              },
            ),
            ListTile(
              leading: const Icon(Icons.subscriptions_outlined),
              title: const Text('Subscription'),
              onTap: () {
                Navigator.pop(ctx);
                _addSubscriptionSheet(finance);
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: const Text('Savings goal'),
              onTap: () {
                Navigator.pop(ctx);
                _addGoalSheet(finance);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _onFabPressed(FinanceProvider finance) {
    // Context-aware + button:
    // - Overview -> add Bill
    // - Subscriptions -> add Subscription
    // - Goals -> add Savings goal
    final i = _tabs.index;
    if (i == 0) {
      _addBillSheet(finance);
      return;
    }
    if (i == 1) {
      _addSubscriptionSheet(finance);
      return;
    }
    _addGoalSheet(finance);
  }

  Future<void> _editBudgetDialog(
    FinanceProvider finance,
    int year,
    int month,
    double current,
  ) async {
    final controller = TextEditingController(
      text: current > 0 ? current.toStringAsFixed(2) : '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Budget'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Monthly limit',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && mounted) {
      // Defer side-effects (Provider notify / SnackBar) to the next frame.
      // Otherwise, the dialog route can still be tearing down and Flutter may
      // assert about dependents during rebuild.
      final v = double.tryParse(controller.text.replaceAll(',', '')) ?? 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (v <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enter a valid amount (greater than 0).'),
            ),
          );
          return;
        }
        try {
          finance.setMonthlyBudget(year, month, v);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save budget: $e')),
          );
        }
      });
    }
    // NOTE: We intentionally don't dispose these short-lived controllers.
    // Disposing during/around route close animations can trigger
    // \"TextEditingController used after being disposed\" on some devices.
  }

  Future<void> _addBillSheet(FinanceProvider finance) async {
    final title = TextEditingController();
    final amount = TextEditingController();
    DateTime due = DateTime.now();
    bool monthly = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New bill',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'What is it?',
                        hintText: 'e.g. Rent, Electric',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amount,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Due date'),
                      subtitle: Text(DateFormat('EEE, MMM d').format(due)),
                      trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: due,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setSt(() => due = d);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: monthly,
                      title: const Text('Repeats every month'),
                      onChanged: (v) => setSt(() => monthly = v),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        final a = double.tryParse(amount.text.replaceAll(',', '')) ?? 0;
                        if (title.text.trim().isEmpty || a <= 0) return;
                        Navigator.pop(ctx);
                        final t = title.text.trim();
                        final d = due;
                        final isM = monthly;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          finance.addBill(
                            Bill(
                              id: finance.newId(),
                              title: t,
                              amount: a,
                              nextDueDate: d,
                              notes: '',
                              isMonthly: isM,
                            ),
                          );
                        });
                      },
                      child: const Text('Add bill'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    // NOTE: Intentionally not disposing short-lived controllers here.
  }

  Future<void> _addSubscriptionSheet(FinanceProvider finance) async {
    final name = TextEditingController();
    final amount = TextEditingController();
    DateTime next = DateTime.now().add(const Duration(days: 30));
    SubscriptionCycle cycle = SubscriptionCycle.monthly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'New subscription',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Netflix',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amount,
                      decoration: const InputDecoration(
                        labelText: 'Amount per period',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SegmentedButton<SubscriptionCycle>(
                        segments: const [
                          ButtonSegment(
                            value: SubscriptionCycle.monthly,
                            label: Text('Monthly'),
                          ),
                          ButtonSegment(
                            value: SubscriptionCycle.yearly,
                            label: Text('Yearly'),
                          ),
                        ],
                        selected: {cycle},
                        onSelectionChanged: (s) {
                          setSt(() => cycle = s.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Next renewal'),
                      subtitle: Text(DateFormat('EEE, MMM d, y').format(next)),
                      trailing: const Icon(Icons.event_outlined, size: 20),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: next,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setSt(() => next = d);
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        final a = double.tryParse(amount.text.replaceAll(',', '')) ?? 0;
                        if (name.text.trim().isEmpty || a <= 0) return;
                        Navigator.pop(ctx);
                        final n = name.text.trim();
                        final c = cycle;
                        final nx = next;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          finance.addSubscription(
                            SubscriptionItem(
                              id: finance.newId(),
                              name: n,
                              amount: a,
                              cycle: c,
                              nextRenewalDate: nx,
                              notes: '',
                            ),
                          );
                        });
                      },
                      child: const Text('Add subscription'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    // NOTE: Intentionally not disposing short-lived controllers here.
  }

  Future<void> _addGoalSheet(FinanceProvider finance) async {
    final title = TextEditingController();
    final target = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Savings goal',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Goal name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setSt(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: target,
                  decoration: const InputDecoration(
                    labelText: 'Target amount',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setSt(() {}),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    final t =
                        double.tryParse(target.text.replaceAll(',', '')) ?? 0;
                    final name = title.text.trim();
                    if (name.isEmpty || t <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a goal name and a valid amount.'),
                        ),
                      );
                      return;
                    }
                    try {
                      Navigator.pop(ctx);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        finance.addSavingsGoal(
                          SavingsGoal(
                            id: finance.newId(),
                            title: name,
                            targetAmount: t,
                          ),
                        );
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not save goal: $e')),
                      );
                    }
                  },
                  child: const Text('Create goal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // NOTE: Intentionally not disposing short-lived controllers here.
  }

  Future<void> _contributeDialog(FinanceProvider finance, SavingsGoal goal) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add amount'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && mounted) {
      final v = double.tryParse(c.text.replaceAll(',', '')) ?? 0;
      if (v > 0) finance.contributeToGoal(goal.id, v);
    }
    // NOTE: Intentionally not disposing short-lived controller here.
  }

  @override
  Widget build(BuildContext context) {
    // Do not `watch` FinanceProvider here — it rebuilds TabBarView on every save and
    // can reset the selected tab / cause layout jumps. Each tab watches what it needs.
    final cs = Theme.of(context).colorScheme;

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
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Subscriptions'),
                  Tab(text: 'Goals'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _FinanceTabKeepAlive(
                    child: _OverviewTab(
                      viewMonth: _viewMonth,
                      onShiftMonth: _shiftMonth,
                      onEditBudget: () {
                        final finance = context.read<FinanceProvider>();
                        final y = _viewMonth.year;
                        final m = _viewMonth.month;
                        final limit =
                            finance.budgetForMonth(y, m)?.limitAmount ?? 0;
                        _editBudgetDialog(finance, y, m, limit);
                      },
                    ),
                  ),
                  const _FinanceTabKeepAlive(
                    child: _UpcomingTab(),
                  ),
                  _FinanceTabKeepAlive(
                    child: _GoalsTab(onContribute: _contributeDialog),
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
            child: Material(
              color: cs.primary,
              elevation: 3,
              shadowColor: Colors.black26,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _onFabPressed(context.read<FinanceProvider>()),
                onLongPress: () => _fabMenu(context.read<FinanceProvider>()),
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
}

/// Keeps tab scroll position and subtree alive when switching tabs / when siblings update.
class _FinanceTabKeepAlive extends StatefulWidget {
  const _FinanceTabKeepAlive({required this.child});

  final Widget child;

  @override
  State<_FinanceTabKeepAlive> createState() => _FinanceTabKeepAliveState();
}

class _FinanceTabKeepAliveState extends State<_FinanceTabKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// —— Overview ——

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.viewMonth,
    required this.onShiftMonth,
    required this.onEditBudget,
  });

  final DateTime viewMonth;
  final ValueChanged<int> onShiftMonth;
  final VoidCallback onEditBudget;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final tasks = context.watch<TaskProvider>().allTasks;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);

    final y = viewMonth.year;
    final m = viewMonth.month;
    final budget = finance.budgetForMonth(y, m);
    final spentTasks = finance.spentFromTasksForMonth(y, m);
    final limit = budget?.limitAmount ?? 0;
    final progress = limit > 0 ? (spentTasks / limit).clamp(0.0, 1.0) : 0.0;

    final taskExpenses = tasks
        .where((t) => t.expenseAmount != null && t.expenseAmount! > 0)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        Material(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onEditBudget,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart_outline_rounded, size: 20, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Monthly budget',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        limit > 0 ? 'Edit' : 'Set',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (limit <= 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap to set a limit. Task expenses count toward this month.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: cs.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currency.format(spentTasks)} of ${currency.format(limit)} from tasks',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${currency.format((limit - spentTasks).clamp(0, double.infinity))} left',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: spentTasks > limit ? cs.error : cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Task expenses',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Set an amount on a task to include it here.',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (taskExpenses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No task expenses yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          )
        else
          ...taskExpenses.take(12).map(
                (t) => _TaskExpenseRow(task: t),
              ),
      ],
    );
  }
}

// —— Upcoming (bills + subs, by date) ——

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab();

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAhead = today.add(const Duration(days: 7));

    bool withinWeek(DateTime raw) {
      final d = DateTime(raw.year, raw.month, raw.day);
      return !d.isBefore(today) && !d.isAfter(weekAhead);
    }

    final rows = <_DueSort>[];
    for (final b in finance.bills) {
      rows.add(_DueSort(
        at: b.nextDueDate,
        child: _BillRow(
          bill: b,
          highlight: withinWeek(b.nextDueDate),
          currency: currency,
        ),
      ));
    }
    for (final s in finance.subscriptions) {
      rows.add(_DueSort(
        at: s.nextRenewalDate,
        child: _SubRow(
          sub: s,
          highlight: withinWeek(s.nextRenewalDate),
          currency: currency,
        ),
      ));
    }
    rows.sort((a, b) => a.at.compareTo(b.at));

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No bills or subscriptions.\nTap + to add one.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: rows.length,
      separatorBuilder: (_, _) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
      itemBuilder: (_, i) => rows[i].child,
    );
  }
}

class _DueSort {
  _DueSort({required this.at, required this.child});
  final DateTime at;
  final Widget child;
}

class _BillRow extends StatelessWidget {
  const _BillRow({
    required this.bill,
    required this.highlight,
    required this.currency,
  });

  final Bill bill;
  final bool highlight;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final cs = Theme.of(context).colorScheme;
    final due = DateFormat('MMM d').format(bill.nextDueDate);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      tileColor: highlight ? cs.errorContainer.withValues(alpha: 0.35) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(Icons.receipt_outlined, color: cs.primary, size: 22),
      title: Text(bill.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        'Due $due${bill.isMonthly ? ' · monthly' : ''}',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currency.format(bill.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) {
              // Defer provider mutation until the popup menu route is closed.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (v == 'paid') finance.markBillPaid(bill.id);
                if (v == 'delete') finance.deleteBill(bill.id);
              });
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'paid', child: Text('Mark paid')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubRow extends StatelessWidget {
  const _SubRow({
    required this.sub,
    required this.highlight,
    required this.currency,
  });

  final SubscriptionItem sub;
  final bool highlight;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final cs = Theme.of(context).colorScheme;
    final next = DateFormat('MMM d').format(sub.nextRenewalDate);
    final cycle = sub.cycle == SubscriptionCycle.monthly ? 'Monthly' : 'Yearly';

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      tileColor: highlight ? cs.tertiaryContainer.withValues(alpha: 0.45) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(Icons.subscriptions_outlined, color: cs.tertiary, size: 22),
      title: Text(sub.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$cycle · $next',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currency.format(sub.amount),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (v) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (v == 'next') finance.advanceSubscriptionRenewal(sub.id);
                if (v == 'delete') finance.deleteSubscription(sub.id);
              });
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'next', child: Text('Next renewal')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

// —— Goals ——

class _GoalsTab extends StatelessWidget {
  const _GoalsTab({required this.onContribute});

  final Future<void> Function(FinanceProvider finance, SavingsGoal goal) onContribute;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);
    final goals = finance.savingsGoals;

    if (goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No savings goals yet.\nTap + to create one.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: goals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final g = goals[i];
        return Material(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        g.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      tooltip: 'Add',
                      onPressed: () => onContribute(finance, g),
                    ),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      onSelected: (v) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (v == 'delete') finance.deleteSavingsGoal(g.id);
                        });
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: g.progress,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${currency.format(g.currentAmount)} / ${currency.format(g.targetAmount)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskExpenseRow extends StatelessWidget {
  const _TaskExpenseRow({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        task.dueDate != null ? DateFormat('MMM d').format(task.dueDate!) : 'No date',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: Text(
        currency.format(task.expenseAmount ?? 0),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (ctx) => TaskFormScreen(task: task),
        ),
      ),
    );
  }
}

// (no controller-dispose helper; see notes above)
