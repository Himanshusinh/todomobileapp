import 'package:hive/hive.dart';

part 'weight_entry.g.dart';

@HiveType(typeId: 18)
class WeightEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  double weightKg;

  @HiveField(3)
  String note;

  WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.note = '',
  });
}
