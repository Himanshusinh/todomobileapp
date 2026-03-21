import 'package:hive/hive.dart';

part 'quick_capture.g.dart';

/// Brain-dump / inbox note (not tied to a calendar day).
@HiveType(typeId: 24)
class QuickCapture extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String body;

  @HiveField(2)
  DateTime createdAt;

  QuickCapture({
    required this.id,
    required this.body,
    required this.createdAt,
  });
}
