import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:todoapp/models/bill.dart';
import 'package:todoapp/models/monthly_budget.dart';
import 'package:todoapp/models/savings_goal.dart';
import 'package:todoapp/models/subscription_item.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:uuid/uuid.dart';

class FinanceProvider extends ChangeNotifier {
  final Box<Bill> _billBox = Hive.box<Bill>('bills');
  final Box<SubscriptionItem> _subBox =
      Hive.box<SubscriptionItem>('subscriptions');
  final Box<SavingsGoal> _goalBox = Hive.box<SavingsGoal>('savings_goals');
  final Box<MonthlyBudget> _budgetBox =
      Hive.box<MonthlyBudget>('monthly_budgets');
  final Box<TaskItem> _taskBox = Hive.box<TaskItem>('tasks');
  final _uuid = const Uuid();

  List<Bill> get bills =>
      _billBox.values.toList()..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

  List<SubscriptionItem> get subscriptions => _subBox.values.toList()
    ..sort((a, b) => a.nextRenewalDate.compareTo(b.nextRenewalDate));

  List<SavingsGoal> get savingsGoals => _goalBox.values.toList();

  MonthlyBudget? budgetForMonth(int year, int month) =>
      _budgetBox.get(MonthlyBudget.idFor(year, month));

  /// Task-linked expenses counted for [month] using due date (or today if no due date).
  double spentFromTasksForMonth(int year, int month) {
    double sum = 0;
    for (final t in _taskBox.values) {
      final amt = t.expenseAmount;
      if (amt == null || amt <= 0) continue;
      final d = t.dueDate;
      if (d != null) {
        if (d.year != year || d.month != month) continue;
      } else {
        // Tasks without due date: include only in "current" month when viewing current month
        final now = DateTime.now();
        if (year != now.year || month != now.month) continue;
      }
      sum += amt;
    }
    return sum;
  }

  void setMonthlyBudget(int year, int month, double limit) {
    final id = MonthlyBudget.idFor(year, month);
    _budgetBox.put(
      id,
      MonthlyBudget(id: id, year: year, month: month, limitAmount: limit),
    );
    notifyListeners();
  }

  void addBill(Bill bill) {
    _billBox.put(bill.id, bill);
    notifyListeners();
  }

  void updateBill(Bill bill) {
    _billBox.put(bill.id, bill);
    notifyListeners();
  }

  void deleteBill(String id) {
    _billBox.delete(id);
    notifyListeners();
  }

  /// Marks bill paid and advances monthly due date.
  void markBillPaid(String id) {
    final b = _billBox.get(id);
    if (b == null) return;
    if (b.isMonthly) {
      final d = b.nextDueDate;
      b.nextDueDate = DateTime(d.year, d.month + 1, d.day);
      _billBox.put(id, b);
    } else {
      _billBox.delete(id);
    }
    notifyListeners();
  }

  void addSubscription(SubscriptionItem s) {
    _subBox.put(s.id, s);
    notifyListeners();
  }

  void updateSubscription(SubscriptionItem s) {
    _subBox.put(s.id, s);
    notifyListeners();
  }

  void deleteSubscription(String id) {
    _subBox.delete(id);
    notifyListeners();
  }

  /// After a renewal / reminder, bump next date by one billing cycle.
  void advanceSubscriptionRenewal(String id) {
    final s = _subBox.get(id);
    if (s == null) return;
    final d = s.nextRenewalDate;
    if (s.cycle == SubscriptionCycle.monthly) {
      s.nextRenewalDate = DateTime(d.year, d.month + 1, d.day);
    } else {
      s.nextRenewalDate = DateTime(d.year + 1, d.month, d.day);
    }
    _subBox.put(id, s);
    notifyListeners();
  }

  void addSavingsGoal(SavingsGoal g) {
    _goalBox.put(g.id, g);
    notifyListeners();
  }

  void updateSavingsGoal(SavingsGoal g) {
    _goalBox.put(g.id, g);
    notifyListeners();
  }

  void deleteSavingsGoal(String id) {
    _goalBox.delete(id);
    notifyListeners();
  }

  void contributeToGoal(String id, double amount) {
    final g = _goalBox.get(id);
    if (g == null || amount <= 0) return;
    g.currentAmount += amount;
    _goalBox.put(id, g);
    notifyListeners();
  }

  String newId() => _uuid.v4();
}
