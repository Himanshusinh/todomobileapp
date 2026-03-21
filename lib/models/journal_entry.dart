import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

@HiveType(typeId: 22)
class JournalEntry extends HiveObject {
  @HiveField(0)
  final String id;

  /// Calendar day for this entry: `yyyy-MM-dd`
  @HiveField(1)
  String dateKey;

  @HiveField(2)
  String title;

  @HiveField(3)
  String bodyMarkdown;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.dateKey,
    this.title = '',
    this.bodyMarkdown = '',
    required this.createdAt,
    required this.updatedAt,
  });
}
