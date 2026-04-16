import 'package:hive_flutter/hive_flutter.dart';
import 'package:todoapp/models/bill.dart';
import 'package:todoapp/models/brainstorm_idea.dart';
import 'package:todoapp/models/bucket_item.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/models/fitness_goal.dart';
import 'package:todoapp/models/goal_item.dart';
import 'package:todoapp/models/grocery_item.dart';
import 'package:todoapp/models/habit.dart';
import 'package:todoapp/models/habit_log.dart';
import 'package:todoapp/models/journal_entry.dart';
import 'package:todoapp/models/kanban_item.dart';
import 'package:todoapp/models/meal_plan_item.dart';
import 'package:todoapp/models/milestone_item.dart';
import 'package:todoapp/models/monthly_budget.dart';
import 'package:todoapp/models/mood_entry.dart';
import 'package:todoapp/models/okr_key_result.dart';
import 'package:todoapp/models/okr_objective.dart';
import 'package:todoapp/models/password_vault_item.dart';
import 'package:todoapp/models/project_board.dart';
import 'package:todoapp/models/quick_capture.dart';
import 'package:todoapp/models/savings_goal.dart';
import 'package:todoapp/models/sleep_entry.dart';
import 'package:todoapp/models/subscription_item.dart';
import 'package:todoapp/models/task_attachment.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/models/vision_item.dart';
import 'package:todoapp/models/water_day.dart';
import 'package:todoapp/models/weight_entry.dart';
import 'package:todoapp/models/workout_entry.dart';

/// Names Hive boxes per Firebase user so each account has isolated local data.
abstract final class HiveUserBoxes {
  static String name(String base, String uid) => '${base}_$uid';

  /// Close any open boxes, then open all app boxes scoped to [uid].
  static Future<void> openForUser(String uid) async {
    await Hive.close();
    await Future.wait([
      Hive.openBox<TaskItem>(name('tasks', uid)),
      Hive.openBox<Category>(name('categories', uid)),
      Hive.openBox<Bill>(name('bills', uid)),
      Hive.openBox<SubscriptionItem>(name('subscriptions', uid)),
      Hive.openBox<SavingsGoal>(name('savings_goals', uid)),
      Hive.openBox<MonthlyBudget>(name('monthly_budgets', uid)),
      Hive.openBox<Habit>(name('habits', uid)),
      Hive.openBox<HabitLog>(name('habit_logs', uid)),
      Hive.openBox<MoodEntry>(name('moods', uid)),
      Hive.openBox<SleepEntry>(name('sleep', uid)),
      Hive.openBox<WorkoutEntry>(name('workouts', uid)),
      Hive.openBox<MealPlanItem>(name('meals', uid)),
      Hive.openBox<GroceryItem>(name('grocery', uid)),
      Hive.openBox<WaterDay>(name('water_days', uid)),
      Hive.openBox<WeightEntry>(name('weights', uid)),
      Hive.openBox<FitnessGoal>(name('fitness_goals', uid)),
      Hive.openBox<TaskAttachment>(name('task_attachments', uid)),
      Hive.openBox<JournalEntry>(name('journal', uid)),
      Hive.openBox<BrainstormIdea>(name('brainstorm', uid)),
      Hive.openBox<QuickCapture>(name('quick_captures', uid)),
      Hive.openBox<GoalItem>(name('goal_items', uid)),
      Hive.openBox<MilestoneItem>(name('milestones', uid)),
      Hive.openBox<ProjectBoard>(name('project_boards', uid)),
      Hive.openBox<KanbanItem>(name('kanban_items', uid)),
      Hive.openBox<VisionItem>(name('vision_items', uid)),
      Hive.openBox<BucketItem>(name('bucket_items', uid)),
      Hive.openBox<OkrObjective>(name('okr_objectives', uid)),
      Hive.openBox<OkrKeyResult>(name('okr_key_results', uid)),
      Hive.openBox<PasswordVaultItem>(name('password_vault', uid)),
    ]);
  }
}
