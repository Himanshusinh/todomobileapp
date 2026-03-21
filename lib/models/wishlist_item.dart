import 'package:hive/hive.dart';

part 'wishlist_item.g.dart';

@HiveType(typeId: 36)
class WishlistItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String notes;

  @HiveField(3)
  String url;

  @HiveField(4)
  double? priceEstimate;

  @HiveField(5)
  bool isPurchased;

  /// Gift idea: who it's for
  @HiveField(6)
  String recipient;

  @HiveField(7)
  String categoryId;

  @HiveField(8)
  String barcode;

  @HiveField(9)
  int sortOrder;

  WishlistItem({
    required this.id,
    required this.title,
    this.notes = '',
    this.url = '',
    this.priceEstimate,
    this.isPurchased = false,
    this.recipient = '',
    this.categoryId = '',
    this.barcode = '',
    this.sortOrder = 0,
  });
}
