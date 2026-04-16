import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:todoapp/models/bucket_item.dart';
import 'package:todoapp/models/goal_item.dart';
import 'package:todoapp/models/kanban_item.dart';
import 'package:todoapp/models/milestone_item.dart';
import 'package:todoapp/models/okr_key_result.dart';
import 'package:todoapp/models/okr_objective.dart';
import 'package:todoapp/models/project_board.dart';
import 'package:todoapp/models/vision_item.dart';
import 'package:todoapp/services/hive_user_boxes.dart';
import 'package:uuid/uuid.dart';

class GoalsProvider extends ChangeNotifier {
  final Box<GoalItem> _goals;
  final Box<MilestoneItem> _milestones;
  final Box<ProjectBoard> _boards;
  final Box<KanbanItem> _kanban;
  final Box<VisionItem> _vision;
  final Box<BucketItem> _bucket;
  final Box<OkrObjective> _okrObj;
  final Box<OkrKeyResult> _okrKr;

  final _uuid = const Uuid();

  GoalsProvider({required String userId})
      : _goals = Hive.box<GoalItem>(HiveUserBoxes.name('goal_items', userId)),
        _milestones =
            Hive.box<MilestoneItem>(HiveUserBoxes.name('milestones', userId)),
        _boards =
            Hive.box<ProjectBoard>(HiveUserBoxes.name('project_boards', userId)),
        _kanban =
            Hive.box<KanbanItem>(HiveUserBoxes.name('kanban_items', userId)),
        _vision =
            Hive.box<VisionItem>(HiveUserBoxes.name('vision_items', userId)),
        _bucket =
            Hive.box<BucketItem>(HiveUserBoxes.name('bucket_items', userId)),
        _okrObj =
            Hive.box<OkrObjective>(HiveUserBoxes.name('okr_objectives', userId)),
        _okrKr =
            Hive.box<OkrKeyResult>(HiveUserBoxes.name('okr_key_results', userId)) {
    _ensureDefaultBoard();
  }

  void _ensureDefaultBoard() {
    if (_boards.isEmpty) {
      final id = _uuid.v4();
      _boards.put(
        id,
        ProjectBoard(id: id, title: 'My board', sortOrder: 0),
      );
    }
  }

  // —— Goals ——
  List<GoalItem> get goals => _goals.values.toList()
    ..sort((a, b) {
      final y = b.targetYear.compareTo(a.targetYear);
      if (y != 0) return y;
      final ma = a.targetMonth ?? 0;
      final mb = b.targetMonth ?? 0;
      return mb.compareTo(ma);
    });

  List<MilestoneItem> milestonesForGoal(String goalId) {
    return _milestones.values
        .where((m) => m.parentGoalId == goalId)
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
  }

  /// All milestones (e.g. calendar due dates).
  List<MilestoneItem> get allMilestones => _milestones.values.toList();

  void addGoal({
    required String title,
    String description = '',
    int timeframe = 1,
    required int targetYear,
    int? targetMonth,
  }) {
    final id = _uuid.v4();
    _goals.put(
      id,
      GoalItem(
        id: id,
        title: title,
        description: description,
        timeframe: timeframe,
        targetYear: targetYear,
        targetMonth: targetMonth,
      ),
    );
    notifyListeners();
  }

  void updateGoal(GoalItem g) {
    g.progressPercent = g.progressPercent.clamp(0, 100);
    g.save();
    notifyListeners();
  }

  void deleteGoal(String id) {
    for (final m in _milestones.values.where((x) => x.parentGoalId == id)) {
      m.delete();
    }
    _goals.delete(id);
    notifyListeners();
  }

  void addMilestone({
    required String goalId,
    required String title,
    DateTime? dueDate,
    int progressPercent = 0,
  }) {
    final id = _uuid.v4();
    _milestones.put(
      id,
      MilestoneItem(
        id: id,
        parentGoalId: goalId,
        title: title,
        dueDate: dueDate,
        progressPercent: progressPercent,
      ),
    );
    syncGoalProgressFromMilestones(goalId);
    notifyListeners();
  }

  void updateMilestone(MilestoneItem m) {
    m.progressPercent = m.progressPercent.clamp(0, 100);
    m.save();
    syncGoalProgressFromMilestones(m.parentGoalId);
    notifyListeners();
  }

  void deleteMilestone(String id) {
    final m = _milestones.get(id);
    if (m == null) return;
    final gid = m.parentGoalId;
    m.delete();
    syncGoalProgressFromMilestones(gid);
    notifyListeners();
  }

  /// Sets goal progress to average of milestone % (completed = 100).
  void syncGoalProgressFromMilestones(String goalId) {
    final list = milestonesForGoal(goalId);
    final g = _goals.get(goalId);
    if (g == null) return;
    if (list.isEmpty) {
      notifyListeners();
      return;
    }
    var sum = 0;
    for (final m in list) {
      sum += m.isCompleted ? 100 : m.progressPercent;
    }
    g.progressPercent = (sum / list.length).round().clamp(0, 100);
    g.save();
    notifyListeners();
  }

