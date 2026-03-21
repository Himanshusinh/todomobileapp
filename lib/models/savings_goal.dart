import 'package:hive/hive.dart';

part 'savings_goal.g.dart';

@HiveType(typeId: 8)
class SavingsGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double targetAmount;

  @HiveField(3)
  double currentAmount;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);
}
