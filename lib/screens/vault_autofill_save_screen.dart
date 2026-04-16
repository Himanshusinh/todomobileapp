import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/providers/password_vault_provider.dart';
import 'package:todoapp/services/vault_autofill_channel.dart';

class VaultAutofillSaveArgs {
  const VaultAutofillSaveArgs({
    required this.packageName,
    required this.domain,
    required this.username,
    required this.password,
  });

  final String packageName;
  final String domain;
  final String username;
  final String password;
}

class VaultAutofillSaveScreen extends StatefulWidget {
  const VaultAutofillSaveScreen({super.key, required this.args});

  final VaultAutofillSaveArgs args;

  @override
  State<VaultAutofillSaveScreen> createState() => _VaultAutofillSaveScreenState();
}

class _VaultAutofillSaveScreenState extends State<VaultAutofillSaveScreen> {
  bool _busy = false;
  String? _err;

  Future<bool> _auth() async {
    try {
      final la = LocalAuthentication();
      return await la.authenticate(
        localizedReason: 'Unlock Vault to save this password',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final site = _siteLabel();
    final u = widget.args.username.trim();
    final p = widget.args.password;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) return;
        await VaultAutofillChannel.cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Save to Vault'),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                site,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                u.isEmpty ? '(no username captured)' : u,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (_err != null)
                Text(
                  _err!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.error,
                  ),
                ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        if (p.isEmpty) {
                          setState(() => _err = 'No password captured to save.');
                          return;
                        }
                        setState(() {
                          _busy = true;
                          _err = null;
                        });
                        final ok = await _auth();
                        if (!mounted) return;
                        if (!ok) {
                          setState(() {
                            _busy = false;
                            _err = 'Authentication cancelled.';
                          });
                          await VaultAutofillChannel.cancel();
                          return;
                        }

                        final provider = context.read<PasswordVaultProvider>();
                        await provider.addEntry(
                          siteName: site,
                          websiteUrl: widget.args.domain.trim(),
                          username: u,
                          password: p,
                          notes: '',
                        );
                        await VaultAutofillChannel.finish();
                      },
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        await VaultAutofillChannel.cancel();
                        if (mounted) Navigator.of(context).maybePop();
                      },
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _siteLabel() {
    final d = widget.args.domain.trim();
    if (d.isNotEmpty) return d;
    final pkg = widget.args.packageName.trim();
    if (pkg.isEmpty) return 'App login';
    final parts = pkg.split('.').where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? pkg : parts.last;
  }
}

