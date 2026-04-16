/// Backend configuration.
///
/// - Keep these values OUT of git for real apps.
/// - For quick local testing, you can paste them here.
/// - Production: prefer `--dart-define` or a secrets manager.
abstract final class BackendConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}

