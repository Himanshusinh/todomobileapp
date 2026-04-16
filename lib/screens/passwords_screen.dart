import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/models/password_vault_item.dart';
import 'package:todoapp/providers/password_vault_provider.dart';
import 'package:todoapp/services/android_autofill_settings.dart';
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
  bool _checkedAutofill = false;
  bool _autofillEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutofill());
  }

  Future<void> _checkAutofill() async {
    if (!AndroidAutofillSettings.isSupported) {
      if (mounted) {
        setState(() {
          _checkedAutofill = true;
          _autofillEnabled = true;
        });
      }
      return;
    }
    final enabled = await AndroidAutofillSettings.isAutofillEnabledForApp();
    if (!mounted) return;
    setState(() {
      _checkedAutofill = true;
      _autofillEnabled = enabled;
    });
    if (!enabled) {
      _showEnableAutofillDialog();
    }
  }

  Future<void> _showEnableAutofillDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enable Autofill'),
        content: const Text(
          'To autofill logins in other apps and websites, enable TodoApp as your Autofill service in system settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AndroidAutofillSettings.openAutofillSettings();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open settings: $e')),
                );
              }
              // Re-check when the user returns.
              await Future<void>.delayed(const Duration(milliseconds: 400));
              await _checkAutofill();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

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

  Widget _autofillBanner() {
    if (!_checkedAutofill || _autofillEnabled) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Material(
        color: cs.tertiaryContainer.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: cs.onTertiaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Autofill is off. Enable it to use Vault in other apps.',
                  style: TextStyle(color: cs.onTertiaryContainer),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await AndroidAutofillSettings.openAutofillSettings();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not open settings: $e')),
                    );
                  }
                  await Future<void>.delayed(const Duration(milliseconds: 400));
                  await _checkAutofill();
                },
                child: const Text('Enable'),
              ),
            ],
          ),
        ),
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

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final maxH = MediaQuery.sizeOf(ctx).height * 0.75;
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              top: 6,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    isEdit ? 'Edit login' : 'Add login',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: siteC,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Website / app name',
                              prefixIcon:
                                  const Icon(Icons.language_rounded, size: 20),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: urlC,
                            decoration: InputDecoration(
                              labelText: 'URL (optional)',
                              prefixIcon:
                                  const Icon(Icons.link_rounded, size: 20),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: userC,
                            decoration: InputDecoration(
                              labelText: 'Email or username',
                              prefixIcon:
                                  const Icon(Icons.person_outline_rounded,
                                      size: 20),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: passC,
                            obscureText: obscure,
                            decoration: InputDecoration(
                              labelText: isEdit
                                  ? 'New password (blank = keep current)'
                                  : 'Password',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded,
                                      size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscure
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                ),
                                onPressed: () =>
                                    setLocal(() => obscure = !obscure),
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (isEdit &&
                              existingPwd != null &&
                              existingPwd.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () async =>
                                    await _copy('Password', existingPwd!),
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('Copy current password'),
                              ),
                            ),
                          if (isEdit)
                            CheckboxListTile(
                              value: removePassword,
                              onChanged: (v) =>
                                  setLocal(() => removePassword = v ?? false),
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              title: const Text('Remove saved password'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: notesC,
                            decoration: InputDecoration(
                              labelText: 'Notes',
                              prefixIcon:
                                  const Icon(Icons.notes_rounded, size: 20),
                              filled: true,
                              fillColor: cs.surfaceContainerHighest
                                  .withValues(alpha: 0.55),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(isEdit ? 'Save' : 'Add'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
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
                  ),
                  const SizedBox(width: 10),
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
            ),
            _autofillBanner(),
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
                                  ? 'Vault is empty.\nTap Add login below to store sites, usernames, and encrypted passwords on this device.'
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
