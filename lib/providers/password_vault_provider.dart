import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:todoapp/models/password_vault_item.dart';
import 'package:todoapp/services/hive_user_boxes.dart';
import 'package:uuid/uuid.dart';

/// Site/email/username in Hive; passwords in encrypted storage (Android Keystore / iOS Keychain).
class PasswordVaultProvider extends ChangeNotifier {
  PasswordVaultProvider({required String userId})
      : _userId = userId,
        _box = Hive.box<PasswordVaultItem>(
          HiveUserBoxes.name('password_vault', userId),
        ),
        _secure = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final String _userId;
  final Box<PasswordVaultItem> _box;
  final FlutterSecureStorage _secure;
  final _uuid = const Uuid();

  String _pwdKey(String id) => 'vault_${_userId}_pwd_$id';

  List<PasswordVaultItem> get entries => _box.values.toList()
    ..sort((a, b) {
      final byName = a.siteName.toLowerCase().compareTo(b.siteName.toLowerCase());
      if (byName != 0) return byName;
      return a.sortOrder.compareTo(b.sortOrder);
    });

  List<PasswordVaultItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return entries.where((e) {
      return e.siteName.toLowerCase().contains(q) ||
          e.username.toLowerCase().contains(q) ||
          e.websiteUrl.toLowerCase().contains(q) ||
          e.notes.toLowerCase().contains(q);
    }).toList();
  }

  Future<String?> getPassword(String id) => _secure.read(key: _pwdKey(id));

  Future<void> addEntry({
    required String siteName,
    String websiteUrl = '',
    String username = '',
    required String password,
    String notes = '',
  }) async {
    final list = _box.values.toList();
    final next = list.isEmpty
        ? 0
        : list.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    final id = _uuid.v4();
    _box.put(
      id,
      PasswordVaultItem(
        id: id,
        siteName: siteName.trim(),
        websiteUrl: websiteUrl.trim(),
        username: username.trim(),
        notes: notes.trim(),
        sortOrder: next,
      ),
    );
    if (password.isNotEmpty) {
      await _secure.write(key: _pwdKey(id), value: password);
    }
    notifyListeners();
  }

  /// Updates metadata (mutate [item] fields first). Optionally replaces or clears password.
  Future<void> updateEntry(
    PasswordVaultItem item, {
    String? newPassword,
    bool clearPassword = false,
  }) async {
    item.save();
    if (clearPassword) {
      await _secure.delete(key: _pwdKey(item.id));
    } else if (newPassword != null && newPassword.isNotEmpty) {
      await _secure.write(key: _pwdKey(item.id), value: newPassword);
    }
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await _secure.delete(key: _pwdKey(id));
    await _box.delete(id);
    notifyListeners();
  }
}
