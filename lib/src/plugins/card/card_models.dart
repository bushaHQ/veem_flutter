import '../../core/errors.dart';
import '../../style/veem_style.dart';

/// Configuration for the Veem Card plugin.
///
/// Per-customer credentials ([accountId], [sessionSecret]) must be fetched
/// from your backend before launching the plugin. Your backend calls
/// Veem's "search customer by email" endpoint with your partner OAuth
/// token to get these values for a given customer.
///
/// Never embed your partner OAuth token, partner secret, or any long-lived
/// credential in a mobile binary — only the short-lived per-session
/// credentials below are safe to pass to the SDK.
class CardPluginConfig {
  /// Construct a card plugin configuration.
  const CardPluginConfig({
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
  final CardPreset? preset;

  /// Custom header text shown above the card form.
  ///
  /// Maps to `configuration.paymentOptions[0].header`.
  final String? headerText;

  /// Custom styling for the plugin UI.
  ///
  /// Use [VeemStyle.fromTheme] to derive a style from your Material
  /// theme, or construct one directly. The full schema is documented at
  /// https://developer.veem.com/docs/card-plugin.
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
          {'type': 'Card', 'header': ?headerText},
        ],
        'style': ?style?.toJson(),
      },
    };
  }
}

/// Amount/currency preset for the plugin UI.
class CardPreset {
  /// Construct a card preset.
  const CardPreset({required this.amount, required this.currencyCode});

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

/// Sealed result returned by [CardPluginApi.present] (and by the widget's
/// callbacks, via the success/exit/error events).
sealed class CardPluginResult {
  const CardPluginResult();
}

/// User completed the card flow successfully.
///
/// [userInputs.paymentMethod.fundingMethod.id] is the Veem funding id —
/// send it to your backend to attach to a payment via the Create Payment
/// API.
class CardPluginCompleted extends CardPluginResult {
  /// Construct a completed event.
  const CardPluginCompleted({
    required this.referenceId,
    required this.userInputs,
    this.preset,
  });

  /// The [CardPluginConfig.referenceId] you passed in, echoed back.
  final String referenceId;

  /// Optional preset that was active during the flow.
  final Map<String, dynamic>? preset;

  /// Card details collected by the plugin.
  final UserInputs userInputs;
}

/// User exited / cancelled the plugin without completing it.
class CardPluginExited extends CardPluginResult {
  /// Construct an exited event.
  const CardPluginExited();
}

/// Plugin failed. Inspect [error] for cause.
class CardPluginErrored extends CardPluginResult {
  /// Construct an errored event.
  const CardPluginErrored(this.error);

  /// The error that occurred.
  final VeemError error;
}

/// Information captured by the card plugin and returned on success.
///
/// Mirrors the `userInputs` shape from
/// https://developer.veem.com/docs/card-plugin.
class UserInputs {
  /// Construct a UserInputs.
  const UserInputs({required this.paymentMethod, required this.raw});

  /// Parse from the Web SDK payload.
  factory UserInputs.fromJson(Map<String, dynamic> json) {
    return UserInputs(
      paymentMethod: PaymentMethod.fromJson(
        (json['paymentMethod'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      raw: json,
    );
  }

  /// The captured payment method.
  final PaymentMethod paymentMethod;

  /// Raw JSON from the Web SDK. Useful if Veem adds fields we haven't
  /// typed yet.
  final Map<String, dynamic> raw;
}

/// A captured payment method.
class PaymentMethod {
  /// Construct a payment method.
  const PaymentMethod({
    required this.type,
    required this.fundingMethod,
    this.nameOnCard,
    this.displayName,
    this.address,
  });

  /// Parse from JSON.
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      type: (json['type'] as String?) ?? '',
      nameOnCard: json['nameOnCard'] as String?,
      displayName: json['displayName'] as String?,
      fundingMethod: FundingMethod.fromJson(
        (json['fundingMethod'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      address: json['address'] == null
          ? null
          : BillingAddress.fromJson(
              (json['address'] as Map).cast<String, dynamic>(),
            ),
    );
  }

  /// Card type, e.g. `'CREDIT'`.
  final String type;

  /// Name on card.
  final String? nameOnCard;

  /// Display string, e.g. `'Visa ****1234'`. Safe to render to users.
  final String? displayName;

  /// Funding method reference — send to backend.
  final FundingMethod fundingMethod;

  /// Billing address.
  final BillingAddress? address;
}

/// Veem funding method reference. Pass [id] to the Create Payment API.
class FundingMethod {
  /// Construct a funding method.
  const FundingMethod({required this.type, required this.id});

  /// Parse from JSON.
  factory FundingMethod.fromJson(Map<String, dynamic> json) {
    return FundingMethod(
      type: (json['type'] as String?) ?? 'Card',
      id: int.tryParse((json['id'] as String?) ?? '') ?? 0,
    );
  }

  /// Funding method type, e.g. `'Card'`.
  final String type;

  /// Veem-internal funding id. Send to backend, do not display.
  final int id;
}

/// Billing address captured by the plugin.
class BillingAddress {
  /// Construct a billing address.
  const BillingAddress({
    this.street,
    this.city,
    this.stateProvince,
    this.countryCode,
    this.postalCode,
  });

  /// Parse from JSON.
  factory BillingAddress.fromJson(Map<String, dynamic> json) {
    return BillingAddress(
      street: json['street'] as String?,
      city: json['city'] as String?,
      stateProvince: json['stateProvince'] as String?,
      countryCode: json['countryCode'] as String?,
      postalCode: json['postalCode'] as String?,
    );
  }

  /// Street.
  final String? street;

  /// City.
  final String? city;

  /// State or province.
  final String? stateProvince;

  /// ISO 3166-1 alpha-2 country code.
  final String? countryCode;

  /// Postal / ZIP code.
  final String? postalCode;
}
