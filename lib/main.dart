import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/sub_task.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(SubTaskAdapter());
  Hive.registerAdapter(TaskItemAdapter());
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(RecurringIntervalAdapter());
  Hive.registerAdapter(CategoryAdapter());

  await Hive.openBox<TaskItem>('tasks');
  await Hive.openBox<Category>('categories');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
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
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryBlue = Colors.blue.shade600;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: brightness,
        surface: isDark ? Colors.black : Colors.white,
      ),
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData(brightness: brightness).textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryBlue;
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
      ),
    );
  }
}
