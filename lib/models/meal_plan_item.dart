import 'package:hive/hive.dart';

part 'meal_plan_item.g.dart';

/// 0 breakfast, 1 lunch, 2 dinner, 3 snack
@HiveType(typeId: 15)
class MealPlanItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String dateKey;

  @HiveField(2)
  int mealType;

  @HiveField(3)
  String description;

  MealPlanItem({
    required this.id,
    required this.dateKey,
    required this.mealType,
    this.description = '',
  });
}
