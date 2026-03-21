import 'package:hive/hive.dart';
import 'package:todoapp/models/attachment_kind.dart';

part 'task_attachment.g.dart';

@HiveType(typeId: 21)
class TaskAttachment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String taskId;

  @HiveField(2)
  String localPath;

  @HiveField(3)
  AttachmentKind kind;

  @HiveField(4)
  String displayName;

  @HiveField(5)
  DateTime addedAt;

  TaskAttachment({
    required this.id,
    required this.taskId,
    required this.localPath,
    required this.kind,
    this.displayName = '',
    required this.addedAt,
  });
}
