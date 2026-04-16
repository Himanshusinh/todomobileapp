import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:todoapp/models/attachment_kind.dart';
import 'package:todoapp/models/brainstorm_idea.dart';
import 'package:todoapp/models/journal_entry.dart';
import 'package:todoapp/models/quick_capture.dart';
import 'package:todoapp/models/task_attachment.dart';
import 'package:todoapp/services/hive_user_boxes.dart';
import 'package:uuid/uuid.dart';

class NotesProvider extends ChangeNotifier {
  NotesProvider({required String userId})
      : _attachBox = Hive.box<TaskAttachment>(
          HiveUserBoxes.name('task_attachments', userId),
        ),
        _journalBox =
            Hive.box<JournalEntry>(HiveUserBoxes.name('journal', userId)),
        _ideaBox =
            Hive.box<BrainstormIdea>(HiveUserBoxes.name('brainstorm', userId)),
        _captureBox = Hive.box<QuickCapture>(
          HiveUserBoxes.name('quick_captures', userId),
        );

  final Box<TaskAttachment> _attachBox;
  final Box<JournalEntry> _journalBox;
  final Box<BrainstormIdea> _ideaBox;
  final Box<QuickCapture> _captureBox;
  final _uuid = const Uuid();

  static Future<void> ensureStorageDirs() async {
    final dir = await getApplicationDocumentsDirectory();
    await Directory('${dir.path}/attachments').create(recursive: true);
    await Directory('${dir.path}/recordings').create(recursive: true);
  }

  String newId() => _uuid.v4();

  List<TaskAttachment> attachmentsForTask(String taskId) {
    return _attachBox.values
        .where((a) => a.taskId == taskId)
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  /// Register a file already stored under the app documents directory (e.g. voice recording).
  void addAttachmentAtPath({
    required String taskId,
    required String absolutePath,
    required AttachmentKind kind,
    String displayName = '',
  }) {
    final att = TaskAttachment(
      id: _uuid.v4(),
      taskId: taskId,
      localPath: absolutePath,
      kind: kind,
      displayName: displayName.isEmpty ? absolutePath.split('/').last : displayName,
      addedAt: DateTime.now(),
    );
    _attachBox.put(att.id, att);
    notifyListeners();
  }

  Future<TaskAttachment?> addAttachmentFromPath({
    required String taskId,
    required String sourcePath,
    required AttachmentKind kind,
    String displayName = '',
  }) async {
    final file = File(sourcePath);
    if (!await file.exists()) return null;
    final dir = await getApplicationDocumentsDirectory();
    final sub = kind == AttachmentKind.voice ? 'recordings' : 'attachments';
    final ext = _extFromPath(sourcePath, kind);
    final name = '${_uuid.v4()}.$ext';
    final dest = File('${dir.path}/$sub/$name');
    await dest.parent.create(recursive: true);
    await file.copy(dest.path);
    final att = TaskAttachment(
      id: _uuid.v4(),
      taskId: taskId,
      localPath: dest.path,
      kind: kind,
      displayName: displayName.isEmpty ? name : displayName,
      addedAt: DateTime.now(),
    );
    _attachBox.put(att.id, att);
    notifyListeners();
    return att;
  }

  String _extFromPath(String path, AttachmentKind kind) {
    final lower = path.toLowerCase();
    final dot = lower.lastIndexOf('.');
    if (dot != -1 && dot < lower.length - 1) {
      return lower.substring(dot + 1);
    }
    switch (kind) {
      case AttachmentKind.voice:
        return 'm4a';
      case AttachmentKind.image:
        return 'jpg';
      case AttachmentKind.file:
        return 'bin';
    }
  }

  void deleteAttachment(String id) {
    final a = _attachBox.get(id);
    if (a != null) {
      try {
        File(a.localPath).deleteSync();
      } catch (_) {}
      _attachBox.delete(id);
      notifyListeners();
    }
  }

  /// Remove all attachments for a task (e.g. discard new task draft).
  void deleteAttachmentsForTask(String taskId) {
    for (final a in _attachBox.values.where((x) => x.taskId == taskId).toList()) {
      try {
        File(a.localPath).deleteSync();
      } catch (_) {}
      _attachBox.delete(a.id);
    }
    notifyListeners();
  }

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<JournalEntry> journalForDay(String dateKey) {
    return _journalBox.values
        .where((e) => e.dateKey == dateKey)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<JournalEntry> get allJournalEntries {
    final list = _journalBox.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  void saveJournalEntry(JournalEntry e) {
    _journalBox.put(e.id, e);
    notifyListeners();
  }

  void addJournalEntry(String dateKey, {String title = '', String body = ''}) {
    final now = DateTime.now();
    final e = JournalEntry(
      id: _uuid.v4(),
      dateKey: dateKey,
      title: title,
      bodyMarkdown: body,
      createdAt: now,
      updatedAt: now,
    );
    _journalBox.put(e.id, e);
    notifyListeners();
  }

  void deleteJournalEntry(String id) {
    _journalBox.delete(id);
    notifyListeners();
  }

  List<BrainstormIdea> get brainstormIdeas {
    final list = _ideaBox.values.toList();
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  void addBrainstormIdea(String title, {String content = '', int color = 0xFF2196F3}) {
    final maxO = _ideaBox.isEmpty
        ? -1
        : _ideaBox.values.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b);
    final idea = BrainstormIdea(
      id: _uuid.v4(),
      title: title,
      content: content,
      colorValue: color,
      orderIndex: maxO + 1,
    );
    _ideaBox.put(idea.id, idea);
    notifyListeners();
  }

  void updateBrainstormIdea(BrainstormIdea idea) {
    _ideaBox.put(idea.id, idea);
    notifyListeners();
  }

  void deleteBrainstormIdea(String id) {
    _ideaBox.delete(id);
    notifyListeners();
  }

  List<QuickCapture> get quickCaptures {
    final list = _captureBox.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void addQuickCapture(String body) {
    if (body.trim().isEmpty) return;
    final c = QuickCapture(
      id: _uuid.v4(),
      body: body.trim(),
      createdAt: DateTime.now(),
    );
    _captureBox.put(c.id, c);
    notifyListeners();
  }

  void updateQuickCapture(QuickCapture c) {
    _captureBox.put(c.id, c);
    notifyListeners();
  }

  void deleteQuickCapture(String id) {
    _captureBox.delete(id);
    notifyListeners();
  }
}
