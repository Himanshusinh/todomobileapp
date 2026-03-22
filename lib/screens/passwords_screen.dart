import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/password_vault_item.dart';
import 'package:todoapp/providers/password_vault_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void _disposeControllersAfterDialog(List<TextEditingController> controllers) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final c in controllers) {
      c.dispose();
    }
  });
}

class PasswordsScreen extends StatefulWidget {
  const PasswordsScreen({super.key});

  @override
  State<PasswordsScreen> createState() => _PasswordsScreenState();
}

class _PasswordsScreenState extends State<PasswordsScreen> {
  final _searchC = TextEditingController();

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _copy(String label, String value) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    var u = url.trim();
    if (u.isEmpty) return;
    if (!u.contains('://')) u = 'https://$u';
    final uri = Uri.tryParse(u);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showAddOrEdit(
    BuildContext context, {
    PasswordVaultItem? existing,
  }) async {
    final siteC = TextEditingController(text: existing?.siteName ?? '');
    final urlC = TextEditingController(text: existing?.websiteUrl ?? '');
    final userC = TextEditingController(text: existing?.username ?? '');
    final passC = TextEditingController();
    final notesC = TextEditingController(text: existing?.notes ?? '');
    var obscure = true;
    var removePassword = false;
    final isEdit = existing != null;
    String? existingPwd;
    if (existing != null) {
      existingPwd = await context.read<PasswordVaultProvider>().getPassword(
            existing.id,
          );
    }
    if (!context.mounted) {
      _disposeControllersAfterDialog([siteC, urlC, userC, passC, notesC]);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(isEdit ? 'Edit login' : 'Save password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: siteC,
                  decoration: const InputDecoration(
                    labelText: 'Website / app name',
                    prefixIcon: Icon(Icons.language),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                TextField(
                  controller: urlC,
                  decoration: const InputDecoration(
                    labelText: 'URL (optional)',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                TextField(
                  controller: userC,
                  decoration: const InputDecoration(
                    labelText: 'Email or username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passC,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: isEdit
                        ? 'New password (blank = keep current)'
                        : 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setLocal(() => obscure = !obscure),
                    ),
                  ),
                ),
                if (isEdit && existingPwd != null && existingPwd.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      await _copy('Password', existingPwd!);
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy current password'),
                  ),
                if (isEdit)
                  CheckboxListTile(
                    value: removePassword,
                    onChanged: (v) =>
                        setLocal(() => removePassword = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Remove saved password'),
                    contentPadding: EdgeInsets.zero,
                  ),
                TextField(
                  controller: notesC,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && siteC.text.trim().isNotEmpty && context.mounted) {
      final p = context.read<PasswordVaultProvider>();
      if (existing != null) {
        final e = existing;
        e.siteName = siteC.text.trim();
        e.websiteUrl = urlC.text.trim();
        e.username = userC.text.trim();
        e.notes = notesC.text.trim();
        if (removePassword) {
          await p.updateEntry(e, clearPassword: true);
        } else if (passC.text.isNotEmpty) {
          await p.updateEntry(e, newPassword: passC.text);
        } else {
          await p.updateEntry(e);
        }
      } else {
        await p.addEntry(
          siteName: siteC.text.trim(),
          websiteUrl: urlC.text.trim(),
          username: userC.text.trim(),
          password: passC.text,
          notes: notesC.text.trim(),
        );
      }
    }

    _disposeControllersAfterDialog([siteC, urlC, userC, passC, notesC]);
  }

  Future<void> _showPasswordSheet(
    BuildContext context,
    PasswordVaultItem e,
  ) async {
    final pwd = await context.read<PasswordVaultProvider>().getPassword(e.id);
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                e.siteName,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              if (e.username.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  e.username,
                  style: Theme.of(ctx).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: 16),
              if (pwd == null || pwd.isEmpty)
                Text(
                  'No password stored.',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                )
              else
                SelectableText(
                  pwd,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        letterSpacing: 1.2,
                      ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: pwd == null || pwd.isEmpty
                    ? null
                    : () {
                        _copy('Password', pwd);
                        Navigator.pop(ctx);
                      },
                icon: const Icon(Icons.copy),
                label: const Text('Copy password'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarBg =
        theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: appBarBg,
              elevation: 0,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Password vault',
                              style: theme.appBarTheme.titleTextStyle,
                            ),
                          ),
                          IconButton.filledTonal(
                            tooltip: 'Security info',
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('How your data is stored'),
                                content: const Text(
                                  'Site names, URLs, and usernames are saved on device. '
                                  'Passwords are stored in encrypted storage (Android Keystore / '
                                  'iOS Keychain). Use a strong device lock screen.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            ),
                            icon: const Icon(Icons.shield_outlined),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchC,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search sites…',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<PasswordVaultProvider>(
                builder: (context, p, _) {
                  final list = p.search(_searchC.text);
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.key_off_outlined,
                              size: 72,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              p.entries.isEmpty
                                  ? 'Save logins by site.\nPasswords are encrypted on device.'
                                  : 'No matches.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final e = list[i];
                      return _VaultCard(
                        entry: e,
                        onCopyUser: () => _copy('Username', e.username),
                        onOpenSite: () => _openUrl(e.websiteUrl),
                        onEdit: () => _showAddOrEdit(context, existing: e),
                        onDelete: () async {
                          final go = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete login?'),
                              content: Text('Remove ${e.siteName}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (go == true && context.mounted) {
                            await p.deleteEntry(e.id);
                          }
                        },
                        onRevealPassword: () => _showPasswordSheet(context, e),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'fab_passwords_add',
            onPressed: () => _showAddOrEdit(context),
            icon: const Icon(Icons.add),
            label: const Text('Add login'),
          ),
        ),
      ],
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard({
    required this.entry,
    required this.onCopyUser,
    required this.onOpenSite,
    required this.onEdit,
    required this.onDelete,
    required this.onRevealPassword,
  });

  final PasswordVaultItem entry;
  final VoidCallback onCopyUser;
  final VoidCallback onOpenSite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRevealPassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = entry.siteName.isNotEmpty
        ? entry.siteName[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onRevealPassword,
          borderRadius: BorderRadius.circular(20),
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.9),
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.siteName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (entry.username.isNotEmpty)
                        Text(
                          entry.username,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (entry.websiteUrl.isNotEmpty)
                        Text(
                          entry.websiteUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Password',
                      onPressed: onRevealPassword,
                      icon: const Icon(Icons.key_rounded),
                    ),
                    IconButton(
                      tooltip: 'Copy user',
                      onPressed: onCopyUser,
                      icon: const Icon(Icons.copy_rounded, size: 20),
                    ),
                    if (entry.websiteUrl.isNotEmpty)
                      IconButton(
                        tooltip: 'Open site',
                        onPressed: onOpenSite,
                        icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      ),
                    PopupMenuButton<String>(
                      child: const Icon(Icons.more_vert),
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'del') onDelete();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'del', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
