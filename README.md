# veem_flutter

Flutter SDK for [Veem Global Payments](https://developer.veem.com/).

Wraps Veem's Web SDK in a WebView and exposes a native Flutter API. The
Web SDK runs inside the WebView; Flutter widgets and an imperative
`present()` method are the public surface. Plugin updates ship from Veem's
CDN, and PCI scope stays with Veem.

## Status

| Plugin                          | v1 | Notes |
|---------------------------------|----|-------|
| Card                            | ✅ | This release. |
| Bank                            | ⏳ | Undetermined. |
| Payee                           | ⏳ | Undetermined. |
| Beneficial Ownership Info       | ⏳ | Undetermined. |
| Plaid                           | ⏳ | Undetermined. Bank OAuth redirects in WebView need attention. |
| Identity Check                  | ⏳ | Undetermined. Requires camera permissions plumbing. |

## Install

This package is distributed via Git, not pub.dev. Add it to your app's
`pubspec.yaml` and pin to a release tag:

```yaml
dependencies:
  veem_flutter:
    git:
      url: https://github.com/bushaHQ/veem_flutter.git
      ref: v0.1.0
```

Always pin `ref:` to a tag. Pointing it at a branch (`ref: main`) means
every `flutter pub get` can silently pull new code.

## Releasing

1. Bump `version:` in this package's `pubspec.yaml`.
2. Update `CHANGELOG.md`.
3. Commit, then tag and push:

   ```sh
   git tag v0.1.0
   git push origin dev --tags
   ```

4. Consuming apps bump their `ref:` to the new tag and run
   `flutter pub get`.

## Platform setup

WebView requires platform configuration. See the
[`webview_flutter`](https://pub.dev/packages/webview_flutter) docs for the
current minimum versions.

- **iOS:** minimum deployment target 12.0. No additional Info.plist entries
  needed for the Card plugin in v1 (camera permissions arrive with Identity
  Check).
- **Android:** `minSdkVersion 21`. Internet permission is included by
  default.

## Quick start

### 1. Initialize once at app startup

```dart
import 'package:veem_flutter/veem_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Veem.initialize(const VeemConfig(
    environment: VeemEnvironment.sandbox,
    clientId: 'your-veem-client-id',
  ));
  runApp(const MyApp());
}
```

### 2. Fetch per-customer credentials from your backend

Your backend calls Veem's
[search customer by email](https://developer.veem.com/reference/searchcustomersusingget_2)
endpoint using your **partner OAuth token** and returns the resulting
`accountId` and `sessionSecret` to your app. **Never embed your partner
token, partner secret, or any long-lived credential in the mobile binary.**

### 3. Launch the card plugin

**Modal (imperative):**

```dart
final result = await Veem.card.present(
  context,
  config: CardPluginConfig(
    accountId: accountId,
    sessionSecret: sessionSecret,
    referenceId: 'order_$orderId',
    preset: const CardPreset(amount: 500, currencyCode: 'USD'),
    headerText: 'Add your card',
  ),
);

switch (result) {
  case CardPluginCompleted(:final userInputs):
    final fundingId = userInputs.paymentMethod.fundingMethod.id;
    // Send fundingId to your backend; call Create Payment API with it.
  case CardPluginExited():
    // User cancelled.
  case CardPluginErrored(:final error):
    // Surface error.message to the user.
}
```

**Embedded widget:**

```dart
VeemCardPlugin(
  config: CardPluginConfig(...),
  onCompleted: (event) { /* ... */ },
  onExited: () { /* ... */ },
  onErrored: (error) { /* ... */ },
)
```

### 4. Custom styling

Pass Veem's style structure directly as a map:

```dart
CardPluginConfig(
  // ...
  style: {
    'typography': {
      'fontFamily': 'Roboto',
      'color': '#1A1A1A',
      'fontSize': 14,
    },
    'button': {
      'backgroundColor': '#0076F7',
      'color': '#FFFFFF',
      'borderRadius': 8,
    },
  },
)
```

The full style schema is documented at
<https://developer.veem.com/docs/card-plugin>. A typed style builder is
planned for a later release.

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Merchant Flutter app                           │
│  ─────────────────                              │
│  Veem.initialize(VeemConfig)                    │
│  Veem.card.present(context, config)             │
│  VeemCardPlugin(config: ...)                    │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│  Bridge layer (Dart)                            │
│  ─────────────────                              │
│  VeemWebView — loads assets/web/index.html      │
│  BridgeMessage — JSON envelope, both directions │
│  JavaScriptChannel('VeemHost')                  │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│  WebView                                        │
│  ─────────────────                              │
│  index.html (bundled asset)                     │
│   • injected config (env, clientId, etc.)       │
│   • loads veem-web-sdk from unpkg.com           │
│   • `new Veem.WebSDK({...})` mounts plugin      │
│   • onComplete/onExit/onError → VeemHost        │
└─────────────────────────────────────────────────┘
```

## Web SDK version pinning

`VeemConfig.webSdkVersion` defaults to `'0'`, which resolves to the latest
0.x release on unpkg. **For production, pin to an exact version you've
tested:**

```dart
const VeemConfig(
  // ...
  webSdkVersion: '0.x.y',  // replace with the version you tested
)
```

Otherwise a breaking change in the Web SDK can ship into your app silently
the next time a user opens the plugin.

## Known limitations

- **Card plugin only available.** Bank, Payee, BOI, Plaid, Identity Check coming
  in subsequent releases.
- **Style API is untyped.** You pass the raw Veem style map. Typed builder
  planned.
- **No offline detection.** The Web SDK loads from a CDN; the plugin won't
  work without network, and the error surface for that case is generic
  (`VeemErrorCode.networkError`).
- **Web SDK exact init signature.** This SDK assumes the Web SDK exposes
  itself as `window.Veem.WebSDK` and accepts the config shape documented
  on Veem's Card Plugin page. If Veem changes that shape, the bridge in
  `assets/web/index.html` is the place to adjust.

## License

MIT
