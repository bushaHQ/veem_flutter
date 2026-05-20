/// Envelope for messages flowing across the JS bridge.
///
/// Both Flutter→JS commands and JS→Flutter events use the same shape:
/// `{ type: string, payload: object }`. Keeping it uniform makes the
/// bridge code on both sides trivial.
class BridgeMessage {
  /// Construct a bridge message.
  const BridgeMessage({required this.type, this.payload = const {}});

  /// Parse a message from a JSON map.
  factory BridgeMessage.fromJson(Map<String, dynamic> json) {
    return BridgeMessage(
      type: (json['type'] as String?) ?? 'unknown',
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Message type discriminator.
  ///
  /// Known incoming types from JS: `ready`, `complete`, `exit`, `error`.
  /// Known outgoing types to JS: `mount`, `dispose`.
  final String type;

  /// Type-specific data.
  final Map<String, dynamic> payload;

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {'type': type, 'payload': payload};
}
