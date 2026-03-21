import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:todoapp/models/fitness_goal.dart';
import 'package:todoapp/models/grocery_item.dart';
import 'package:todoapp/models/habit.dart';
import 'package:todoapp/models/habit_log.dart';
import 'package:todoapp/models/meal_plan_item.dart';
import 'package:todoapp/models/mood_entry.dart';
import 'package:todoapp/models/sleep_entry.dart';
import 'package:todoapp/models/water_day.dart';
import 'package:todoapp/models/weight_entry.dart';
import 'package:todoapp/models/workout_entry.dart';
import 'package:uuid/uuid.dart';

class HealthProvider extends ChangeNotifier {
  final Box<Habit> _habitBox = Hive.box<Habit>('habits');
  final Box<HabitLog> _habitLogBox = Hive.box<HabitLog>('habit_logs');
  final Box<MoodEntry> _moodBox = Hive.box<MoodEntry>('moods');
  final Box<SleepEntry> _sleepBox = Hive.box<SleepEntry>('sleep');
  final Box<WorkoutEntry> _workoutBox = Hive.box<WorkoutEntry>('workouts');
  final Box<MealPlanItem> _mealBox = Hive.box<MealPlanItem>('meals');
  final Box<GroceryItem> _groceryBox = Hive.box<GroceryItem>('grocery');
  final Box<WaterDay> _waterBox = Hive.box<WaterDay>('water_days');
  final Box<WeightEntry> _weightBox = Hive.box<WeightEntry>('weights');
  final Box<FitnessGoal> _fitnessGoalBox = Hive.box<FitnessGoal>('fitness_goals');

  final _uuid = const Uuid();

  static const int defaultWaterGoalMl = 2000;
  static const int waterGlassMl = 250;

  HealthProvider() {
    _seedDefaultHabitsIfEmpty();
  }

  void _seedDefaultHabitsIfEmpty() {
    if (_habitBox.isNotEmpty) return;
    final seeds = [
      (title: 'Drink water', color: 0xFF03A9F4),
      (title: 'Exercise', color: 0xFF4CAF50),
      (title: 'Meditate', color: 0xFF9C27B0),
    ];
    for (var i = 0; i < seeds.length; i++) {
      final h = Habit(
        id: _uuid.v4(),
        title: seeds[i].title,
        colorValue: seeds[i].color,
        orderIndex: i,
      );
      _habitBox.put(h.id, h);
    }
  }

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get todayKey => dateKey(DateTime.now());

  List<Habit> get habits =>
      _habitBox.values.toList()..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  bool isHabitDone(String habitId, String key) {
    final log = _habitLogBox.get(HabitLog.composeKey(habitId, key));
    return log?.completed == true;
  }

  /// Consecutive completed days ending at [end] (inclusive).
  int streakForHabit(String habitId, [DateTime? end]) {
    var day = end ?? DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    var n = 0;
    while (isHabitDone(habitId, dateKey(day))) {
      n++;
      day = day.subtract(const Duration(days: 1));
    }
    return n;
  }

  void toggleHabitDay(String habitId, String key) {
    final id = HabitLog.composeKey(habitId, key);
    final existing = _habitLogBox.get(id);
    if (existing?.completed == true) {
      _habitLogBox.delete(id);
    } else {
      _habitLogBox.put(
        id,
        HabitLog(habitId: habitId, dateKey: key, completed: true),
      );
    }
    notifyListeners();
  }

