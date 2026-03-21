import 'package:hive/hive.dart';

part 'grocery_item.g.dart';

@HiveType(typeId: 16)
class GroceryItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isChecked;

  @HiveField(3)
  int orderIndex;

  GroceryItem({
    required this.id,
    required this.title,
    this.isChecked = false,
    this.orderIndex = 0,
  });
}
