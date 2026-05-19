/// Flutter SDK for Veem Global Payments.
///
/// v1 wraps the Veem Web SDK in a WebView and exposes:
///   - A widget API: [VeemCardPlugin] for embedding the card flow inline.
///   - An imperative API: [Veem.card.present] for showing it as a full-screen
///     modal and awaiting the result.
///
/// Quick start:
///
/// ```dart
/// // app startup
/// await Veem.initialize(const VeemConfig(
///   environment: VeemEnvironment.sandbox,
///   clientId: 'your-client-id',
/// ));
///
/// // when ready to collect card details for a customer
/// final result = await Veem.card.present(
///   context,
///   config: CardPluginConfig(
///     accountId: 391558,
///     sessionSecret: 'session-secret-from-your-backend',
///     referenceId: 'order_abc123',
///   ),
/// );
///
/// switch (result) {
///   case CardPluginCompleted(:final userInputs):
///     // userInputs.paymentMethod.fundingMethod.id is the Veem funding id.
///     // Send it to your backend to create the payment.
///   case CardPluginExited():
///     // user closed the plugin
///   case CardPluginErrored(:final error):
///     // surface the error
/// }
/// ```
library;

export 'src/core/veem.dart' show Veem;
export 'src/core/config.dart' show VeemConfig, VeemEnvironment;
export 'src/core/errors.dart' show VeemError, VeemErrorCode;
export 'src/plugins/card/card_plugin.dart' show VeemCardPlugin;
export 'src/plugins/card/card_api.dart' show CardPluginApi;
export 'src/plugins/card/card_models.dart'
    show
        CardPluginConfig,
        CardPreset,
        CardPluginResult,
        CardPluginCompleted,
        CardPluginExited,
        CardPluginErrored,
        UserInputs,
        PaymentMethod,
        FundingMethod,
        BillingAddress;
