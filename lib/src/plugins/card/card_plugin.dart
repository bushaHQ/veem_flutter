import 'package:flutter/material.dart';

import '../../bridge/bridge_message.dart';
import '../../bridge/veem_webview.dart';
import '../../core/errors.dart';
import '../../core/veem.dart';
import 'card_models.dart';

/// Embeddable Veem card capture widget.
///
/// Drops the Veem Web SDK's card plugin into your Flutter app via a
/// WebView. Use this when you want the card form inline in your own
/// screen. For a full-screen modal flow, use [Veem.card.present] instead.
///
/// ```dart
/// VeemCardPlugin(
///   config: CardPluginConfig(
///     accountId: 391558,
///     sessionSecret: '...',
///     referenceId: 'order_123',
///   ),
///   onCompleted: (event) {
///     // event.userInputs.paymentMethod.fundingMethod.id is the card ref
///   },
///   onExited: () {},
///   onErrored: (err) {},
/// )
/// ```
class VeemCardPlugin extends StatefulWidget {
  /// Construct a card plugin widget.
  const VeemCardPlugin({
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
  final CardPluginConfig config;

  /// Called when the user completes the card flow successfully.
  ///
  /// `event.userInputs.paymentMethod.fundingMethod.id` is the Veem
  /// funding reference — send to your backend.
  final void Function(CardPluginCompleted event)? onCompleted;

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
  State<VeemCardPlugin> createState() => _VeemCardPluginState();
}

class _VeemCardPluginState extends State<VeemCardPlugin> {
  @override
  Widget build(BuildContext context) {
    // Surface a clear, eager error if the SDK isn't initialized — better
    // than a confusing WebView load failure deeper in.
    if (!Veem.isInitialized) {
      throw const VeemError(
        code: VeemErrorCode.notInitialized,
        message:
            'Veem.initialize() must be called before mounting VeemCardPlugin.',
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
        final completed = CardPluginCompleted(
          referenceId:
              (message.payload['referenceId'] as String?) ??
              widget.config.referenceId,
          preset: (message.payload['preset'] as Map?)?.cast<String, dynamic>(),
          userInputs: UserInputs.fromJson(
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
        // Unknown event — ignore in v1. Future plugins may add new event
        // types we don't recognize yet.
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
