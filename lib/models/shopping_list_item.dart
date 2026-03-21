import 'package:hive/hive.dart';

part 'shopping_list_item.g.dart';

@HiveType(typeId: 34)
class ShoppingListItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String categoryId;

  @HiveField(2)
  String name;

  /// e.g. "2", "1 kg"
  @HiveField(3)
  String quantityLabel;

  @HiveField(4)
  String notes;

  @HiveField(5)
  bool isChecked;

  /// Store / list price (price tracking)
  @HiveField(6)
  double? unitPrice;

  /// Last price you logged (e.g. last purchase)
  @HiveField(7)
  double? lastRecordedPrice;

  @HiveField(8)
  String barcode;

  @HiveField(9)
  int sortOrder;

  ShoppingListItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.quantityLabel = '',
    this.notes = '',
    this.isChecked = false,
    this.unitPrice,
    this.lastRecordedPrice,
    this.barcode = '',
    this.sortOrder = 0,
  });
}
