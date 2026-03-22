import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/providers/pomodoro_provider.dart';
import 'package:todoapp/screens/calendar_screen.dart';
import 'package:todoapp/screens/planning_wizard_screen.dart';
import 'package:todoapp/screens/finance_screen.dart';
import 'package:todoapp/screens/health_screen.dart';
import 'package:todoapp/screens/notes_screen.dart';
import 'package:todoapp/screens/goals_screen.dart';
import 'package:todoapp/screens/shopping_screen.dart';
import 'package:todoapp/screens/passwords_screen.dart';
import 'package:todoapp/screens/notifications_screen.dart';
import 'package:todoapp/screens/settings_screen.dart';
import 'package:todoapp/screens/task_form_screen.dart';
import 'package:todoapp/widgets/main_app_drawer.dart';
import 'package:todoapp/widgets/task_tile.dart';
import 'package:todoapp/widgets/contrast_choice_chip.dart';
import 'package:todoapp/widgets/luxury_status_dot.dart';
import 'package:todoapp/widgets/scrollable_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static final List<NavDestinationData> _navDestinations = [
    const NavDestinationData(
      icon: Icons.task_alt_outlined,
      selectedIcon: Icons.task_alt_rounded,
      label: 'Tasks',
    ),
    const NavDestinationData(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      label: 'Finance',
    ),
    const NavDestinationData(
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite_rounded,
      label: 'Health',
    ),
    const NavDestinationData(
      icon: Icons.edit_note_outlined,
      selectedIcon: Icons.edit_note_rounded,
      label: 'Notes',
    ),
    const NavDestinationData(
      icon: Icons.flag_outlined,
      selectedIcon: Icons.flag_rounded,
      label: 'Goals',
    ),
    const NavDestinationData(
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      label: 'Shop',
    ),
    const NavDestinationData(
      icon: Icons.key_outlined,
      selectedIcon: Icons.key_rounded,
      label: 'Vault',
    ),
  ];

  final List<Widget> _screens = [
    const _TaskListView(),
    const FinanceScreen(),
    const HealthScreen(),
    const NotesScreen(),
    const GoalsScreen(),
    const ShoppingScreen(),
    const PasswordsScreen(),
  ];

  void _closeDrawerThen(VoidCallback action) {
    _scaffoldKey.currentState?.closeDrawer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final surface = cs.surface;
    final outline = cs.outlineVariant.withValues(alpha: 0.35);
    final sectionTitle = _navDestinations[_currentIndex].label;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Consumer<TaskProvider>(
        builder: (context, tp, _) {
          return MainAppDrawer(
            notificationCount: NotificationsScreen.countAlertTasks(tp),
            onCalendar: () {
              _closeDrawerThen(() {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              });
            },
            onNotifications: () {
              _closeDrawerThen(() {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              });
            },
            onSettings: () {
              _closeDrawerThen(() {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              });
            },
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: cs.surface,
            elevation: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  bottom: BorderSide(color: outline),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Menu',
                        style: IconButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          backgroundColor: cs.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        icon: const Icon(Icons.menu_rounded, size: 24),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, anim) {
                            return FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.08),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic,
                                )),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            'Luxury Todo · $sectionTitle',
                            key: ValueKey<String>(sectionTitle),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.15,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 48,
                        child: Center(
                          child: LuxuryStatusDot(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: surface,
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'fab_home_new_task',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TaskFormScreen(),
                ),
              ),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('New task'),
            )
          : null,
      bottomNavigationBar: ScrollableBottomNav(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: _navDestinations,
      ),
    );
  }
}

class _TaskListView extends StatefulWidget {
  const _TaskListView();

  @override
  State<_TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<_TaskListView> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;

    final appBarBg =
        Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: appBarBg,
          elevation: 0,
          child: SafeArea(
            top: false,
            bottom: false,
            child: _selectionMode
                ? AppBar(
                    primary: false,
                    toolbarHeight: 48,
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _selectionMode = false;
                        _selectedIds.clear();
                      }),
                    ),
                    title: Text('${_selectedIds.length} selected'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () {
                          taskProvider.completeAll(_selectedIds.toList());
                          setState(() {
                            _selectionMode = false;
                            _selectedIds.clear();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          taskProvider.deleteAll(_selectedIds.toList());
                          setState(() {
                            _selectionMode = false;
                            _selectedIds.clear();
                          });
                        },
                      ),
                    ],
                  )
                : AppBar(
                    primary: false,
                    toolbarHeight: 48,
                    title: const Text('My Todos'),
                    leading: IconButton(
                      icon: Icon(
                        Icons.auto_awesome_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Planning Wizard',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlanningWizardScreen(),
                        ),
                      ),
                    ),
                    actions: const [
                      _PomodoroStatusWidget(),
                    ],
                  ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
          // Smart Filters
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: TaskFilter.values
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ContrastChoiceChip(
                        label:
                            f.name[0].toUpperCase() + f.name.substring(1),
                        selected: taskProvider.selectedFilter == f,
                        onSelected: (v) {
                          if (v) taskProvider.selectFilter(f);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Category Selector
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All Lists',
                  isSelected: taskProvider.selectedCategoryId == null,
                  onTap: () => taskProvider.selectCategory(null),
                ),
                ...taskProvider.categories.map(
                  (cat) => _CategoryChip(
                    label: cat.name,
                    isSelected: taskProvider.selectedCategoryId == cat.id,
                    color: Color(cat.colorValue),
                    onTap: () => taskProvider.selectCategory(cat.id),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  onPressed: () =>
                      _showAddCategoryDialog(context, taskProvider),
                ),
              ],
            ),
          ),

          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks yet. Add one!'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: tasks.length,
                    onReorder: taskProvider.reorderTasks,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskTile(
                        key: ValueKey(task.id),
                        task: task,
                        isSelectionMode: _selectionMode,
                        isSelected: _selectedIds.contains(task.id),
                        onLongPress: () {
                          if (!_selectionMode) {
                            setState(() {
                              _selectionMode = true;
                              _selectedIds.add(task.id);
                            });
                          }
                        },
                        onTap: () {
                          if (_selectionMode) {
                            _toggleSelection(task.id);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TaskFormScreen(task: task),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context, TaskProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter list name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addCategory(
                  Category(
                    id: const Uuid().v4(),
                    name: controller.text,
                    iconCode: Icons.list.codePoint,
                    colorValue: Colors.blue.value,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ContrastChoiceChip(
        label: label,
        selected: isSelected,
        accentColor: color,
        onSelected: (v) {
          if (v) onTap();
        },
      ),
    );
  }
}

class _PomodoroStatusWidget extends StatelessWidget {
  const _PomodoroStatusWidget();

  @override
  Widget build(BuildContext context) {
    final pomodoro = Provider.of<PomodoroProvider>(context);
    return GestureDetector(
      onTap: () => pomodoro.toggleTimer(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: pomodoro.isRunning 
            ? (pomodoro.currentState == PomodoroState.focus ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1))
            : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              pomodoro.isRunning ? Icons.timer : Icons.timer_outlined,
              size: 16,
              color: pomodoro.isRunning 
                ? (pomodoro.currentState == PomodoroState.focus ? Colors.blue : Colors.green)
                : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              pomodoro.timerString,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: pomodoro.isRunning 
                  ? (pomodoro.currentState == PomodoroState.focus ? Colors.blue : Colors.green)
                  : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