  void addHabit(String title, int colorValue) {
    final maxOrder = _habitBox.isEmpty
        ? -1
        : _habitBox.values.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b);
    final h = Habit(
      id: _uuid.v4(),
      title: title,
      colorValue: colorValue,
      orderIndex: maxOrder + 1,
    );
    _habitBox.put(h.id, h);
    notifyListeners();
  }

  void deleteHabit(String id) {
    for (final key in _habitLogBox.keys.toList()) {
      final log = _habitLogBox.get(key);
      if (log?.habitId == id) _habitLogBox.delete(key);
    }
    _habitBox.delete(id);
    notifyListeners();
  }

  MoodEntry? moodFor(String key) => _moodBox.get(key);

  void setMood(String key, int level, [String note = '']) {
    _moodBox.put(
      key,
      MoodEntry(id: key, dateKey: key, moodLevel: level.clamp(0, 4), note: note),
    );
    notifyListeners();
  }

  SleepEntry? sleepFor(String key) => _sleepBox.get(key);

  void setSleep(String key, double hours, {int? quality, String note = ''}) {
    _sleepBox.put(
      key,
      SleepEntry(
        id: key,
        dateKey: key,
        hoursSlept: hours,
        quality: quality,
        note: note,
      ),
    );
    notifyListeners();
  }

  List<WorkoutEntry> get workouts {
    final list = _workoutBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  void addWorkout(String title, DateTime date, int durationMin, {String notes = ''}) {
    final w = WorkoutEntry(
      id: _uuid.v4(),
      date: date,
      title: title,
      durationMinutes: durationMin,
      notes: notes,
    );
    _workoutBox.put(w.id, w);
    notifyListeners();
  }

  void deleteWorkout(String id) {
    _workoutBox.delete(id);
    notifyListeners();
  }

  List<MealPlanItem> mealsFor(String key) {
    return _mealBox.values.where((m) => m.dateKey == key).toList()
      ..sort((a, b) => a.mealType.compareTo(b.mealType));
  }

  void setMeal(String dateKey, int mealType, String description) {
    final existing = _mealBox.values.where((m) => m.dateKey == dateKey && m.mealType == mealType).toList();
    for (final e in existing) {
      _mealBox.delete(e.id);
    }
    if (description.trim().isEmpty) {
      notifyListeners();
      return;
    }
    final m = MealPlanItem(
      id: _uuid.v4(),
      dateKey: dateKey,
      mealType: mealType,
      description: description.trim(),
    );
    _mealBox.put(m.id, m);
    notifyListeners();
  }

  List<GroceryItem> get groceryItems {
    final list = _groceryBox.values.toList();
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  void addGrocery(String title) {
    final maxOrder = _groceryBox.isEmpty
        ? -1
        : _groceryBox.values.map((e) => e.orderIndex).reduce((a, b) => a > b ? a : b);
    final g = GroceryItem(
      id: _uuid.v4(),
      title: title,
      orderIndex: maxOrder + 1,
    );
    _groceryBox.put(g.id, g);
    notifyListeners();
  }

  void toggleGrocery(String id) {
    final g = _groceryBox.get(id);
    if (g != null) {
      g.isChecked = !g.isChecked;
      _groceryBox.put(id, g);
      notifyListeners();
    }
  }

  void deleteGrocery(String id) {
    _groceryBox.delete(id);
    notifyListeners();
  }

  void clearCheckedGroceries() {
    for (final id in _groceryBox.keys.toList()) {
      final g = _groceryBox.get(id);
      if (g?.isChecked == true) _groceryBox.delete(id);
    }
    notifyListeners();
  }

  int waterTotalMl(String key) => _waterBox.get(key)?.totalMl ?? 0;

  void addWaterMl(String key, int ml) {
    final existing = _waterBox.get(key);
    final w = existing ?? WaterDay(id: key);
    w.totalMl = (w.totalMl + ml).clamp(0, 20000);
    _waterBox.put(key, w);
    notifyListeners();
  }

  void setWaterMl(String key, int ml) {
    final existing = _waterBox.get(key);
    final w = existing ?? WaterDay(id: key);
    w.totalMl = ml.clamp(0, 20000);
    _waterBox.put(key, w);
    notifyListeners();
  }

  List<WeightEntry> get weightEntries {
    final list = _weightBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double? get latestWeightKg =>
      weightEntries.isEmpty ? null : weightEntries.first.weightKg;

  void addWeight(DateTime date, double kg, {String note = ''}) {
    final e = WeightEntry(
      id: _uuid.v4(),
      date: date,
      weightKg: kg,
      note: note,
    );
    _weightBox.put(e.id, e);
    notifyListeners();
  }

  void deleteWeight(String id) {
    _weightBox.delete(id);
    notifyListeners();
  }

  List<FitnessGoal> get fitnessGoals => _fitnessGoalBox.values.toList();

  void addFitnessGoal(String title, double targetKg, {double? startKg}) {
    final g = FitnessGoal(
      id: _uuid.v4(),
      title: title,
      targetWeightKg: targetKg,
      startWeightKg: startKg ?? latestWeightKg,
    );
    _fitnessGoalBox.put(g.id, g);
    notifyListeners();
  }

  void deleteFitnessGoal(String id) {
    _fitnessGoalBox.delete(id);
    notifyListeners();
  }

  String newId() => _uuid.v4();
}
