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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Journal'),
              Tab(text: 'Ideas'),
              Tab(text: 'Capture'),
            ],
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
  final _searchAllC = TextEditingController();
  _JournalViewMode _viewMode = _JournalViewMode.list;

  @override
  void dispose() {
    _searchAllC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final q = _searchAllC.text.trim().toLowerCase();
    final list = notes.allJournalEntries.where((e) {
      if (q.isEmpty) return true;
      return e.title.toLowerCase().contains(q) ||
          e.bodyMarkdown.toLowerCase().contains(q) ||
          e.dateKey.toLowerCase().contains(q);
    }).toList();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _searchAllC,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search notes…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SegmentedButton<_JournalViewMode>(
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          visualDensity:
                              const VisualDensity(horizontal: -2, vertical: -2),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: _JournalViewMode.list,
                            icon: Icon(Icons.view_agenda_outlined, size: 18),
                          ),
                          ButtonSegment(
                            value: _JournalViewMode.grid,
                            icon: Icon(Icons.grid_view_rounded, size: 18),
                          ),
                          ButtonSegment(
                            value: _JournalViewMode.flex,
                            icon: Icon(Icons.view_module_outlined, size: 18),
                          ),
                        ],
                        selected: {_viewMode},
                        onSelectionChanged: (v) =>
                            setState(() => _viewMode = v.first),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (list.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 88),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    q.isEmpty ? 'No notes yet.' : 'No matches.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else ...[
              if (_viewMode == _JournalViewMode.list)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final e = list[i];
                        final title =
                            e.title.trim().isEmpty ? '(untitled)' : e.title;
                        return _NoteListRow(
                          dense: true,
                          title: title,
                          subtitle: DateFormat('MMM d, y').format(e.updatedAt),
                          meta: '',
                          onTap: () => _openJournalEditor(context, e),
                          onDelete: () => notes.deleteJournalEntry(e.id),
                        );
                      },
                      childCount: list.length,
                    ),
                  ),
                )
              else if (_viewMode == _JournalViewMode.grid)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final e = list[i];
                        return _JournalGridTile(
                          title: e.title.trim().isEmpty ? '(untitled)' : e.title,
                          date: DateFormat('MMM d').format(e.updatedAt),
                          onTap: () => _openJournalEditor(context, e),
                          onDelete: () => notes.deleteJournalEntry(e.id),
                        );
                      },
                      childCount: list.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.35,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  sliver: SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final e in list)
                          _JournalFlexTile(
                            title: e.title.trim().isEmpty ? '(untitled)' : e.title,
                            date: DateFormat('MMM d').format(e.updatedAt),
                            onTap: () => _openJournalEditor(context, e),
                            onDelete: () => notes.deleteJournalEntry(e.id),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            child: FloatingActionButton(
              heroTag: 'fab_notes_new_entry',
              onPressed: () => _openJournalEditor(context, null),
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openJournalEditor(BuildContext context, JournalEntry? existing) async {
    final notes = context.read<NotesProvider>();
    final titleC = TextEditingController(text: existing?.title ?? '');
    final bodyC = TextEditingController(text: existing?.bodyMarkdown ?? '');
    final dateKey =
        existing?.dateKey ?? NotesProvider.dateKey(DateTime.now());

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

enum _JournalViewMode { list, grid, flex }

class _JournalGridTile extends StatelessWidget {
  const _JournalGridTile({
    required this.title,
    required this.date,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String date;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    visualDensity:
                        const VisualDensity(horizontal: -2, vertical: -2),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                date,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalFlexTile extends StatelessWidget {
  const _JournalFlexTile({
    required this.title,
    required this.date,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String date;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 210),
      child: Material(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  visualDensity:
                      const VisualDensity(horizontal: -3, vertical: -3),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteListRow extends StatelessWidget {
  const _NoteListRow({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    required this.onDelete,
    this.dense = false,
  });

  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                8,
                dense ? 8 : 10,
                4,
                dense ? 8 : 10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (meta.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                meta,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: dense ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.28),
        ),
      ],
    );
  }
}

class _BrainstormTab extends StatelessWidget {
  const _BrainstormTab();

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>();
    final ideas = notes.brainstormIdeas;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Stack(
      children: [
        ideas.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Add idea cards for projects, plans, and quick thoughts.\nTap + to start.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              )
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
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    child: InkWell(
                      onTap: () => _editIdea(context, idea),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              idea.title.isEmpty ? 'Idea' : idea.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                idea.content,
                                maxLines: 6,
                                overflow: TextOverflow.fade,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(99),
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
            heroTag: 'fab_notes_ideas',
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Stack(
      children: [
        items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Quick capture is a brain-dump.\nTap “Quick add” to save anything.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: items.length,
                separatorBuilder: (context, _) => Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.28),
                ),
                itemBuilder: (ctx, i) {
                  final q = items[i];
                  return Dismissible(
                    key: ValueKey('capture_${q.id}'),
                    direction: DismissDirection.endToStart,
                    background: const SizedBox.shrink(),
                    secondaryBackground: Container(
                      color: cs.error.withValues(alpha: 0.12),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(Icons.delete_outline_rounded, color: cs.error),
                    ),
                    onDismissed: (_) => notes.deleteQuickCapture(q.id),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _editCapture(context, q),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: cs.tertiary.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      q.body,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(q.createdAt),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => notes.deleteQuickCapture(q.id),
                                icon: const Icon(Icons.close_rounded, size: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_notes_quick_capture',
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
