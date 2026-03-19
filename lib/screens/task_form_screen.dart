import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/sub_task.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:uuid/uuid.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskItem? task;
  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late String _description;
  late TaskPriority _priority;
  late DateTime? _dueDate;
  late DateTime? _dueTime;
  late RecurringInterval _recurringInterval;
  late List<SubTask> _subTasks;
  late List<String> _tags;
  late List<String> _dependencies;

  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _subTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = t?.title ?? '';
    _description = t?.description ?? '';
    _priority = t?.priority ?? TaskPriority.medium;
    _dueDate = t?.dueDate;
    _dueTime = t?.dueTime;
    _recurringInterval = t?.recurringInterval ?? RecurringInterval.none;
    _subTasks = t != null ? List.from(t.subTasks) : [];
    _tags = t != null ? List.from(t.tags) : [];
    _dependencies = t != null ? List.from(t.dependencies) : [];
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      final newTask = TaskItem(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _title,
        description: _description,
        priority: _priority,
        dueDate: _dueDate,
        dueTime: _dueTime,
        recurringInterval: _recurringInterval,
        subTasks: _subTasks,
        tags: _tags,
        dependencies: _dependencies,
        isCompleted: widget.task?.isCompleted ?? false,
        orderIndex: widget.task?.orderIndex ?? 0,
      );

      if (widget.task == null) {
        taskProvider.addTask(newTask);
      } else {
        taskProvider.updateTask(newTask);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveForm),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              initialValue: _title,
              decoration: _inputDecoration('Task Title', Icons.title),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onSaved: (v) => _title = v!,
            ),
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              initialValue: _description,
              maxLines: 3,
              decoration: _inputDecoration('Description', Icons.description),
              onSaved: (v) => _description = v ?? '',
            ),
            const SizedBox(height: 24),

            // Priority and Recurring
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TaskPriority>(
                    value: _priority,
                    decoration: _inputDecoration('Priority', Icons.priority_high),
                    items: TaskPriority.values.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name.toUpperCase()),
                    )).toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<RecurringInterval>(
                    value: _recurringInterval,
                    decoration: _inputDecoration('Recurring', Icons.repeat),
                    items: RecurringInterval.values.map((i) => DropdownMenuItem(
                      value: i,
                      child: Text(i.name.toUpperCase()),
                    )).toList(),
                    onChanged: (v) => setState(() => _recurringInterval = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date and Time
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Due Date', style: TextStyle(fontSize: 12)),
                    subtitle: Text(_dueDate == null ? 'None' : DateFormat('yMMMd').format(_dueDate!)),
                    leading: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) setState(() => _dueDate = selected);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Due Time', style: TextStyle(fontSize: 12)),
                    subtitle: Text(_dueTime == null ? 'None' : DateFormat('HH:mm').format(_dueTime!)),
                    leading: const Icon(Icons.access_time),
                    onTap: () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_dueTime ?? DateTime.now()),
                      );
                      if (selected != null) {
                        setState(() {
                          final now = DateTime.now();
                          _dueTime = DateTime(now.year, now.month, now.day, selected.hour, selected.minute);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tags
            Text('Tags', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                )),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(hintText: 'Add...', border: InputBorder.none),
                    onSubmitted: (v) {
                      if (v.isNotEmpty) {
                        setState(() {
                          _tags.add(v);
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Subtasks
            Text('Subtasks', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._subTasks.map((st) => ListTile(
              leading: Checkbox(
                value: st.isCompleted,
                onChanged: (val) => setState(() => st.isCompleted = val!),
              ),
              title: Text(st.title),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _subTasks.remove(st)),
              ),
            )),
            TextField(
              controller: _subTaskController,
              decoration: _inputDecoration('Add Subtask', Icons.add_circle_outline),
              onSubmitted: (v) {
                if (v.isNotEmpty) {
                  setState(() {
                    _subTasks.add(SubTask(id: const Uuid().v4(), title: v));
                    _subTaskController.clear();
                  });
                }
              },
            ),
            
            // Dependencies
            Text('Dependencies (This task can\'t start until these are done)', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Consumer<TaskProvider>(
              builder: (context, provider, _) {
                final otherTasks = provider.tasks.where((t) => t.id != widget.task?.id).toList();
                if (otherTasks.isEmpty) return const Text('No other tasks to depend on.', style: TextStyle(fontSize: 12, color: Colors.grey));
                
                return Wrap(
                  spacing: 8,
                  children: otherTasks.map((t) {
                    final isDep = _dependencies.contains(t.id);
                    return FilterChip(
                      label: Text(t.title),
                      selected: isDep,
                      onSelected: (val) {
                        setState(() {
                          if (val) _dependencies.add(t.id);
                          else _dependencies.remove(t.id);
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            
            const SizedBox(height: 100), // Space at bottom
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
