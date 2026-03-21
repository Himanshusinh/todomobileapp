import 'package:hive/hive.dart';

part 'monthly_budget.g.dart';

@HiveType(typeId: 9)
class MonthlyBudget extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  int year;

  @HiveField(2)
  int month;

  @HiveField(3)
  double limitAmount;

  MonthlyBudget({
    required this.id,
    required this.year,
    required this.month,
    required this.limitAmount,
  });

  static String idFor(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';
}
