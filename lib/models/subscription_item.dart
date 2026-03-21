import 'package:hive/hive.dart';

part 'subscription_item.g.dart';

@HiveType(typeId: 6)
enum SubscriptionCycle {
  @HiveField(0)
  monthly,

  @HiveField(1)
  yearly,
}

@HiveType(typeId: 7)
class SubscriptionItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double amount;

  @HiveField(3)
  SubscriptionCycle cycle;

  /// Next renewal / reminder date.
  @HiveField(4)
  DateTime nextRenewalDate;

  @HiveField(5)
  String notes;

  SubscriptionItem({
    required this.id,
    required this.name,
    required this.amount,
    this.cycle = SubscriptionCycle.monthly,
    required this.nextRenewalDate,
    this.notes = '',
  });
}
