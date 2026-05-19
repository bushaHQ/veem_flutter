import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/veem.dart';
import 'card_models.dart';
import 'card_plugin.dart';

/// Imperative API for the card plugin.
///
/// Accessed via [Veem.card]. Pushes the plugin as a full-screen modal and
/// awaits a sealed [CardPluginResult].
///
/// ```dart
/// final result = await Veem.card.present(
///   context,
///   config: CardPluginConfig(
///     accountId: 391558,
///     sessionSecret: '...',
///     referenceId: 'order_123',
///   ),
/// );
///
/// switch (result) {
///   case CardPluginCompleted(:final userInputs):
///     final fundingId = userInputs.paymentMethod.fundingMethod.id;
///     // POST to your backend to create the payment
///   case CardPluginExited():
///     // user closed
///   case CardPluginErrored(:final error):
///     // show error
/// }
/// ```
class CardPluginApi {
  /// Construct the API. You should not need to instantiate this directly;
  /// use [Veem.card].
  const CardPluginApi();

  /// Present the card plugin as a full-screen modal and await the
  /// result.
  ///
  /// Returns one of [CardPluginCompleted], [CardPluginExited], or
  /// [CardPluginErrored].
  ///
  /// If the user dismisses the modal via the system back button or close
  /// icon, this resolves to [CardPluginExited].
  Future<CardPluginResult> present(
    BuildContext context, {
    required CardPluginConfig config,
    String title = 'Add card',
    bool useRootNavigator = true,
    bool isDismissible = true,
  }) async {
    if (!Veem.isInitialized) {
      throw const VeemError(
        code: VeemErrorCode.notInitialized,
        message:
            'Veem.initialize() must be called before presenting the card plugin.',
      );
    }

    final completer = Completer<CardPluginResult>();

    final route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => _CardPluginScreen(
        config: config,
        title: title,
        isDismissible: isDismissible,
        onResult: (result) {
          if (!completer.isCompleted) completer.complete(result);
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        },
      ),
    );

    await Navigator.of(context, rootNavigator: useRootNavigator).push(route);

    // If the route popped without us completing (e.g. system back button
    // without isDismissible=false handling), treat as exit.
    if (!completer.isCompleted) {
      completer.complete(const CardPluginExited());
    }

    return completer.future;
  }
}

class _CardPluginScreen extends StatelessWidget {
  const _CardPluginScreen({
    required this.config,
    required this.title,
    required this.isDismissible,
    required this.onResult,
  });

  final CardPluginConfig config;
  final String title;
  final bool isDismissible;
  final void Function(CardPluginResult) onResult;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: isDismissible,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) onResult(const CardPluginExited());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: isDismissible
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onResult(const CardPluginExited()),
                )
              : null,
        ),
        body: SafeArea(
          child: VeemCardPlugin(
            config: config,
            onCompleted: onResult,
            onExited: () => onResult(const CardPluginExited()),
            onErrored: (err) => onResult(CardPluginErrored(err)),
          ),
        ),
      ),
    );
  }
}
