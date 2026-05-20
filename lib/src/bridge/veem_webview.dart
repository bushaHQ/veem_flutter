import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../core/config.dart';
import '../core/errors.dart';
import '../core/veem.dart';
import 'bridge_message.dart';

/// Internal widget. Hosts a [WebView] that runs the Veem Web SDK and
/// forwards bridge events out via [onMessage].
///
/// Not part of the public API. Each plugin (Card, Bank, etc.) builds on
/// this with the appropriate `pluginName` and `pluginConfig`.
class VeemWebView extends StatefulWidget {
  /// Construct a Veem WebView.
  const VeemWebView({
    required this.pluginName,
    required this.pluginConfig,
    required this.onMessage,
    this.loadingBuilder,
    super.key,
  });

  /// The Web SDK plugin name to mount.
  ///
  /// Maps to the `name` parameter of `new Veem.WebSDK({...})`. For the card
  /// plugin this is `'collectAccountInformation'`.
  final String pluginName;

  /// Configuration passed into the Web SDK. Marshalled to JSON and injected
  /// into the WebView at load time.
  final Map<String, dynamic> pluginConfig;

  /// Called for every event coming out of the Web SDK.
  final void Function(BridgeMessage) onMessage;

  /// Custom loading widget while the WebView and Web SDK initialize.
  final Widget? loadingBuilder;

  @override
  State<VeemWebView> createState() => _VeemWebViewState();
}

class _VeemWebViewState extends State<VeemWebView> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(const Color(0x00000000))
    ..addJavaScriptChannel('VeemHost', onMessageReceived: _handleJsMessage)
    ..setOnConsoleMessage(_handleConsoleMessage)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          if (!_disposed && mounted) {
            setState(() => _isLoading = false);
          }
        },
        onWebResourceError: (error) {
          if (_disposed) return;
          widget.onMessage(
            BridgeMessage(
              type: 'error',
              payload: {
                'code': VeemErrorCode.webviewLoadFailed.name,
                'message': 'WebView resource error: ${error.description}',
                'details': {
                  'errorType': error.errorType?.name,
                  'errorCode': error.errorCode,
                },
              },
            ),
          );
        },
      ),
    );
  bool _isLoading = true;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final config = Veem.config;
      final html = await _buildHtml(config);
      if (_disposed) return;
      if (config.enableWebViewDebugging) {
        final platform = _controller.platform;
        if (platform is WebKitWebViewController) {
          await platform.setInspectable(true);
        }
      }
      await _controller.loadHtmlString(html, baseUrl: 'https://veem.local/');
    } on VeemError catch (e) {
      widget.onMessage(
        BridgeMessage(
          type: 'error',
          payload: {'code': e.code.name, 'message': e.message},
        ),
      );
    } catch (e, st) {
      widget.onMessage(
        BridgeMessage(
          type: 'error',
          payload: {
            'code': VeemErrorCode.webviewLoadFailed.name,
            'message': 'Failed to initialize WebView: $e',
            'details': {'stackTrace': st.toString()},
          },
        ),
      );
    }
  }

  Future<String> _buildHtml(VeemConfig config) async {
    final shell = await rootBundle.loadString(
      'packages/veem_flutter/assets/web/index.html',
    );

    final injected = <String, String>{
      '{{VEEM_WEBSDK_VERSION}}': _jsonEscape(config.webSdkVersion),
      '{{VEEM_ENV}}': _jsonEscape(config.environment.wireValue),
      '{{VEEM_CLIENT_ID}}': _jsonEscape(config.clientId),
      '{{VEEM_PLUGIN_NAME}}': _jsonEscape(widget.pluginName),
      '{{VEEM_PLUGIN_CONFIG}}': jsonEncode(widget.pluginConfig),
      '{{VEEM_ENABLE_LOGGING}}': config.enableLogging ? 'true' : 'false',
    };

    var out = shell;
    injected.forEach((k, v) => out = out.replaceAll(k, v));
    return out;
  }

  String _jsonEscape(String value) => jsonEncode(value);

  void _handleConsoleMessage(JavaScriptConsoleMessage message) {
    if (_disposed) return;
    if (Veem.isInitialized && Veem.config.enableLogging) {
      developer.log(
        'webview console [${message.level.name}]: ${message.message}',
        name: 'veem_flutter',
      );
    }
    if (message.level == JavaScriptLogLevel.error) {
      widget.onMessage(
        BridgeMessage(
          type: 'error',
          payload: {
            'code': VeemErrorCode.bridgeError.name,
            'message': 'WebView console error: ${message.message}',
          },
        ),
      );
    }
  }

  void _handleJsMessage(JavaScriptMessage message) {
    if (_disposed) return;
    try {
      final json = jsonDecode(message.message) as Map<String, dynamic>;
      final bridge = BridgeMessage.fromJson(json);
      if (Veem.isInitialized && Veem.config.enableLogging) {
        developer.log('bridge: ${bridge.type}', name: 'veem_flutter');
      }
      widget.onMessage(bridge);
    } catch (e) {
      widget.onMessage(
        BridgeMessage(
          type: 'error',
          payload: {
            'code': VeemErrorCode.bridgeError.name,
            'message': 'Failed to parse bridge message: $e',
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        if (_isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child:
                  widget.loadingBuilder ??
                  const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
