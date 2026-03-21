import 'package:hive/hive.dart';

part 'home_inventory_item.g.dart';

@HiveType(typeId: 35)
class HomeInventoryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String categoryId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String location;

  @HiveField(4)
  int quantity;

  @HiveField(5)
  String notes;

  @HiveField(6)
  String barcode;

  /// Purchase or estimated value for tracking
  @HiveField(7)
  double? valueEstimate;

  @HiveField(8)
  int sortOrder;

  HomeInventoryItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.location = '',
    this.quantity = 1,
    this.notes = '',
    this.barcode = '',
    this.valueEstimate,
    this.sortOrder = 0,
  });
}
