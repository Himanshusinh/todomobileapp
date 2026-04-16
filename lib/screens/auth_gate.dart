import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todoapp/providers/finance_provider.dart';
import 'package:todoapp/providers/goals_provider.dart';
import 'package:todoapp/providers/health_provider.dart';
import 'package:todoapp/providers/notes_provider.dart';
import 'package:todoapp/providers/password_vault_provider.dart';
import 'package:todoapp/providers/task_provider.dart';
import 'package:todoapp/providers/theme_provider.dart';
import 'package:todoapp/screens/home_screen.dart';
import 'package:todoapp/screens/sign_in_screen.dart';
import 'package:todoapp/screens/vault_autofill_pick_screen.dart';
import 'package:todoapp/screens/vault_autofill_save_screen.dart';
import 'package:todoapp/services/hive_user_boxes.dart';
import 'package:todoapp/theme/app_theme.dart';

/// Root auth + per-user Hive + [MaterialApp]. Rebuilds the navigator on sign-in
/// so stacked sign-up routes disappear; vault routes sit under the same provider tree.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        unawaited(Hive.close());
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _TodoMaterialApp(
            home: const _AuthLoadingBody(),
          );
        }
        final user = snap.data;
        if (user == null) {
          return _TodoMaterialApp(
            home: const SignInScreen(),
          );
        }
        return FutureBuilder<void>(
          key: ValueKey<String>(user.uid),
          future: HiveUserBoxes.openForUser(user.uid),
          builder: (context, asyncSnap) {
            if (asyncSnap.connectionState != ConnectionState.done) {
              return _TodoMaterialApp(
                home: const _AuthLoadingBody(),
              );
            }
            if (asyncSnap.hasError) {
              return _TodoMaterialApp(
                home: _HiveOpenErrorBody(error: asyncSnap.error),
              );
            }
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => TaskProvider(userId: user.uid),
                ),
                ChangeNotifierProvider(
                  create: (_) => FinanceProvider(userId: user.uid),
                ),
                ChangeNotifierProvider(
                  create: (_) => HealthProvider(userId: user.uid),
                ),
                ChangeNotifierProvider(
                  create: (_) => NotesProvider(userId: user.uid),
                ),
                ChangeNotifierProvider(
                  create: (_) => GoalsProvider(userId: user.uid),
                ),
                ChangeNotifierProvider(
                  create: (_) => PasswordVaultProvider(userId: user.uid),
                ),
              ],
              child: _TodoMaterialApp(
                home: const HomeScreen(),
              ),
            );
          },
        );
      },
    );
  }
}

class _AuthLoadingBody extends StatelessWidget {
  const _AuthLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HiveOpenErrorBody extends StatelessWidget {
  const _HiveOpenErrorBody({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not open local storage.\n$error',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

class _TodoMaterialApp extends StatelessWidget {
  const _TodoMaterialApp({required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Todo',
      debugShowCheckedModeBanner: false,
      theme: LuxuryAppTheme.theme(Brightness.light),
      darkTheme: LuxuryAppTheme.theme(Brightness.dark),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final uri = Uri.tryParse(name);
        if (uri != null && uri.path == '/vault/autofill/pick') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => VaultAutofillPickScreen(
              args: VaultAutofillPickArgs(
                packageName: uri.queryParameters['pkg'] ?? '',
                domain: uri.queryParameters['domain'] ?? '',
              ),
            ),
          );
        }
        if (uri != null && uri.path == '/vault/autofill/save') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => VaultAutofillSaveScreen(
              args: VaultAutofillSaveArgs(
                packageName: uri.queryParameters['pkg'] ?? '',
                domain: uri.queryParameters['domain'] ?? '',
                username: uri.queryParameters['u'] ?? '',
                password: uri.queryParameters['p'] ?? '',
              ),
            ),
          );
        }
        return null;
      },
      home: home,
    );
  }
}
