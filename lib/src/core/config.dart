/// Environment the SDK runs against.
enum VeemEnvironment {
  /// Veem sandbox. Use for development and integration testing.
  sandbox,

  /// Veem production. Use only when going live.
  production;

  /// The string the Web SDK expects.
  String get wireValue => switch (this) {
    VeemEnvironment.sandbox => 'sandbox',
    VeemEnvironment.production => 'production',
  };
}

/// Global configuration for the Veem SDK.
///
/// Pass this to [Veem.initialize] once at app startup. Per-customer
/// credentials (`accountId`, `sessionSecret`) are NOT part of this config —
/// those are passed per plugin invocation since they're customer-scoped and
/// short-lived.
class VeemConfig {
  /// Construct a Veem configuration.
  const VeemConfig({
    required this.environment,
    required this.clientId,
    this.webSdkVersion = '0',
    this.enableLogging = false,
    this.enableWebViewDebugging = false,
  });

  /// Whether to target sandbox or production.
  final VeemEnvironment environment;

  /// Your Veem API `clientId`. Safe to ship in a mobile binary — it's an
  /// identifier, not a secret.
  final String clientId;

  /// Pin for the Veem Web SDK on unpkg.
  ///
  /// Defaults to `'0'` (latest 0.x). For production you should pin to an
  /// exact version you've tested against (e.g. `'0.x.y'`) and bump
  /// deliberately. Leaving this on `'0'` means Veem's CDN can ship a
  /// breaking change into your app silently.
  final String webSdkVersion;

  /// Emit debug logging for bridge events. Off by default. Never logs card
  /// data or session secrets; only structural events.
  final bool enableLogging;

  /// Make the underlying WebView inspectable from Safari Web Inspector
  /// (iOS/macOS, requires iOS 16.4+) and Chrome DevTools at
  /// `chrome://inspect` (Android).
  ///
  /// Off by default. Recommended pattern is to gate on `kDebugMode` so the
  /// inspector never ships in release builds:
  ///
  /// ```dart
  /// VeemConfig(
  ///   ...,
  ///   enableWebViewDebugging: kDebugMode,
  /// )
  /// ```
  final bool enableWebViewDebugging;
}
