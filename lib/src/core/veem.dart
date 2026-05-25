import 'package:flutter/foundation.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../plugins/bank/bank_api.dart';
import '../plugins/card/card_api.dart';
import 'config.dart';
import 'errors.dart';

/// Entry point to the Veem SDK.
///
/// Call [Veem.initialize] once at app startup, then use the plugin
/// namespaces ([card], etc.) to launch flows.
class Veem {
  Veem._();

  static VeemConfig? _config;

  /// The current configuration. Throws [VeemError] with code
  /// [VeemErrorCode.notInitialized] if [initialize] hasn't been called.
  static VeemConfig get config {
    final c = _config;
    if (c == null) {
      throw const VeemError(
        code: VeemErrorCode.notInitialized,
        message:
            'Veem.initialize() must be called before using the SDK. Call it '
            'once at app startup (typically in main()).',
      );
    }
    return c;
  }

  /// Whether [initialize] has been called.
  static bool get isInitialized => _config != null;

  /// Initialize the SDK. Call once at app startup.
  ///
  /// Idempotent: re-calling replaces the existing config. Useful for tests
  /// and for swapping environments at runtime.
  static Future<void> initialize(VeemConfig config) async {
    _config = config;
    if (config.enableWebViewDebugging &&
        defaultTargetPlatform == TargetPlatform.android) {
      await AndroidWebViewController.enableDebugging(true);
    }
  }

  /// Card plugin namespace.
  ///
  /// ```dart
  /// final result = await Veem.card.present(context, config: ...);
  /// ```
  static const CardPluginApi card = CardPluginApi();

  /// Bank plugin namespace.
  ///
  /// ```dart
  /// final result = await Veem.bank.present(context, config: ...);
  /// ```
  static const BankPluginApi bank = BankPluginApi();

  /// Reset SDK state. Intended for tests only.
  @visibleForTesting
  static void reset() {
    _config = null;
  }
}
