import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todoapp/models/sub_task.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/theme_provider.dart';
import 'package:todoapp/providers/pomodoro_provider.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/models/bill.dart';
import 'package:todoapp/models/monthly_budget.dart';
import 'package:todoapp/models/savings_goal.dart';
import 'package:todoapp/models/subscription_item.dart';
import 'package:todoapp/models/habit.dart';
import 'package:todoapp/models/habit_log.dart';
import 'package:todoapp/models/mood_entry.dart';
import 'package:todoapp/models/sleep_entry.dart';
import 'package:todoapp/models/workout_entry.dart';
import 'package:todoapp/models/meal_plan_item.dart';
import 'package:todoapp/models/grocery_item.dart';
import 'package:todoapp/models/water_day.dart';
import 'package:todoapp/models/weight_entry.dart';
import 'package:todoapp/models/fitness_goal.dart';
import 'package:todoapp/models/attachment_kind.dart';
import 'package:todoapp/models/task_attachment.dart';
import 'package:todoapp/models/journal_entry.dart';
import 'package:todoapp/models/brainstorm_idea.dart';
import 'package:todoapp/models/quick_capture.dart';
import 'package:todoapp/models/goal_item.dart';
import 'package:todoapp/models/milestone_item.dart';
import 'package:todoapp/models/project_board.dart';
import 'package:todoapp/models/kanban_item.dart';
import 'package:todoapp/models/vision_item.dart';
import 'package:todoapp/models/bucket_item.dart';
import 'package:todoapp/models/okr_objective.dart';
import 'package:todoapp/models/okr_key_result.dart';
import 'package:todoapp/models/password_vault_item.dart';
import 'package:todoapp/providers/notes_provider.dart';
import 'package:todoapp/screens/auth_gate.dart';
import 'package:todoapp/config/backend_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase (Auth) + Supabase (data). Firebase must be configured per-platform
  // (Android/iOS) for this to succeed.
  await Firebase.initializeApp();
  if (BackendConfig.supabaseUrl.isNotEmpty &&
      BackendConfig.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      anonKey: BackendConfig.supabaseAnonKey,
      accessToken: () async =>
          FirebaseAuth.instance.currentUser?.getIdToken(),
    );
  }

  await Hive.initFlutter();
  await NotesProvider.ensureStorageDirs();

  // Register Adapters (boxes open per user in [HiveUserBoxes.openForUser]).
  Hive.registerAdapter(SubTaskAdapter());
  Hive.registerAdapter(TaskItemAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(RecurringIntervalAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(BillAdapter());
  Hive.registerAdapter(SubscriptionCycleAdapter());
  Hive.registerAdapter(SubscriptionItemAdapter());
  Hive.registerAdapter(SavingsGoalAdapter());
  Hive.registerAdapter(MonthlyBudgetAdapter());
  Hive.registerAdapter(HabitAdapter());
  Hive.registerAdapter(HabitLogAdapter());
  Hive.registerAdapter(MoodEntryAdapter());
  Hive.registerAdapter(SleepEntryAdapter());
  Hive.registerAdapter(WorkoutEntryAdapter());
  Hive.registerAdapter(MealPlanItemAdapter());
  Hive.registerAdapter(GroceryItemAdapter());
  Hive.registerAdapter(WaterDayAdapter());
  Hive.registerAdapter(WeightEntryAdapter());
  Hive.registerAdapter(FitnessGoalAdapter());
  Hive.registerAdapter(AttachmentKindAdapter());
  Hive.registerAdapter(TaskAttachmentAdapter());
  Hive.registerAdapter(JournalEntryAdapter());
  Hive.registerAdapter(BrainstormIdeaAdapter());
  Hive.registerAdapter(QuickCaptureAdapter());
  Hive.registerAdapter(GoalItemAdapter());
  Hive.registerAdapter(MilestoneItemAdapter());
  Hive.registerAdapter(ProjectBoardAdapter());
  Hive.registerAdapter(KanbanItemAdapter());
  Hive.registerAdapter(VisionItemAdapter());
  Hive.registerAdapter(BucketItemAdapter());
  Hive.registerAdapter(OkrObjectiveAdapter());
  Hive.registerAdapter(OkrKeyResultAdapter());
  Hive.registerAdapter(PasswordVaultItemAdapter());

  final prefs = await SharedPreferences.getInstance();
  final initialDark =
      prefs.getBool(ThemeProvider.preferenceKeyDarkMode) ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialIsDark: initialDark),
        ),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
      ],
      child: const AuthGate(),
    ),
  );
}
