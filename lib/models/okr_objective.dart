import 'package:hive/hive.dart';

part 'okr_objective.g.dart';

@HiveType(typeId: 31)
class OkrObjective extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  /// e.g. "2026 Q1", "H1 2026"
  @HiveField(2)
  String periodLabel;

  @HiveField(3)
  int sortOrder;

  OkrObjective({
    required this.id,
    required this.title,
    this.periodLabel = '',
    this.sortOrder = 0,
  });
}
