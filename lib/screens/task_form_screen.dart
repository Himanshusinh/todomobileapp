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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    
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
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What do you want to do?',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional details',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Core fields kept on one screen (minimal scrolling).
            Text('List', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              value: _categoryId,
              decoration: const InputDecoration(),
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
            const SizedBox(height: 12),

            Text('Priority', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(),
              items: TaskPriority.values
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        p.name[0].toUpperCase() + p.name.substring(1),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (p) {
                if (p == null) return;
                setState(() => _priority = p);
              },
            ),

            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.35)),

            // Everything else goes behind a single compact "Add details" panel.
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 6),
                title: Text('Add details', style: theme.textTheme.titleSmall),
                subtitle: Text(
                  'Schedule, notes, attachments, tags…',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.15,
                  ),
                ),
                children: [
                  // Schedule (compact)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      _dueDate == null
                          ? 'Add due date'
                          : 'Due: ${DateFormat('MMM d, y').format(_dueDate!)}',
                    ),
                    trailing: const Icon(Icons.add_rounded),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (d == null) return;
                      setState(() {
                        _dueDate = d;
                        if (_startTime != null) {
                          _startTime = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            _startTime!.hour,
                            _startTime!.minute,
                          );
                        }
                        if (_endTime != null) {
                          _endTime = DateTime(
                            d.year,
                            d.month,
                            d.day,
                            _endTime!.hour,
                            _endTime!.minute,
                          );
                        }
                      });
                    },
                  ),

                  // Notes (collapsed in UI; field only when user opens panel)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 6),
                    leading: const Icon(Icons.notes_outlined),
                    title: Text('Notes', style: theme.textTheme.titleSmall),
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          FilledButton.tonal(
                            onPressed: () => _wrapNoteSelection('**', '**'),
                            child: const Text('Bold', style: TextStyle(fontSize: 12.5)),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _wrapNoteSelection('*', '*'),
                            child: const Text('Italic', style: TextStyle(fontSize: 12.5)),
                          ),
                          FilledButton.tonal(
                            onPressed: () => _insertNoteText('\n- '),
                            child: const Text('List', style: TextStyle(fontSize: 12.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _noteMarkdownController,
                        decoration: const InputDecoration(
                          hintText: 'Add a note (Markdown supported)',
                          alignLabelWithHint: true,
                        ),
                        minLines: 3,
                        maxLines: 6,
                      ),
                    ],
                  ),

                  // Attachments (compact row + list)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 6),
                    leading: const Icon(Icons.attach_file_rounded),
                    title: Text('Attachments', style: theme.textTheme.titleSmall),
                    children: [
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
                          if (list.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'No attachments',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: list
                                .map((a) => _AttachmentTile(
                                      attachment: a,
                                      notes: notes,
                                    ))
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),

                  // Tags (chips + add)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 6),
                    leading: const Icon(Icons.sell_outlined),
                    title: Text('Tags', style: theme.textTheme.titleSmall),
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _tags
                            .map(
                              (t) => Chip(
                                label: Text(t),
                                onDeleted: () => setState(() => _tags.remove(t)),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagController,
                              decoration: const InputDecoration(hintText: 'Add tag'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () {
                              final v = _tagController.text.trim();
                              if (v.isEmpty) return;
                              setState(() {
                                _tags.add(v);
                                _tagController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Subtasks (list + add)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 6),
                    leading: const Icon(Icons.checklist_rounded),
                    title: Text('Sub-tasks', style: theme.textTheme.titleSmall),
                    children: [
                      ..._subTasks.map(
                        (st) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: st.isCompleted,
                            onChanged: (v) => setState(() => st.isCompleted = v ?? false),
                          ),
                          title: Text(st.title),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() => _subTasks.remove(st)),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subTaskController,
                              decoration: const InputDecoration(hintText: 'Add sub-task'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () {
                              final v = _subTaskController.text.trim();
                              if (v.isEmpty) return;
                              setState(() {
                                _subTasks.add(SubTask(id: const Uuid().v4(), title: v));
                                _subTaskController.clear();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Dependencies (kept but in advanced)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 6),
                    leading: const Icon(Icons.account_tree_outlined),
                    title: Text('Dependencies', style: theme.textTheme.titleSmall),
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: taskProvider.tasks
                            .where((t) => t.id != _taskId)
                            .map(
                              (t) => FilterChip(
                                label: Text(t.title),
                                selected: _dependencies.contains(t.id),
                                onSelected: (val) => setState(() {
                                  if (val) {
                                    _dependencies.add(t.id);
                                  } else {
                                    _dependencies.remove(t.id);
                                  }
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),

                  // Rare fields: expense, estimated time, repeat
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 6),
                    leading: const Icon(Icons.tune_rounded),
                    title: Text('Advanced', style: theme.textTheme.titleSmall),
                    children: [
                      TextFormField(
                        controller: _expenseController,
                        decoration: const InputDecoration(
                          labelText: 'Expense (optional)',
                          hintText: 'e.g. 45.00',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: widget.task?.estimatedMinutes?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Estimated time (minutes)',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => setState(() => widget.task?.estimatedMinutes = int.tryParse(val)),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<RecurringInterval>(
                        value: _recurringInterval,
                        decoration: const InputDecoration(labelText: 'Repeat'),
                        items: RecurringInterval.values
                            .map((i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(i.name),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _recurringInterval = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
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
