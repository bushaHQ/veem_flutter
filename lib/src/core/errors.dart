/// Categories of errors the SDK can raise.
enum VeemErrorCode {
  /// [Veem.initialize] was not called before using the SDK.
  notInitialized,

  /// The provided session credentials were rejected by Veem.
  authenticationFailed,

  /// Network failure while loading the Web SDK or talking to Veem.
  networkError,

  /// The WebView failed to load the bridge HTML.
  webviewLoadFailed,

  /// Internal bridge error (JS<->Dart message handling failed).
  bridgeError,

  /// The Web SDK raised an error from the plugin itself.
  pluginError,

  /// User cancelled / exited the plugin.
  userCancelled,

  /// Anything we couldn't classify.
  unknown,
}

/// Errors raised by the Veem SDK.
///
/// All callbacks and futures surface failures as [VeemError]. Inspect
/// [code] to branch on cause, [message] for human-readable detail, and
/// [details] for the raw payload from the Web SDK (useful when reporting
/// bugs to Veem support).
class VeemError implements Exception {
  /// Construct a VeemError.
  const VeemError({
    required this.code,
    required this.message,
    this.cause,
    this.details,
  });

  /// Category of error. Use this for control flow.
  final VeemErrorCode code;

  /// Human-readable description.
  final String message;

  /// The underlying exception (if any).
  final Object? cause;

  /// Raw payload from the Web SDK or bridge layer. Untyped — useful for
  /// debugging and bug reports, not for control flow.
  final Map<String, dynamic>? details;

  @override
  String toString() => 'VeemError(${code.name}): $message';
}
