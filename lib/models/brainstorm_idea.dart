import 'package:hive/hive.dart';

part 'brainstorm_idea.g.dart';

@HiveType(typeId: 23)
class BrainstormIdea extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  int orderIndex;

  BrainstormIdea({
    required this.id,
    required this.title,
    this.content = '',
    this.colorValue = 0xFF2196F3,
    this.orderIndex = 0,
  });
}
