import 'package:hive/hive.dart';

part 'fitness_goal.g.dart';

@HiveType(typeId: 19)
class FitnessGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  /// Target scale weight (kg)
  @HiveField(2)
  double targetWeightKg;

  /// Starting point when goal was set (kg)
  @HiveField(3)
  double? startWeightKg;

  FitnessGoal({
    required this.id,
    required this.title,
    required this.targetWeightKg,
    this.startWeightKg,
  });

  /// Progress 0–1 toward target using [currentKg]. Loss goals: start > target.
  double progressToward(double? currentKg) {
    if (currentKg == null || startWeightKg == null) return 0;
    final start = startWeightKg!;
    final target = targetWeightKg;
    if ((start - target).abs() < 0.01) return 1;
    if (start > target) {
      // lose weight
      final done = start - currentKg;
      final total = start - target;
      return (done / total).clamp(0.0, 1.0);
    } else {
      // gain weight
      final done = currentKg - start;
      final total = target - start;
      return (done / total).clamp(0.0, 1.0);
    }
  }
}
