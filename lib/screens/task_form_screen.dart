import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/category.dart';
import 'package:todoapp/models/sub_task.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskItem? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskPriority _priority;
  late RecurringInterval _recurringInterval;
  DateTime? _dueDate;
  DateTime? _dueTime;
  String? _categoryId;
  DateTime? _startTime;
  DateTime? _endTime;

  final List<SubTask> _subTasks = [];
  final List<String> _tags = [];
  final List<String> _dependencies = [];

  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _subTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? TaskPriority.medium;
    _recurringInterval = widget.task?.recurringInterval ?? RecurringInterval.none;
    _dueDate = widget.task?.dueDate;
    _dueTime = widget.task?.dueTime;
    _categoryId = widget.task?.categoryId;
    _startTime = widget.task?.startTime;
    _endTime = widget.task?.endTime;

    if (widget.task != null) {
      _subTasks.addAll(widget.task!.subTasks.map((st) => SubTask(id: st.id, title: st.title, isCompleted: st.isCompleted)));
      _tags.addAll(widget.task!.tags);
      _dependencies.addAll(widget.task!.dependencies);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final newTask = TaskItem(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        priority: _priority,
        dueDate: _dueDate,
        dueTime: _dueTime,
        recurringInterval: _recurringInterval,
        subTasks: _subTasks,
        tags: _tags,
        dependencies: _dependencies,
        categoryId: _categoryId,
        startTime: _startTime,
        endTime: _endTime,
        durationMinutes: (_startTime != null && _endTime != null) ? _endTime!.difference(_startTime!).inMinutes : null,
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
    final taskProvider = Provider.of<TaskProvider>(context);
    
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
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: widget.task?.estimatedMinutes?.toString() ?? '',
              decoration: const InputDecoration(
                labelText: 'Estimated Time (minutes)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() => widget.task?.estimatedMinutes = int.tryParse(val)),
            ),
            const SizedBox(height: 24),
            
            // Category Selection
            const Text('List / Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _categoryId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Inbox (No List)')),
                ...taskProvider.categories.map((cat) => DropdownMenuItem(
                      value: cat.id,
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 12, color: Color(cat.colorValue)),
                          const SizedBox(width: 8),
                          Text(cat.name),
                        ],
                      ),
                    )),
              ],
              onChanged: (val) => setState(() => _categoryId = val),
            ),
            const SizedBox(height: 24),

            const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: TaskPriority.values.map((p) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: Text(p.name[0].toUpperCase()),
                    selected: _priority == p,
                    onSelected: (val) => setState(() => _priority = p),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 24),

            const Text('Schedule & Time Blocking', style: TextStyle(fontWeight: FontWeight.bold)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_dueDate == null ? 'Set Due Date' : DateFormat('MMM d, y').format(_dueDate!)),
              leading: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (d != null) {
                  setState(() {
                    _dueDate = d;
                    // Auto-set start/end time dates if selected
                    if (_startTime != null) _startTime = DateTime(d.year, d.month, d.day, _startTime!.hour, _startTime!.minute);
                    if (_endTime != null) _endTime = DateTime(d.year, d.month, d.day, _endTime!.hour, _endTime!.minute);
                  });
                }
              },
            ),
            
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_startTime == null ? 'Start Time' : DateFormat('HH:mm').format(_startTime!)),
                    leading: const Icon(Icons.access_time),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (t != null) {
                        final d = _dueDate ?? DateTime.now();
                        setState(() => _startTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                      }
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_endTime == null ? 'End Time' : DateFormat('HH:mm').format(_endTime!)),
                    leading: const Icon(Icons.access_time_filled),
                    onTap: () async {
                      final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                      if (t != null) {
                        final d = _dueDate ?? DateTime.now();
                        setState(() => _endTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                      }
                    },
                  ),
                ),
              ],
            ),

            DropdownButton<RecurringInterval>(
              isExpanded: true,
              value: _recurringInterval,
              items: RecurringInterval.values.map((i) => DropdownMenuItem(value: i, child: Text('Repeat: ${i.name}'))).toList(),
              onChanged: (val) => setState(() => _recurringInterval = val!),
            ),
            const SizedBox(height: 24),

            const Text('Sub-tasks', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._subTasks.map((st) => ListTile(
              leading: Checkbox(value: st.isCompleted, onChanged: (v) => setState(() => st.isCompleted = v!)),
              title: Text(st.title),
              trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _subTasks.remove(st))),
            )),
            Row(
              children: [
                Expanded(child: TextField(controller: _subTaskController, decoration: const InputDecoration(hintText: 'Add sub-task'))),
                IconButton(icon: const Icon(Icons.add), onPressed: () {
                  if (_subTaskController.text.isNotEmpty) {
                    setState(() {
                      _subTasks.add(SubTask(id: const Uuid().v4(), title: _subTaskController.text));
                      _subTaskController.clear();
                    });
                  }
                }),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _tags.map((t) => Chip(label: Text(t), onDeleted: () => setState(() => _tags.remove(t)))).toList(),
            ),
            Row(
              children: [
                Expanded(child: TextField(controller: _tagController, decoration: const InputDecoration(hintText: 'Add tag'))),
                IconButton(icon: const Icon(Icons.add), onPressed: () {
                  if (_tagController.text.isNotEmpty) {
                    setState(() {
                      _tags.add(_tagController.text);
                      _tagController.clear();
                    });
                  }
                }),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Dependencies', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: taskProvider.tasks.where((t) => t.id != widget.task?.id).map((t) => FilterChip(
                label: Text(t.title),
                selected: _dependencies.contains(t.id),
                onSelected: (val) => setState(() => val ? _dependencies.add(t.id) : _dependencies.remove(t.id)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
