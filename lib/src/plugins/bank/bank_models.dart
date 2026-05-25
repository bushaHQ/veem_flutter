import '../../core/errors.dart';
import '../../style/veem_style.dart';
import '../card/card_models.dart' show FundingMethod;

/// Configuration for the Veem Bank plugin.
///
/// Per-customer credentials ([accountId], [sessionSecret]) must be fetched
/// from your backend before launching the plugin. Your backend calls
/// Veem's "search customer by email" endpoint with your partner OAuth
/// token to get these values for a given customer.
///
/// Never embed your partner OAuth token, partner secret, or any long-lived
/// credential in a mobile binary — only the short-lived per-session
/// credentials below are safe to pass to the SDK.
class BankPluginConfig {
  /// Construct a bank plugin configuration.
  const BankPluginConfig({
    required this.accountId,
    required this.sessionSecret,
    required this.referenceId,
    this.preset,
    this.headerText,
    this.style,
  });

  /// Veem account id for the customer (payer). Returned by the
  /// search-customer-by-email API.
  final int accountId;

  /// Per-session secret returned by the search-customer-by-email API.
  ///
  /// Treat as a short-lived credential — fetch from your backend each
  /// time you launch the plugin. Do not cache.
  final String sessionSecret;

  /// Unique identifier for this plugin instance. Echoed back in the
  /// completion event so you can correlate the result to the originating
  /// flow (e.g. an order id or account id).
  final String referenceId;

  /// Optional amount/currency to prefill in the plugin UI.
  final BankPreset? preset;

  /// Custom header text shown above the bank form.
  ///
  /// Maps to `configuration.paymentOptions[0].header`.
  final String? headerText;

  /// Custom styling for the plugin UI.
  ///
  /// Use [VeemStyle.fromTheme] to derive a style from your Material
  /// theme, or construct one directly. The full schema is documented at
  /// https://developer.veem.com/docs/bank-plugin.
  final VeemStyle? style;

  /// Serialize to the JSON shape the Web SDK expects.
  ///
  /// This is mapped onto the `Veem.WebSDK` constructor's top-level fields
  /// and `configuration` object inside the JS bridge.
  Map<String, dynamic> toJson() {
    return {
      'referenceId': referenceId,
      'preset': ?preset?.toJson(),
      'configuration': {
        'accountId': accountId,
        'sessionSecret': sessionSecret,
        'paymentOptions': [
          {'type': 'Bank', 'header': ?headerText},
        ],
        'style': ?style?.toJson(),
      },
    };
  }
}

/// Amount/currency preset for the plugin UI.
class BankPreset {
  /// Construct a bank preset.
  const BankPreset({required this.amount, required this.currencyCode});

  /// Amount in the smallest unit of [currencyCode] (cents for USD, etc.).
  final num amount;

  /// ISO 4217 currency code (e.g. `'USD'`).
  final String currencyCode;

  /// JSON shape expected by the Web SDK.
  Map<String, dynamic> toJson() => {
    'amount': amount,
    'currencyCode': currencyCode,
  };
}

/// Sealed result returned by [BankPluginApi.present] (and by the widget's
/// callbacks, via the success/exit/error events).
sealed class BankPluginResult {
  const BankPluginResult();
}

/// User completed the bank flow successfully.
///
/// [userInputs.paymentMethod.fundingMethod.id] is the Veem funding id —
/// send it to your backend to attach to a payment via the Create Payment
/// API.
class BankPluginCompleted extends BankPluginResult {
  /// Construct a completed event.
  const BankPluginCompleted({
    required this.referenceId,
    required this.userInputs,
    this.preset,
  });

  /// The [BankPluginConfig.referenceId] you passed in, echoed back.
  final String referenceId;

  /// Optional preset that was active during the flow.
  final Map<String, dynamic>? preset;

  /// Bank details collected by the plugin.
  final BankUserInputs userInputs;
}

/// User exited / cancelled the plugin without completing it.
class BankPluginExited extends BankPluginResult {
  /// Construct an exited event.
  const BankPluginExited();
}

/// Plugin failed. Inspect [error] for cause.
class BankPluginErrored extends BankPluginResult {
  /// Construct an errored event.
  const BankPluginErrored(this.error);

  /// The error that occurred.
  final VeemError error;
}

/// Information captured by the bank plugin and returned on success.
///
/// Mirrors the `userInputs` shape from
/// https://developer.veem.com/docs/bank-plugin.
class BankUserInputs {
  /// Construct a BankUserInputs.
  const BankUserInputs({required this.paymentMethod, required this.raw});

  /// Parse from the Web SDK payload.
  factory BankUserInputs.fromJson(Map<String, dynamic> json) {
    return BankUserInputs(
      paymentMethod: BankPaymentMethod.fromJson(
        (json['paymentMethod'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      raw: json,
    );
  }

  /// The captured payment method.
  final BankPaymentMethod paymentMethod;

  /// Raw JSON from the Web SDK. Useful if Veem adds fields we haven't
  /// typed yet.
  final Map<String, dynamic> raw;
}

/// A captured bank payment method.
class BankPaymentMethod {
  /// Construct a bank payment method.
  const BankPaymentMethod({
    required this.type,
    required this.fundingMethod,
    this.name,
    this.bankName,
    this.routingNumber,
    this.bankAccountNumber,
    this.isoCountryCode,
    this.currencyCode,
  });

  /// Parse from JSON.
  factory BankPaymentMethod.fromJson(Map<String, dynamic> json) {
    return BankPaymentMethod(
      type: (json['type'] as String?) ?? '',
      name: json['name'] as String?,
      bankName: json['bankName'] as String?,
      routingNumber: switch (json['routingNumber']) {
        final String r? => int.tryParse(r),
        final int r => r,
        _ => null,
      },
      bankAccountNumber: json['bankAccountNumber'] as String?,
      isoCountryCode: json['isoCountryCode'] as String?,
      currencyCode: json['currencyCode'] as String?,
      fundingMethod: FundingMethod.fromJson(
        (json['fundingMethod'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }

  /// Payment method type, e.g. `'BANK'`.
  final String type;

  /// Account holder name.
  final String? name;

  /// Bank name, e.g. `'Bank of America'`. Safe to display.
  final String? bankName;

  /// Routing number. US-only; null for non-US accounts.
  final int? routingNumber;

  /// Masked account number, e.g. `'******1234'`. Safe to display.
  final String? bankAccountNumber;

  /// ISO 3166-1 alpha-2 country code, e.g. `'US'`.
  final String? isoCountryCode;

  /// ISO 4217 currency code, e.g. `'USD'`.
  final String? currencyCode;

  /// Funding method reference — send to backend.
  final FundingMethod fundingMethod;
}
