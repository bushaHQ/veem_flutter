import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors.dart';
import '../../core/veem.dart';
import 'bank_models.dart';
import 'bank_plugin.dart';

/// Imperative API for the bank plugin.
///
/// Accessed via [Veem.bank]. Pushes the plugin as a full-screen modal and
/// awaits a sealed [BankPluginResult].
///
/// ```dart
/// final result = await Veem.bank.present(
///   context,
///   config: BankPluginConfig(
///     accountId: 391558,
///     sessionSecret: '...',
///     referenceId: 'order_123',
///   ),
/// );
///
/// switch (result) {
///   case BankPluginCompleted(:final userInputs):
///     final fundingId = userInputs.paymentMethod.fundingMethod.id;
///     // POST to your backend to create the payment
///   case BankPluginExited():
///     // user closed
///   case BankPluginErrored(:final error):
///     // show error
/// }
/// ```
class BankPluginApi {
  /// Construct the API. You should not need to instantiate this directly;
  /// use [Veem.bank].
  const BankPluginApi();

  /// Present the bank plugin as a full-screen modal and await the
  /// result.
  ///
  /// Returns one of [BankPluginCompleted], [BankPluginExited], or
  /// [BankPluginErrored].
  ///
  /// If the user dismisses the modal via the system back button or close
  /// icon, this resolves to [BankPluginExited].
  Future<BankPluginResult> present(
    BuildContext context, {
    required BankPluginConfig config,
    String title = 'Add bank account',
    bool useRootNavigator = true,
    bool isDismissible = true,
  }) async {
    if (!Veem.isInitialized) {
      throw const VeemError(
        code: VeemErrorCode.notInitialized,
        message:
            'Veem.initialize() must be called before presenting the bank plugin.',
      );
    }

    final completer = Completer<BankPluginResult>();

    final route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) => _BankPluginScreen(
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

    if (!completer.isCompleted) {
      completer.complete(const BankPluginExited());
    }

    return completer.future;
  }
}

class _BankPluginScreen extends StatelessWidget {
  const _BankPluginScreen({
    required this.config,
    required this.title,
    required this.isDismissible,
    required this.onResult,
  });

  final BankPluginConfig config;
  final String title;
  final bool isDismissible;
  final void Function(BankPluginResult) onResult;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: isDismissible,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) onResult(const BankPluginExited());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: isDismissible
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onResult(const BankPluginExited()),
                )
              : null,
        ),
        body: SafeArea(
          child: VeemBankPlugin(
            config: config,
            onCompleted: onResult,
            onExited: () => onResult(const BankPluginExited()),
            onErrored: (err) => onResult(BankPluginErrored(err)),
          ),
        ),
      ),
    );
  }
}
