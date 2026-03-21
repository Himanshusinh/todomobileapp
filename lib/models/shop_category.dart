import 'package:hive/hive.dart';

part 'shop_category.g.dart';

@HiveType(typeId: 33)
class ShopCategory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int sortOrder;

  ShopCategory({
    required this.id,
    required this.name,
    this.sortOrder = 0,
  });
}
