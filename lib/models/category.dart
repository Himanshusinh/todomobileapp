import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 4)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int iconCode; // Store icon data as codePoint

  @HiveField(3)
  final int colorValue; // Store color as hex value

  Category({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
  });
}
