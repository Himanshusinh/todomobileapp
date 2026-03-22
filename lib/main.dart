import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoapp/models/sub_task.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/providers/theme_provider.dart';
import 'package:todoapp/providers/pomodoro_provider.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/models/bill.dart';
import 'package:todoapp/models/monthly_budget.dart';
import 'package:todoapp/models/savings_goal.dart';
import 'package:todoapp/models/subscription_item.dart';
import 'package:todoapp/providers/finance_provider.dart';
import 'package:todoapp/providers/health_provider.dart';
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
import 'package:todoapp/models/shop_category.dart';
import 'package:todoapp/models/shopping_list_item.dart';
import 'package:todoapp/models/home_inventory_item.dart';
import 'package:todoapp/models/wishlist_item.dart';
import 'package:todoapp/models/password_vault_item.dart';
import 'package:todoapp/providers/notes_provider.dart';
import 'package:todoapp/providers/password_vault_provider.dart';
import 'package:todoapp/providers/goals_provider.dart';
import 'package:todoapp/providers/shopping_provider.dart';
import 'package:todoapp/screens/home_screen.dart';
import 'package:todoapp/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await NotesProvider.ensureStorageDirs();

  // Register Adapters
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
  Hive.registerAdapter(ShopCategoryAdapter());
  Hive.registerAdapter(ShoppingListItemAdapter());
  Hive.registerAdapter(HomeInventoryItemAdapter());
  Hive.registerAdapter(WishlistItemAdapter());
  Hive.registerAdapter(PasswordVaultItemAdapter());

  await Hive.openBox<TaskItem>('tasks');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Bill>('bills');
  await Hive.openBox<SubscriptionItem>('subscriptions');
  await Hive.openBox<SavingsGoal>('savings_goals');
  await Hive.openBox<MonthlyBudget>('monthly_budgets');
  await Hive.openBox<Habit>('habits');
  await Hive.openBox<HabitLog>('habit_logs');
  await Hive.openBox<MoodEntry>('moods');
  await Hive.openBox<SleepEntry>('sleep');
  await Hive.openBox<WorkoutEntry>('workouts');
  await Hive.openBox<MealPlanItem>('meals');
  await Hive.openBox<GroceryItem>('grocery');
  await Hive.openBox<WaterDay>('water_days');
  await Hive.openBox<WeightEntry>('weights');
  await Hive.openBox<FitnessGoal>('fitness_goals');
  await Hive.openBox<TaskAttachment>('task_attachments');
  await Hive.openBox<JournalEntry>('journal');
  await Hive.openBox<BrainstormIdea>('brainstorm');
  await Hive.openBox<QuickCapture>('quick_captures');
  await Hive.openBox<GoalItem>('goal_items');
  await Hive.openBox<MilestoneItem>('milestones');
  await Hive.openBox<ProjectBoard>('project_boards');
  await Hive.openBox<KanbanItem>('kanban_items');
  await Hive.openBox<VisionItem>('vision_items');
  await Hive.openBox<BucketItem>('bucket_items');
  await Hive.openBox<OkrObjective>('okr_objectives');
  await Hive.openBox<OkrKeyResult>('okr_key_results');
  await Hive.openBox<ShopCategory>('shop_categories');
  await Hive.openBox<ShoppingListItem>('shopping_items');
  await Hive.openBox<HomeInventoryItem>('home_inventory');
  await Hive.openBox<WishlistItem>('wishlist_items');
  await Hive.openBox<PasswordVaultItem>('password_vault');

  final prefs = await SharedPreferences.getInstance();
  final initialDark =
      prefs.getBool(ThemeProvider.preferenceKeyDarkMode) ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialIsDark: initialDark),
        ),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider(create: (_) => GoalsProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingProvider()),
        ChangeNotifierProvider(create: (_) => PasswordVaultProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Luxury Todo',
      debugShowCheckedModeBanner: false,
      theme: LuxuryAppTheme.theme(Brightness.light),
      darkTheme: LuxuryAppTheme.theme(Brightness.dark),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}
