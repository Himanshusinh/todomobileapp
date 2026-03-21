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

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _viewMonth = DateTime(n.year, n.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final allTasks = context.watch<TaskProvider>().allTasks;
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);

    final y = _viewMonth.year;
    final m = _viewMonth.month;
    final budget = finance.budgetForMonth(y, m);
    final spentTasks = finance.spentFromTasksForMonth(y, m);
    final limit = budget?.limitAmount ?? 0;
    final progress = limit > 0 ? (spentTasks / limit).clamp(0.0, 1.0) : 0.0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAhead = today.add(const Duration(days: 7));

    bool withinWeek(DateTime raw) {
      final d = DateTime(raw.year, raw.month, raw.day);
      return !d.isBefore(today) && !d.isAfter(weekAhead);
    }

    final upcomingBills = finance.bills.where((b) => withinWeek(b.nextDueDate)).toList();

    final upcomingSubs =
        finance.subscriptions.where((s) => withinWeek(s.nextRenewalDate)).toList();

    final taskExpenses = allTasks
        .where((t) => t.expenseAmount != null && t.expenseAmount! > 0)
        .toList();

    final appBarBg =
        Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: appBarBg,
                elevation: 0,
                child: SafeArea(
                  bottom: false,
                  child: AppBar(
                    title: const Text('Finance & Budget'),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
          _MonthHeader(
            label: DateFormat('MMMM yyyy').format(_viewMonth),
            onPrev: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined),
                      const SizedBox(width: 8),
                      Text(
                        'Monthly budget',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _editBudgetDialog(context, finance, y, m, limit),
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(limit > 0 ? 'Edit' : 'Set limit'),
                      ),
                    ],
                  ),
                  if (limit <= 0)
                    Text(
                      'Set a monthly limit to track spending from task expenses.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Spent (from tasks): ${currency.format(spentTasks)} / ${currency.format(limit)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Remaining: ${currency.format((limit - spentTasks).clamp(0, double.infinity))}',
                      style: TextStyle(
                        color: spentTasks > limit
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            icon: Icons.receipt_long,
            title: 'Bills & due dates',
            onAdd: () => _addBillSheet(context, finance),
          ),
          if (upcomingBills.isNotEmpty) ...[
            Text(
              'Due within 7 days',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
          ],
          if (finance.bills.isEmpty)
            const _EmptyHint('Add recurring bills like rent, utilities, etc.')
          else
            ...finance.bills.map(
              (b) => _BillTile(
                bill: b,
                highlight: withinWeek(b.nextDueDate),
              ),
            ),
          const SizedBox(height: 20),
          _SectionTitle(
            icon: Icons.subscriptions_outlined,
            title: 'Subscriptions',
            onAdd: () => _addSubscriptionSheet(context, finance),
          ),
          if (upcomingSubs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Some subscriptions renew within 7 days (highlighted below).',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.orange.shade800,
                    ),
              ),
            ),
          if (finance.subscriptions.isEmpty)
            const _EmptyHint('Track Netflix, gym, cloud — with renewal reminders.')
          else
            ...finance.subscriptions.map(
              (s) => _SubscriptionTile(
                sub: s,
                highlight: withinWeek(s.nextRenewalDate),
              ),
            ),
          const SizedBox(height: 20),
          _SectionTitle(
            icon: Icons.savings_outlined,
            title: 'Savings goals',
            onAdd: () => _addGoalSheet(context, finance),
          ),
          if (finance.savingsGoals.isEmpty)
            const _EmptyHint('Create a goal and log progress toward it.')
          else
            ...finance.savingsGoals.map((g) => _GoalTile(goal: g)),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.task_alt, size: 22),
              const SizedBox(width: 8),
              Text(
                'Task expenses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Amounts you attach to tasks (e.g. “Buy groceries — \$45”) roll into the monthly overview.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          if (taskExpenses.isEmpty)
            const _EmptyHint('Edit a task and set “Expense amount”.')
          else
            ...taskExpenses.take(12).map((t) => _TaskExpenseTile(task: t)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _financeFabMenu(context, finance),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
      ],
    );
  }

  void _financeFabMenu(BuildContext context, FinanceProvider finance) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Bill'),
              onTap: () {
                Navigator.pop(ctx);
                _addBillSheet(context, finance);
              },
            ),
            ListTile(
              leading: const Icon(Icons.subscriptions),
              title: const Text('Subscription'),
              onTap: () {
                Navigator.pop(ctx);
                _addSubscriptionSheet(context, finance);
              },
            ),
            ListTile(
              leading: const Icon(Icons.savings),
              title: const Text('Savings goal'),
              onTap: () {
                Navigator.pop(ctx);
                _addGoalSheet(context, finance);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editBudgetDialog(
    BuildContext context,
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
        title: Text('Budget — ${DateFormat('MMMM yyyy').format(DateTime(year, month))}'),
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
    if (ok == true && context.mounted) {
      final v = double.tryParse(controller.text.replaceAll(',', '')) ?? 0;
      finance.setMonthlyBudget(year, month, v);
    }
  }

  Future<void> _addBillSheet(BuildContext context, FinanceProvider finance) async {
    final title = TextEditingController();
    final amount = TextEditingController();
    final notes = TextEditingController();
    DateTime due = DateTime.now();
    bool monthly = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('New bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                controller: amount,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              ListTile(
                title: Text(DateFormat('MMM d, y').format(due)),
                subtitle: const Text('Due date'),
                trailing: const Icon(Icons.calendar_today),
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
                value: monthly,
                title: const Text('Repeats monthly'),
                onChanged: (v) => setSt(() => monthly = v),
              ),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final a = double.tryParse(amount.text.replaceAll(',', '')) ?? 0;
                  if (title.text.trim().isEmpty || a <= 0) return;
                  finance.addBill(
                    Bill(
                      id: finance.newId(),
                      title: title.text.trim(),
                      amount: a,
                      nextDueDate: due,
                      notes: notes.text.trim(),
                      isMonthly: monthly,
                    ),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Save bill'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addSubscriptionSheet(BuildContext context, FinanceProvider finance) async {
    final name = TextEditingController();
    final amount = TextEditingController();
    final notes = TextEditingController();
    DateTime next = DateTime.now().add(const Duration(days: 30));
    SubscriptionCycle cycle = SubscriptionCycle.monthly;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('New subscription', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                controller: amount,
                decoration: const InputDecoration(labelText: 'Amount per cycle'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              DropdownButtonFormField<SubscriptionCycle>(
                value: cycle,
                items: const [
                  DropdownMenuItem(value: SubscriptionCycle.monthly, child: Text('Monthly')),
                  DropdownMenuItem(value: SubscriptionCycle.yearly, child: Text('Yearly')),
                ],
                onChanged: (v) => setSt(() => cycle = v ?? SubscriptionCycle.monthly),
                decoration: const InputDecoration(labelText: 'Billing'),
              ),
              ListTile(
                title: Text(DateFormat('MMM d, y').format(next)),
                subtitle: const Text('Next renewal / reminder'),
                trailing: const Icon(Icons.event),
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
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Notes (optional)')),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  final a = double.tryParse(amount.text.replaceAll(',', '')) ?? 0;
                  if (name.text.trim().isEmpty || a <= 0) return;
                  finance.addSubscription(
                    SubscriptionItem(
                      id: finance.newId(),
                      name: name.text.trim(),
                      amount: a,
                      cycle: cycle,
                      nextRenewalDate: next,
                      notes: notes.text.trim(),
                    ),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Save subscription'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addGoalSheet(BuildContext context, FinanceProvider finance) async {
    final title = TextEditingController();
    final target = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('New savings goal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Goal name')),
            TextField(
              controller: target,
              decoration: const InputDecoration(labelText: 'Target amount'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final t = double.tryParse(target.text.replaceAll(',', '')) ?? 0;
                if (title.text.trim().isEmpty || t <= 0) return;
                finance.addSavingsGoal(
                  SavingsGoal(
                    id: finance.newId(),
                    title: title.text.trim(),
                    targetAmount: t,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Save goal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.label,
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
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onAdd;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add',
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  final Bill bill;
  final bool highlight;

  const _BillTile({required this.bill, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);
    final due = DateFormat('MMM d').format(bill.nextDueDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: highlight
          ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.35)
          : null,
      child: ListTile(
        title: Text(bill.title),
        subtitle: Text(
          '${currency.format(bill.amount)} · Due $due${bill.isMonthly ? ' · Monthly' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'paid') finance.markBillPaid(bill.id);
            if (v == 'delete') finance.deleteBill(bill.id);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'paid', child: Text('Mark paid')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final SubscriptionItem sub;
  final bool highlight;

  const _SubscriptionTile({required this.sub, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);
    final next = DateFormat('MMM d, y').format(sub.nextRenewalDate);
    final cycle = sub.cycle == SubscriptionCycle.monthly ? 'Monthly' : 'Yearly';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: highlight
          ? Colors.orange.shade50.withOpacity(0.5)
          : null,
      child: ListTile(
        title: Text(sub.name),
        subtitle: Text('${currency.format(sub.amount)} · $cycle · Next $next'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'next') finance.advanceSubscriptionRenewal(sub.id);
            if (v == 'delete') finance.deleteSubscription(sub.id);
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'next',
              child: Text('Record renewal (next cycle)'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final SavingsGoal goal;

  const _GoalTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add contribution',
                  onPressed: () async {
                    final c = TextEditingController();
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Add to goal'),
                        content: TextField(
                          controller: c,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: true,
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
                    if (ok == true && context.mounted) {
                      final v = double.tryParse(c.text.replaceAll(',', '')) ?? 0;
                      if (v > 0) finance.contributeToGoal(goal.id, v);
                    }
                  },
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') finance.deleteSavingsGoal(goal.id);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete goal')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${currency.format(goal.currentAmount)} / ${currency.format(goal.targetAmount)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskExpenseTile extends StatelessWidget {
  final TaskItem task;

  const _TaskExpenseTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(task.title),
        subtitle: Text(
          task.dueDate != null
              ? DateFormat('MMM d').format(task.dueDate!)
              : 'No due date',
        ),
        trailing: Text(
          currency.format(task.expenseAmount ?? 0),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => TaskFormScreen(task: task)),
        ),
      ),
    );
  }
}