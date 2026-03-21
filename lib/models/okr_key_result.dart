import 'package:hive/hive.dart';

part 'okr_key_result.g.dart';

@HiveType(typeId: 32)
class OkrKeyResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String objectiveId;

  @HiveField(2)
  String title;

  @HiveField(3)
  double current;

  @HiveField(4)
  double target;

  @HiveField(5)
  String unit;

  @HiveField(6)
  int sortOrder;

  OkrKeyResult({
    required this.id,
    required this.objectiveId,
    required this.title,
    this.current = 0,
    this.target = 100,
    this.unit = '',
    this.sortOrder = 0,
  });

  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0);
}
