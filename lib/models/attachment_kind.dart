import 'package:hive/hive.dart';

part 'attachment_kind.g.dart';

@HiveType(typeId: 20)
enum AttachmentKind {
  @HiveField(0)
  image,

  @HiveField(1)
  file,

  @HiveField(2)
  voice,
}
