import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:todoapp/models/attachment_kind.dart';
import 'package:todoapp/models/sub_task.dart';
import 'package:todoapp/models/task_item.dart';
import 'package:todoapp/models/task_attachment.dart';
import 'package:todoapp/providers/notes_provider.dart';
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
  late final TextEditingController _expenseController;
  late final TextEditingController _noteMarkdownController;
  late String _taskId;
  final AudioRecorder _voiceRecorder = AudioRecorder();
  bool _recordingVoice = false;
  NotesProvider? _notes;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _taskId = widget.task?.id ?? const Uuid().v4();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _noteMarkdownController = TextEditingController(text: widget.task?.noteMarkdown ?? '');
    _expenseController = TextEditingController(
      text: widget.task?.expenseAmount != null
          ? widget.task!.expenseAmount!.toStringAsFixed(2)
          : '',
    );
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notes ??= context.read<NotesProvider>();
  }

  @override
  void dispose() {
    if (widget.task == null && !_saved) {
      _notes?.deleteAttachmentsForTask(_taskId);
    }
    _voiceRecorder.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _noteMarkdownController.dispose();
    _tagController.dispose();
    _subTaskController.dispose();
    _expenseController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final exp = double.tryParse(_expenseController.text.replaceAll(',', '').trim());
      final newTask = TaskItem(
        id: _taskId,
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
        isCompleted: widget.task?.isCompleted ?? false,
        orderIndex: widget.task?.orderIndex ?? 0,
        estimatedMinutes: widget.task?.estimatedMinutes,
        actualMinutes: widget.task?.actualMinutes,
        isFavorited: widget.task?.isFavorited ?? false,
        expenseAmount: (exp != null && exp > 0) ? exp : null,
        noteMarkdown: _noteMarkdownController.text,
      );

      if (widget.task == null) {
        taskProvider.addTask(newTask);
      } else {
        taskProvider.updateTask(newTask);
      }
      _saved = true;
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
              controller: _expenseController,
              decoration: const InputDecoration(
                labelText: 'Expense amount (optional)',
                hintText: 'e.g. 45.00 for groceries',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 24),
            const Text('Notes (Markdown)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                FilledButton.tonal(
                  onPressed: () => _wrapNoteSelection('**', '**'),
                  child: const Text('Bold'),
                ),
                FilledButton.tonal(
                  onPressed: () => _wrapNoteSelection('*', '*'),
                  child: const Text('Italic'),
                ),
                FilledButton.tonal(
                  onPressed: () => _insertNoteText('\n- '),
                  child: const Text('List'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteMarkdownController,
              decoration: const InputDecoration(
                labelText: 'Rich text note',
                hintText: '**Bold**, *italic*, - list items',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 10,
            ),
            const SizedBox(height: 12),
            const Text('Attachments', style: TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Photo',
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                ),
                IconButton.filledTonal(
                  tooltip: 'File',
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                ),
                IconButton.filledTonal(
                  tooltip: _recordingVoice ? 'Stop' : 'Voice note',
                  onPressed: _toggleVoice,
                  icon: Icon(_recordingVoice ? Icons.stop : Icons.mic_none),
                ),
              ],
            ),
            Consumer<NotesProvider>(
              builder: (context, notes, _) {
                final list = notes.attachmentsForTask(_taskId);
                if (list.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: list.map((a) => _AttachmentTile(attachment: a, notes: notes)).toList(),
                );
              },
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
              children: taskProvider.tasks.where((t) => t.id != _taskId).map((t) => FilterChip(
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

  void _wrapNoteSelection(String left, String right) {
    final t = _noteMarkdownController;
    final s = t.selection;
    if (!s.isValid) return;
    final text = t.text;
    final inner = s.isCollapsed ? '' : text.substring(s.start, s.end);
    final replacement = '$left$inner$right';
    final newText = text.replaceRange(s.start, s.end, replacement);
    t.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: s.start + replacement.length),
    );
  }

  void _insertNoteText(String snippet) {
    final t = _noteMarkdownController;
    final sel = t.selection;
    if (!sel.isValid) return;
    final start = sel.start;
    final text = t.text;
    final newText = text.replaceRange(start, start, snippet);
    t.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + snippet.length),
    );
  }

  Future<void> _pickImage() async {
    final notes = context.read<NotesProvider>();
    await NotesProvider.ensureStorageDirs();
    final pick = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pick == null || !mounted) return;
    await notes.addAttachmentFromPath(
      taskId: _taskId,
      sourcePath: pick.path,
      kind: AttachmentKind.image,
      displayName: pick.name,
    );
    setState(() {});
  }

  Future<void> _pickFile() async {
    final notes = context.read<NotesProvider>();
    await NotesProvider.ensureStorageDirs();
    final res = await FilePicker.platform.pickFiles();
    if (res == null || res.files.isEmpty || !mounted) return;
    final f = res.files.single;
    final path = f.path;
    if (path == null) return;
    await notes.addAttachmentFromPath(
      taskId: _taskId,
      sourcePath: path,
      kind: AttachmentKind.file,
      displayName: f.name,
    );
    setState(() {});
  }

  Future<void> _toggleVoice() async {
    final notes = context.read<NotesProvider>();
    if (_recordingVoice) {
      final path = await _voiceRecorder.stop();
      setState(() => _recordingVoice = false);
      if (path != null && mounted) {
        notes.addAttachmentAtPath(
          taskId: _taskId,
          absolutePath: path,
          kind: AttachmentKind.voice,
          displayName: 'Voice ${DateFormat('MMM d H:mm').format(DateTime.now())}',
        );
        setState(() {});
      }
      return;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted || !mounted) return;
    await NotesProvider.ensureStorageDirs();
    if (!await _voiceRecorder.hasPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/recordings/${const Uuid().v4()}.m4a';
    await _voiceRecorder.start(const RecordConfig(), path: filePath);
    setState(() => _recordingVoice = true);
  }
}

class _AttachmentTile extends StatelessWidget {
  final TaskAttachment attachment;
  final NotesProvider notes;

  const _AttachmentTile({required this.attachment, required this.notes});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _leading(),
      title: Text(attachment.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(attachment.kind.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attachment.kind == AttachmentKind.voice)
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () async {
                final ap = AudioPlayer();
                await ap.play(DeviceFileSource(attachment.localPath));
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => notes.deleteAttachment(attachment.id),
          ),
        ],
      ),
    );
  }

  Widget _leading() {
    switch (attachment.kind) {
      case AttachmentKind.image:
        final f = File(attachment.localPath);
        if (f.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(f, width: 48, height: 48, fit: BoxFit.cover),
          );
        }
        return const Icon(Icons.image_not_supported);
      case AttachmentKind.voice:
        return const Icon(Icons.graphic_eq);
      case AttachmentKind.file:
        return const Icon(Icons.insert_drive_file_outlined);
    }
  }
}
