import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/brainstorm_idea.dart';
import 'package:todoapp/models/journal_entry.dart';
import 'package:todoapp/models/quick_capture.dart';
import 'package:todoapp/providers/notes_provider.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarBg = theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: appBarBg,
          elevation: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: Center(
                    child: Text(
                      'Notes & Journal',
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(text: 'Journal'),
                    Tab(text: 'Ideas'),
                    Tab(text: 'Capture'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _JournalTab(),
              _BrainstormTab(),
              _QuickCaptureTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _JournalTab extends StatefulWidget {
  const _JournalTab();

  @override
  State<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<_JournalTab> {
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _day = DateTime(n.year, n.month, n.day);
  }

  String get _key => NotesProvider.dateKey(_day);

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>();
    final entries = notes.journalForDay(_key);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(onPressed: () => setState(() => _day = _day.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMM d').format(_day),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(onPressed: () => setState(() => _day = _day.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_right)),
            IconButton(
              icon: const Icon(Icons.today_outlined),
              onPressed: () {
                final n = DateTime.now();
                setState(() => _day = DateTime(n.year, n.month, n.day));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Daily journal — markdown supported (**bold**, *italic*, lists).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _openJournalEditor(context, null),
          icon: const Icon(Icons.add),
          label: const Text('New entry for this day'),
        ),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No entries yet.')),
          )
        else
          ...entries.map((e) => Card(
                child: ListTile(
                  title: Text(e.title.isEmpty ? '(untitled)' : e.title),
                  subtitle: Text(
                    e.bodyMarkdown.length > 120 ? '${e.bodyMarkdown.substring(0, 120)}…' : e.bodyMarkdown,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notes.deleteJournalEntry(e.id),
                  ),
                  onTap: () => _openJournalEditor(context, e),
                ),
              )),
        const SizedBox(height: 24),
        const Divider(),
        ListTile(
          title: const Text('All entries'),
          subtitle: const Text('Browse recent'),
        ),
        ...notes.allJournalEntries.take(15).map((e) => ListTile(
              dense: true,
              title: Text(e.title.isEmpty ? e.dateKey : e.title),
              subtitle: Text(DateFormat('MMM d, y').format(e.updatedAt)),
              onTap: () => _openJournalEditor(context, e),
            )),
      ],
    );
  }

  Future<void> _openJournalEditor(BuildContext context, JournalEntry? existing) async {
    final notes = context.read<NotesProvider>();
    final titleC = TextEditingController(text: existing?.title ?? '');
    final bodyC = TextEditingController(text: existing?.bodyMarkdown ?? '');
    final dateKey = existing?.dateKey ?? _key;

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setSt) => ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Journal entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                    FilledButton(
                      onPressed: () {
                        final now = DateTime.now();
                        if (existing != null) {
                          existing.title = titleC.text.trim();
                          existing.bodyMarkdown = bodyC.text;
                          existing.updatedAt = now;
                          notes.saveJournalEntry(existing);
                        } else {
                          notes.addJournalEntry(
                            dateKey,
                            title: titleC.text.trim(),
                            body: bodyC.text,
                          );
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(labelText: 'Title (optional)', border: OutlineInputBorder()),
                  onChanged: (_) => setSt(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyC,
                  decoration: const InputDecoration(
                    labelText: 'Markdown body',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  minLines: 6,
                  maxLines: 14,
                  onChanged: (_) => setSt(() {}),
                ),
                const SizedBox(height: 16),
                Text('Preview', style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                MarkdownBody(data: bodyC.text.isEmpty ? '_Empty_' : bodyC.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrainstormTab extends StatelessWidget {
  const _BrainstormTab();

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>();
    final ideas = notes.brainstormIdeas;

    return Stack(
      children: [
        ideas.isEmpty
            ? const Center(child: Text('Tap + to add a card. Rearrange ideas freely.'))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: ideas.length,
                itemBuilder: (ctx, i) {
                  final idea = ideas[i];
                  final color = Color(idea.colorValue);
                  return Card(
                    color: color.withValues(alpha: 0.2),
                    child: InkWell(
                      onTap: () => _editIdea(context, idea),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              idea.title.isEmpty ? 'Idea' : idea.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                idea.content,
                                maxLines: 6,
                                overflow: TextOverflow.fade,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _editIdea(context, null),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _editIdea(BuildContext context, BrainstormIdea? existing) async {
    final notes = context.read<NotesProvider>();
    final titleC = TextEditingController(text: existing?.title ?? '');
    final bodyC = TextEditingController(text: existing?.content ?? '');
    int color = existing?.colorValue ?? 0xFF2196F3;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(existing == null ? 'New idea' : 'Edit idea'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: bodyC, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 4),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    0xFF2196F3,
                    0xFF4CAF50,
                    0xFFE91E63,
                    0xFFFF9800,
                    0xFF9C27B0,
                  ].map((c) {
                    final sel = color == c;
                    return GestureDetector(
                      onTap: () => setSt(() => color = c),
                      child: CircleAvatar(
                        backgroundColor: Color(c),
                        radius: 16,
                        child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () {
                  notes.deleteBrainstormIdea(existing.id);
                  Navigator.pop(ctx);
                },
                child: const Text('Delete'),
              ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (existing != null) {
                  existing.title = titleC.text.trim().isEmpty ? 'Idea' : titleC.text.trim();
                  existing.content = bodyC.text;
                  existing.colorValue = color;
                  notes.updateBrainstormIdea(existing);
                } else {
                  notes.addBrainstormIdea(
                    titleC.text.trim().isEmpty ? 'Idea' : titleC.text.trim(),
                    content: bodyC.text,
                    color: color,
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCaptureTab extends StatelessWidget {
  const _QuickCaptureTab();

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>();
    final items = notes.quickCaptures;

    return Stack(
      children: [
        items.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Brain dump — quick thoughts without a date. Open from + '),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final q = items[i];
                  return Card(
                    child: ListTile(
                      title: Text(q.body, maxLines: 4, overflow: TextOverflow.ellipsis),
                      subtitle: Text(DateFormat('MMM d, h:mm a').format(q.createdAt)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => notes.deleteQuickCapture(q.id),
                      ),
                      onTap: () => _editCapture(context, q),
                    ),
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _newCapture(context),
            icon: const Icon(Icons.bolt),
            label: const Text('Quick add'),
          ),
        ),
      ],
    );
  }

  void _newCapture(BuildContext context) {
    final notes = context.read<NotesProvider>();
    final c = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Quick capture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: c,
              autofocus: true,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(hintText: 'Type anything…', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                notes.addQuickCapture(c.text);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editCapture(BuildContext context, QuickCapture q) {
    final notes = context.read<NotesProvider>();
    final c = TextEditingController(text: q.body);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit capture'),
            TextField(controller: c, minLines: 4, maxLines: 12, decoration: const InputDecoration(border: OutlineInputBorder())),
            FilledButton(
              onPressed: () {
                q.body = c.text.trim();
                if (q.body.isEmpty) {
                  notes.deleteQuickCapture(q.id);
                } else {
                  notes.updateQuickCapture(q);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
