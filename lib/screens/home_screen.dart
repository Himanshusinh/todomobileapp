import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/screens/calendar_screen.dart';
import 'package:todoapp/screens/finance_screen.dart';
import 'package:todoapp/screens/health_screen.dart';
import 'package:todoapp/screens/notes_screen.dart';
import 'package:todoapp/screens/goals_screen.dart';
import 'package:todoapp/screens/passwords_screen.dart';
import 'package:todoapp/screens/notifications_screen.dart';
import 'package:todoapp/screens/settings_screen.dart';
import 'package:todoapp/screens/task_form_screen.dart';
import 'package:todoapp/widgets/main_app_drawer.dart';
import 'package:todoapp/widgets/task_tile.dart';
import 'package:todoapp/widgets/contrast_choice_chip.dart';
import 'package:todoapp/widgets/scrollable_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// After removing tabs (e.g. Shop), a persisted index can be out of range and
  /// [IndexedStack] shows a blank body. Keep selection valid.
  int get _maxTabIndex => _navDestinations.length - 1;

  int _clampTabIndex(int i) {
    if (_navDestinations.isEmpty) return 0;
    if (i < 0) return 0;
    if (i > _maxTabIndex) return _maxTabIndex;
    return i;
  }

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
    const PasswordsScreen(),
  ];

  void _closeDrawerThen(VoidCallback action) {
    _scaffoldKey.currentState?.closeDrawer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final surface = cs.surface;
    final outline = cs.outlineVariant.withValues(alpha: 0.35);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Space reserved for the floating bottom nav so content/FABs don't overlap it.
    const navHeight = 70.0;
    const navMarginBottom = 10.0;
    final bottomReserve = navHeight + navMarginBottom + bottomInset;
    final safeIndex = _clampTabIndex(_currentIndex);
    if (safeIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = safeIndex);
      });
    }
    final sectionTitle = _navDestinations[safeIndex].label;

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
      body: Stack(
        children: [
          Column(
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
                                sectionTitle,
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
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: surface,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomReserve),
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) {
                        final next = _clampTabIndex(i);
                        if (next == _currentIndex) return;
                        setState(() => _currentIndex = next);
                      },
                      children: _screens,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: SafeArea(
              top: false,
              child: ScrollableBottomNav(
                currentIndex: safeIndex,
                floating: true,
                onDestinationSelected: (index) {
                  final next = _clampTabIndex(index);
                  setState(() => _currentIndex = next);
                  _pageController.animateToPage(
                    next,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                  );
                },
                destinations: _navDestinations,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: safeIndex == 0
          ? Padding(
              padding: EdgeInsets.only(bottom: bottomReserve + 4),
              child: FloatingActionButton.extended(
                heroTag: 'fab_home_new_task',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskFormScreen(),
                  ),
                ),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('New task'),
              ),
            )
          : null,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header is handled by the parent screen; keep list content only here.
        if (_selectionMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Cancel selection',
                  onPressed: () => setState(() {
                    _selectionMode = false;
                    _selectedIds.clear();
                  }),
                  icon: const Icon(Icons.close_rounded),
                ),
                Expanded(
                  child: Text(
                    '${_selectedIds.length} selected',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mark complete',
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  onPressed: () {
                    taskProvider.completeAll(_selectedIds.toList());
                    setState(() {
                      _selectionMode = false;
                      _selectedIds.clear();
                    });
                  },
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () {
                    taskProvider.deleteAll(_selectedIds.toList());
                    setState(() {
                      _selectionMode = false;
                      _selectedIds.clear();
                    });
                  },
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 6),
        Expanded(
          child: Column(
            children: [
          // Filters (Time + Priority)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final cs = theme.colorScheme;

                Widget field({
                  required IconData icon,
                  required String label,
                  required Widget dropdown,
                }) {
                  return Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(child: dropdown),
                      ],
                    ),
                  );
                }

                final timeDropdown = DropdownButtonHideUnderline(
                  child: DropdownButton<TaskFilter>(
                    value: taskProvider.selectedFilter,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more_rounded),
                    borderRadius: BorderRadius.circular(14),
                    dropdownColor: cs.surface,
                    style: theme.textTheme.bodyMedium,
                    items: const [
                      DropdownMenuItem(value: TaskFilter.all, child: Text('All')),
                      DropdownMenuItem(value: TaskFilter.today, child: Text('Today')),
                      DropdownMenuItem(value: TaskFilter.week, child: Text('Week')),
                      DropdownMenuItem(value: TaskFilter.upcoming, child: Text('Upcoming')),
                      DropdownMenuItem(value: TaskFilter.overdue, child: Text('Overdue')),
                      DropdownMenuItem(value: TaskFilter.suggested, child: Text('Suggested')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      taskProvider.selectFilter(v);
                    },
                  ),
                );

                final priorityDropdown = DropdownButtonHideUnderline(
                  child: DropdownButton<TaskPriority?>(
                    value: taskProvider.selectedPriority,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more_rounded),
                    borderRadius: BorderRadius.circular(14),
                    dropdownColor: cs.surface,
                    style: theme.textTheme.bodyMedium,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...TaskPriority.values.map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p.name[0].toUpperCase() + p.name.substring(1),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (p) => taskProvider.selectPriority(p),
                  ),
                );

                return Row(
                  children: [
                    Expanded(
                      child: field(
                        icon: Icons.schedule_rounded,
                        label: 'Time',
                        dropdown: timeDropdown,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: field(
                        icon: Icons.flag_outlined,
                        label: 'Priority',
                        dropdown: priorityDropdown,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Category Selector
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 2),
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

