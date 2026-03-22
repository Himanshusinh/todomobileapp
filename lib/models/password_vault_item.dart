import 'package:hive/hive.dart';

part 'password_vault_item.g.dart';

/// Login metadata only — the actual password is stored in [FlutterSecureStorage].
@HiveType(typeId: 37)
class PasswordVaultItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String siteName;

  /// Website URL (https://…)
  @HiveField(2)
  String websiteUrl;

  /// Email or username
  @HiveField(3)
  String username;

  @HiveField(4)
  String notes;

  @HiveField(5)
  int sortOrder;

  PasswordVaultItem({
    required this.id,
    required this.siteName,
    this.websiteUrl = '',
    this.username = '',
    this.notes = '',
    this.sortOrder = 0,
  });
}
