import 'package:hive/hive.dart';

part 'bill.g.dart';

@HiveType(typeId: 5)
class Bill extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  /// Amount due (same currency as rest of app — user-defined).
  @HiveField(2)
  double amount;

  /// Next due date for this bill.
  @HiveField(3)
  DateTime nextDueDate;

  @HiveField(4)
  String notes;

  /// If true, after marking paid, next due advances by one month.
  @HiveField(5)
  bool isMonthly;

  Bill({
    required this.id,
    required this.title,
    required this.amount,
    required this.nextDueDate,
    this.notes = '',
    this.isMonthly = true,
  });
}
