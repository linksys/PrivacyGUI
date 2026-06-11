/// Theme source enumeration.
enum ThemeSource {
  /// Resolve by priority (default).
  normal,

  /// Force use CI/CD environment variable.
  cicd,

  /// Force use remote API.
  network,

  /// Force use assets file.
  assets,

  /// Force use built-in default.
  defaultTheme
}
