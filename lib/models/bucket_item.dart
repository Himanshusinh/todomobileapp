import 'package:hive/hive.dart';

part 'bucket_item.g.dart';

@HiveType(typeId: 30)
class BucketItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String notes;

  @HiveField(3)
  bool isDone;

  @HiveField(4)
  DateTime? completedAt;

  @HiveField(5)
  int sortOrder;

  BucketItem({
    required this.id,
    required this.title,
    this.notes = '',
    this.isDone = false,
    this.completedAt,
    this.sortOrder = 0,
  });
}
