import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/providers/password_vault_provider.dart';
import 'package:todoapp/services/vault_autofill_channel.dart';

class VaultAutofillPickArgs {
  const VaultAutofillPickArgs({
    required this.packageName,
    required this.domain,
  });

  final String packageName;
  final String domain;
}

class VaultAutofillPickScreen extends StatefulWidget {
  const VaultAutofillPickScreen({super.key, required this.args});

  final VaultAutofillPickArgs args;

  @override
  State<VaultAutofillPickScreen> createState() =>
      _VaultAutofillPickScreenState();
}

class _VaultAutofillPickScreenState extends State<VaultAutofillPickScreen> {
  final _searchC = TextEditingController();
  bool _authed = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _auth());
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _auth() async {
    try {
      final la = LocalAuthentication();
      final ok = await la.authenticate(
        localizedReason: 'Unlock Vault to autofill',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (!ok) {
        setState(() => _err = 'Authentication cancelled.');
        await VaultAutofillChannel.cancel();
        return;
      }
      setState(() => _authed = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = 'Biometric auth failed.');
      await VaultAutofillChannel.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final p = context.watch<PasswordVaultProvider>();

    final hint = _searchHint();
    final q = _searchC.text.trim();
    final initialQuery = q.isNotEmpty ? q : hint;
    final entries = p.search(initialQuery);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) return;
        await VaultAutofillChannel.cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Autofill from Vault'),
          actions: [
            IconButton(
              tooltip: 'Cancel',
              onPressed: () async {
                await VaultAutofillChannel.cancel();
                if (mounted) Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              TextField(
                controller: _searchC,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search ${hint.isEmpty ? 'logins' : hint}…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_err != null) ...[
                const SizedBox(height: 10),
                Text(
                  _err!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.error,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Expanded(
                child: !_authed
                    ? const Center(child: CircularProgressIndicator())
                    : entries.isEmpty
                        ? Center(
                            child: Text(
                              'No matching logins.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: entries.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: cs.outlineVariant.withValues(alpha: 0.28),
                            ),
                            itemBuilder: (ctx, i) {
                              final e = entries[i];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  e.siteName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  e.username,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () async {
                                  final pwd = await p.getPassword(e.id);
                                  if (!mounted) return;
                                  if (pwd == null || pwd.isEmpty) {
                                    setState(
                                      () => _err = 'No password stored for this login.',
                                    );
                                    return;
                                  }
                                  await VaultAutofillChannel.finishWithCredential(
                                    username: e.username,
                                    password: pwd,
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _searchHint() {
    final d = widget.args.domain.trim();
    if (d.isNotEmpty) return d;
    final p = widget.args.packageName.trim();
    if (p.isEmpty) return '';
    final parts = p.split('.').where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? p : parts.last;
  }
}