  // —— Boards / Kanban ——
  List<ProjectBoard> get boards => _boards.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<KanbanItem> itemsForBoard(String boardId, int column) {
    return _kanban.values
        .where((k) => k.boardId == boardId && k.column == column)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  void addBoard(String title) {
    final maxOrder = boards.isEmpty
        ? 0
        : boards.map((b) => b.sortOrder).reduce((a, b) => a > b ? a : b);
    final id = _uuid.v4();
    _boards.put(
      id,
      ProjectBoard(id: id, title: title, sortOrder: maxOrder + 1),
    );
    notifyListeners();
  }

  void updateBoard(ProjectBoard b) {
    b.save();
    notifyListeners();
  }

  void deleteBoard(String boardId) {
    for (final k in _kanban.values.where((x) => x.boardId == boardId)) {
      k.delete();
    }
    _boards.delete(boardId);
    notifyListeners();
  }

  void addKanbanItem({
    required String boardId,
    required String title,
    String notes = '',
    int column = 0,
  }) {
    final colItems = itemsForBoard(boardId, column);
    final nextOrder = colItems.isEmpty
        ? 0
        : colItems.map((k) => k.orderIndex).reduce((a, b) => a > b ? a : b) +
            1;
    final id = _uuid.v4();
    _kanban.put(
      id,
      KanbanItem(
        id: id,
        boardId: boardId,
        title: title,
        notes: notes,
        column: column,
        orderIndex: nextOrder,
      ),
    );
    notifyListeners();
  }

  void moveKanbanItem(String id, int newColumn) {
    final k = _kanban.get(id);
    if (k == null) return;
    newColumn = newColumn.clamp(0, 2);
    k.column = newColumn;
    final colItems = itemsForBoard(k.boardId, newColumn)
      ..removeWhere((x) => x.id == id);
    final nextOrder = colItems.isEmpty
        ? 0
        : colItems.map((x) => x.orderIndex).reduce((a, b) => a > b ? a : b) +
            1;
    k.orderIndex = nextOrder;
    k.save();
    notifyListeners();
  }

  void updateKanbanItem(KanbanItem k) {
    k.column = k.column.clamp(0, 2);
    k.save();
    notifyListeners();
  }

  void deleteKanbanItem(String id) {
    _kanban.delete(id);
    notifyListeners();
  }

  // —— Vision ——
  List<VisionItem> get visionItems => _vision.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void addVisionItem({
    required String title,
    String caption = '',
    String? imagePath,
  }) {
    final list = visionItems;
    final id = _uuid.v4();
    _vision.put(
      id,
      VisionItem(
        id: id,
        title: title,
        caption: caption,
        imagePath: imagePath,
        sortOrder: list.isEmpty
            ? 0
            : list.map((v) => v.sortOrder).reduce((a, b) => a > b ? a : b) + 1,
      ),
    );
    notifyListeners();
  }

  void updateVisionItem(VisionItem v) {
    v.save();
    notifyListeners();
  }

  void deleteVisionItem(String id) {
    _vision.delete(id);
    notifyListeners();
  }

  // —— Bucket ——
  List<BucketItem> get bucketItems => _bucket.values.toList()
    ..sort((a, b) {
      if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
      return a.sortOrder.compareTo(b.sortOrder);
    });

  void addBucketItem({required String title, String notes = ''}) {
    final list = _bucket.values.toList();
    final id = _uuid.v4();
    _bucket.put(
      id,
      BucketItem(
        id: id,
        title: title,
        notes: notes,
        sortOrder: list.isEmpty
            ? 0
            : list.map((b) => b.sortOrder).reduce((a, b) => a > b ? a : b) + 1,
      ),
    );
    notifyListeners();
  }

  void toggleBucketDone(String id) {
    final b = _bucket.get(id);
    if (b == null) return;
    b.isDone = !b.isDone;
    b.completedAt = b.isDone ? DateTime.now() : null;
    b.save();
    notifyListeners();
  }

  void updateBucketItem(BucketItem b) {
    b.save();
    notifyListeners();
  }

  void deleteBucketItem(String id) {
    _bucket.delete(id);
    notifyListeners();
  }

  // —— OKRs ——
  List<OkrObjective> get okrObjectives => _okrObj.values.toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<OkrKeyResult> keyResultsFor(String objectiveId) {
    return _okrKr.values
        .where((k) => k.objectiveId == objectiveId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  double objectiveProgress(String objectiveId) {
    final krs = keyResultsFor(objectiveId);
    if (krs.isEmpty) return 0;
    var sum = 0.0;
    for (final kr in krs) {
      sum += kr.progress;
    }
    return sum / krs.length;
  }

  void addOkrObjective({required String title, String period = ''}) {
    final list = okrObjectives;
    final id = _uuid.v4();
    _okrObj.put(
      id,
      OkrObjective(
        id: id,
        title: title,
        periodLabel: period,
        sortOrder: list.isEmpty
            ? 0
            : list.map((o) => o.sortOrder).reduce((a, b) => a > b ? a : b) + 1,
      ),
    );
    notifyListeners();
  }

  void updateOkrObjective(OkrObjective o) {
    o.save();
    notifyListeners();
  }

  void deleteOkrObjective(String id) {
    for (final kr in _okrKr.values.where((k) => k.objectiveId == id)) {
      kr.delete();
    }
    _okrObj.delete(id);
    notifyListeners();
  }

  void addKeyResult({
    required String objectiveId,
    required String title,
    double target = 100,
    double current = 0,
    String unit = '',
  }) {
    final krs = keyResultsFor(objectiveId);
    final id = _uuid.v4();
    _okrKr.put(
      id,
      OkrKeyResult(
        id: id,
        objectiveId: objectiveId,
        title: title,
        target: target,
        current: current,
        unit: unit,
        sortOrder: krs.isEmpty
            ? 0
            : krs.map((k) => k.sortOrder).reduce((a, b) => a > b ? a : b) + 1,
      ),
    );
    notifyListeners();
  }

  void updateKeyResult(OkrKeyResult kr) {
    kr.save();
    notifyListeners();
  }

  void deleteKeyResult(String id) {
    _okrKr.delete(id);
    notifyListeners();
  }
}
