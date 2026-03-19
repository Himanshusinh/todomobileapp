import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/providers/theme_provider.dart';
import 'package:todoapp/providers/pomodoro_provider.dart';
import 'package:todoapp/screens/calendar_screen.dart';
import 'package:todoapp/screens/planning_wizard_screen.dart';
import 'package:todoapp/screens/settings_screen.dart';
import 'package:todoapp/screens/task_form_screen.dart';
import 'package:todoapp/widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [const _TaskListView(), const CalendarScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
        ],
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final tasks = taskProvider.tasks;

    return Scaffold(
      appBar: _selectionMode
          ? AppBar(
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
              title: const Text('My Todos'),
              leading: IconButton(
                icon: const Icon(Icons.auto_awesome_outlined, color: Colors.blue),
                tooltip: 'Planning Wizard',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlanningWizardScreen()),
                ),
              ),
              actions: [
                const _PomodoroStatusWidget(),
                IconButton(
                  icon: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
      body: Column(
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
                      child: ChoiceChip(
                        label: Text(
                          f.name[0].toUpperCase() + f.name.substring(1),
                        ),
                        selected: taskProvider.selectedFilter == f,
                        onSelected: (val) => taskProvider.selectFilter(f),
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
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.blue,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TaskFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
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
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: (color ?? Colors.blue).withOpacity(0.2),
        checkmarkColor: color ?? Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? (color ?? Colors.blue) : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
