# Changelog

## 0.1.0

Initial release.

### Added
- `Veem.initialize(VeemConfig)` — global SDK init.
- `Veem.card.present(context, config)` — imperative modal API returning
  a sealed `CardPluginResult`.
- `VeemCardPlugin` — embeddable widget for inline card capture.
- WebView-based bridge loading the Veem Web SDK from unpkg.
- Typed models for `UserInputs`, `PaymentMethod`, `FundingMethod`,
  `BillingAddress`.
- Typed error model (`VeemError` + `VeemErrorCode`).

### Known limitations
- Card plugin only. Bank, Payee, BOI, Plaid, Identity Check planned.
- Style API accepts raw Map (matches Veem's documented schema); typed
  builder planned.
- Web SDK version defaults to `'0'` (caret-zero on unpkg); pin to exact
  version for production.
