import 'package:hive/hive.dart';

part 'sleep_entry.g.dart';

/// One row per wake-up calendar day (`dateKey`).
@HiveType(typeId: 13)
class SleepEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String dateKey;

  /// Hours slept (e.g. 7.5)
  @HiveField(2)
  double hoursSlept;

  /// 1–5 optional quality
  @HiveField(3)
  int? quality;

  @HiveField(4)
  String note;

  SleepEntry({
    required this.id,
    required this.dateKey,
    required this.hoursSlept,
    this.quality,
    this.note = '',
  });
}
