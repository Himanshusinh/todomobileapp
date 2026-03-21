import 'package:hive/hive.dart';

part 'vision_item.g.dart';

@HiveType(typeId: 29)
class VisionItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String caption;

  /// Local file path from gallery/camera (optional)
  @HiveField(3)
  String? imagePath;

  @HiveField(4)
  int sortOrder;

  VisionItem({
    required this.id,
    required this.title,
    this.caption = '',
    this.imagePath,
    this.sortOrder = 0,
  });
}
