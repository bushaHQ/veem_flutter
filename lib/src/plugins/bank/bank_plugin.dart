import 'package:flutter/material.dart';

import '../../bridge/bridge_message.dart';
import '../../bridge/veem_webview.dart';
import '../../core/errors.dart';
import '../../core/veem.dart';
import 'bank_models.dart';

/// Embeddable Veem bank capture widget.
///
/// Drops the Veem Web SDK's bank plugin into your Flutter app via a
/// WebView. Use this when you want the bank form inline in your own
/// screen. For a full-screen modal flow, use [Veem.bank.present] instead.
///
/// ```dart
/// VeemBankPlugin(
///   config: BankPluginConfig(
///     accountId: 391558,
///     sessionSecret: '...',
///     referenceId: 'order_123',
///   ),
///   onCompleted: (event) {
///     // event.userInputs.paymentMethod.fundingMethod.id is the bank ref
///   },
///   onExited: () {},
///   onErrored: (err) {},
/// )
/// ```
class VeemBankPlugin extends StatefulWidget {
  /// Construct a bank plugin widget.
  const VeemBankPlugin({
    required this.config,
    this.onCompleted,
    this.onExited,
    this.onErrored,
    this.onReady,
    this.loadingBuilder,
    super.key,
  });

  /// Plugin configuration — per-customer credentials, preset, header,
  /// style.
  final BankPluginConfig config;

  /// Called when the user completes the bank flow successfully.
  ///
  /// `event.userInputs.paymentMethod.fundingMethod.id` is the Veem
  /// funding reference — send to your backend.
  final void Function(BankPluginCompleted event)? onCompleted;

  /// Called when the user exits the plugin without completing it.
  final VoidCallback? onExited;

  /// Called when the plugin fails. Inspect [error.code] for cause.
  final void Function(VeemError error)? onErrored;

  /// Called when the plugin has finished loading and is interactive.
  final VoidCallback? onReady;

  /// Custom loading widget shown while the WebView and Web SDK
  /// initialize.
  final Widget? loadingBuilder;

  @override
  State<VeemBankPlugin> createState() => _VeemBankPluginState();
}

class _VeemBankPluginState extends State<VeemBankPlugin> {
  @override
  Widget build(BuildContext context) {
    if (!Veem.isInitialized) {
      throw const VeemError(
        code: VeemErrorCode.notInitialized,
        message:
            'Veem.initialize() must be called before mounting VeemBankPlugin.',
      );
    }

    return VeemWebView(
      pluginName: 'collectAccountInformation',
      pluginConfig: widget.config.toJson(),
      loadingBuilder: widget.loadingBuilder,
      onMessage: _onMessage,
    );
  }

  void _onMessage(BridgeMessage message) {
    if (!mounted) return;

    switch (message.type) {
      case 'ready':
        widget.onReady?.call();
      case 'complete':
        final completed = BankPluginCompleted(
          referenceId:
              (message.payload['referenceId'] as String?) ??
              widget.config.referenceId,
          preset: (message.payload['preset'] as Map?)?.cast<String, dynamic>(),
          userInputs: BankUserInputs.fromJson(
            (message.payload['userInputs'] as Map?)?.cast<String, dynamic>() ??
                const {},
          ),
        );
        widget.onCompleted?.call(completed);
      case 'exit':
        widget.onExited?.call();
      case 'error':
        final error = VeemError(
          code: _decodeErrorCode(message.payload['code'] as String?),
          message: (message.payload['message'] as String?) ?? 'Unknown error',
          details: (message.payload['details'] as Map?)
              ?.cast<String, dynamic>(),
        );
        widget.onErrored?.call(error);
      default:
        break;
    }
  }

  VeemErrorCode _decodeErrorCode(String? code) {
    return switch (code) {
      'notInitialized' => VeemErrorCode.notInitialized,
      'authenticationFailed' => VeemErrorCode.authenticationFailed,
      'networkError' => VeemErrorCode.networkError,
      'webviewLoadFailed' => VeemErrorCode.webviewLoadFailed,
      'bridgeError' => VeemErrorCode.bridgeError,
      'pluginError' => VeemErrorCode.pluginError,
      'userCancelled' => VeemErrorCode.userCancelled,
      _ => VeemErrorCode.unknown,
    };
  }
}
