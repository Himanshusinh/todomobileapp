import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/providers/theme_provider.dart';
import 'package:todoapp/screens/settings_screen.dart';
import 'package:todoapp/screens/task_form_screen.dart';
import 'package:todoapp/widgets/task_tile.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
              actions: [
                IconButton(
                  icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () => themeProvider.toggleTheme(),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ),
                ),
              ],
            ),
      body: Column(
        children: [
          // Category Selector
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: taskProvider.selectedCategoryId == null,
                  onTap: () => taskProvider.selectCategory(null),
                ),
                ...taskProvider.categories.map((cat) => _CategoryChip(
                      label: cat.name,
                      isSelected: taskProvider.selectedCategoryId == cat.id,
                      color: Color(cat.colorValue),
                      onTap: () => taskProvider.selectCategory(cat.id),
                    )),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  onPressed: () => _showAddCategoryDialog(context, taskProvider),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const Center(child: Text('No tasks yet. Add one!'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                builder: (context) => TaskFormScreen(task: task),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addCategory(Category(
                  id: const Uuid().v4(),
                  name: controller.text,
                  iconCode: Icons.list.codePoint,
                  colorValue: Colors.blue.value,
                ));
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
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
