import 'package:flutter/material.dart';

/// Typed builder for the Veem Web SDK's `style` configuration.
///
/// Mirrors the schema documented at
/// https://developer.veem.com/docs/card-plugin (the `style` object).
/// Pass a [VeemStyle] to [CardPluginConfig.style] and it will be
/// serialized to the JSON shape the Web SDK expects.
///
/// For forward compatibility, [extra] is merged into the output map after
/// the typed fields — use it to pass Web SDK style keys that aren't yet
/// typed here. Keys in [extra] override typed fields if they collide.
///
/// ```dart
/// const VeemStyle(
///   typography: VeemTypography(
///     fontFamily: 'Roboto',
///     color: Color(0xFF1A1A1A),
///     fontSize: 14,
///   ),
///   button: VeemButtonStyle(
///     backgroundColor: Color(0xFF0076F7),
///     color: Colors.white,
///     borderRadius: 8,
///   ),
/// )
/// ```
///
/// Or auto-derive from your app's Material theme:
///
/// ```dart
/// VeemStyle.fromTheme(Theme.of(context))
/// ```
@immutable
class VeemStyle {
  /// Construct a style.
  const VeemStyle({
    this.typography,
    this.header,
    this.input,
    this.button,
    this.extra,
  });

  /// Derive a default style from a Material [ThemeData].
  ///
  /// Pulls colors from the color scheme and text styles from the text
  /// theme, producing a reasonable Veem styling that matches the host
  /// app's look. Override individual fields by constructing your own
  /// [VeemStyle] and copying the bits you want.
  factory VeemStyle.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final body = theme.textTheme.bodyMedium;
    final heading = theme.textTheme.headlineSmall;
    final label = theme.textTheme.labelLarge;

    return VeemStyle(
      typography: VeemTypography(
        fontFamily: body?.fontFamily,
        color: scheme.onSurface,
        fontSize: 14,
        weight: FontWeight.w400,
        error: VeemTypography(
          color: scheme.error,
          fontFamily: body?.fontFamily,
          fontSize: 14,
          weight: FontWeight.w400,
        ),
      ),
      header: VeemHeaderStyle(
        fontFamily: heading?.fontFamily ?? body?.fontFamily,
        fontSize: 22,
        weight: FontWeight.w700,
      ),
      input: VeemInputStyle(
        backgroundColor: scheme.surface,
        borderColor: scheme.outline,
        placeholderColor: scheme.outline,
        height: 48,
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        error: VeemInputStyle(
          backgroundColor: scheme.errorContainer,
          borderColor: scheme.error,
          placeholderColor: scheme.outline,
          height: 48,
          borderRadius: 8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      button: VeemButtonStyle(
        backgroundColor: scheme.primary,
        color: scheme.onPrimary,
        fontFamily: label?.fontFamily ?? body?.fontFamily,
        fontSize: 16,
        weight: FontWeight.w600,
        borderRadius: 8,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  /// Base text styling.
  final VeemTypography? typography;

  /// Header styling.
  final VeemHeaderStyle? header;

  /// Input field styling.
  final VeemInputStyle? input;

  /// Primary action button styling.
  final VeemButtonStyle? button;

  /// Escape hatch for Web SDK style keys that aren't typed here yet.
  /// Merged into the output AFTER the typed fields, so collisions in
  /// [extra] win.
  final Map<String, dynamic>? extra;

  /// Serialize to the JSON shape the Web SDK expects.
  Map<String, dynamic> toJson() {
    return {
      'typography': ?typography?.toJson(),
      'header': ?header?.toJson(),
      'input': ?input?.toJson(),
      'button': ?button?.toJson(),
      ...?extra,
    };
  }
}

/// Typography section of [VeemStyle].
///
/// Used both as the base typography and as the [error] sub-style (which
/// applies when fields are in an error state).
@immutable
class VeemTypography {
  /// Construct a typography style.
  const VeemTypography({
    this.fontFamily,
    this.color,
    this.weight,
    this.fontSize,
    this.error,
  });

  /// Font family name. Must be a font available in the WebView's runtime
  /// (system font or web-loaded). Custom fonts bundled in your Flutter
  /// app are NOT automatically available — the WebView runs an isolated
  /// rendering context.
  final String? fontFamily;

  /// Text color.
  final Color? color;

  /// Font weight. Maps to numeric CSS weight (100-900).
  final FontWeight? weight;

  /// Font size in CSS pixels.
  final double? fontSize;

  /// Override typography when fields are in an error state.
  final VeemTypography? error;

  /// JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      'fontFamily': ?fontFamily,
      if (color case final color?) 'color': colorToHex(color),
      if (weight case final weight?) 'weight': fontWeightToInt(weight),
      'fontSize': ?fontSize,
      'error': ?error?.toJson(),
    };
  }
}

/// Header styling.
@immutable
class VeemHeaderStyle {
  /// Construct a header style.
  const VeemHeaderStyle({this.fontFamily, this.fontSize, this.weight});

  /// Font family.
  final String? fontFamily;

  /// Font size in CSS pixels.
  final double? fontSize;

  /// Font weight.
  final FontWeight? weight;

  /// JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      'fontFamily': ?fontFamily,
      'fontSize': ?fontSize,
      if (weight case final weight?) 'weight': fontWeightToInt(weight),
    };
  }
}

/// Input field styling.
@immutable
class VeemInputStyle {
  /// Construct an input style.
  const VeemInputStyle({
    this.backgroundColor,
    this.borderColor,
    this.placeholderColor,
    this.height,
    this.borderRadius,
    this.padding,
    this.error,
  });

  /// Background color of input fields.
  final Color? backgroundColor;

  /// Border color in default state.
  final Color? borderColor;

  /// Placeholder text color.
  final Color? placeholderColor;

  /// Field height in CSS pixels.
  final double? height;

  /// Corner radius in CSS pixels.
  final double? borderRadius;

  /// Padding inside the input. Mapped to `paddingTop`, `paddingRight`,
  /// `paddingBottom`, `paddingLeft` in the Web SDK schema.
  final EdgeInsets? padding;

  /// Override styling when the input is in an error state.
  final VeemInputStyle? error;

  /// JSON serialization. Note: input padding is emitted as flat
  /// `paddingTop`/`paddingRight`/`paddingBottom`/`paddingLeft` keys to
  /// match Veem's documented schema (not as a nested padding object).
  Map<String, dynamic> toJson() {
    return {
      if (backgroundColor case final backgroundColor?)
        'backgroundColor': colorToHex(backgroundColor),
      if (borderColor case final borderColor?)
        'borderColor': colorToHex(borderColor),
      if (placeholderColor case final placeholderColor?)
        'placeholderColor': colorToHex(placeholderColor),
      'height': ?height,
      'borderRadius': ?borderRadius,
      if (padding case final padding?) ...{
        'paddingTop': padding.top,
        'paddingRight': padding.right,
        'paddingBottom': padding.bottom,
        'paddingLeft': padding.left,
      },
      'error': ?error?.toJson(),
    };
  }
}

/// Button styling.
@immutable
class VeemButtonStyle {
  /// Construct a button style.
  const VeemButtonStyle({
    this.height,
    this.minWidth,
    this.padding,
    this.textTransform,
    this.backgroundColor,
    this.color,
    this.fontFamily,
    this.fontSize,
    this.weight,
    this.borderRadius,
    this.border,
    this.hover,
    this.disabled,
  });

  /// Button height in CSS pixels.
  final double? height;

  /// Minimum button width in CSS pixels.
  final double? minWidth;

  /// Padding inside the button. Mapped to nested
  /// `padding: { top, right, bottom, left }` in the Web SDK schema.
  final EdgeInsets? padding;

  /// CSS text transform applied to button label.
  final VeemTextTransform? textTransform;

  /// Background color.
  final Color? backgroundColor;

  /// Text color.
  final Color? color;

  /// Font family.
  final String? fontFamily;

  /// Font size.
  final double? fontSize;

  /// Font weight.
  final FontWeight? weight;

  /// Corner radius.
  final double? borderRadius;

  /// Border styling.
  final VeemBorder? border;

  /// Style when the button is in hover state (mostly relevant on web /
  /// desktop pointer devices; touch devices won't see this).
  final VeemButtonStateStyle? hover;

  /// Style when the button is disabled.
  final VeemButtonStateStyle? disabled;

  /// JSON serialization. Note: button padding is emitted as a nested
  /// `padding: { top, right, bottom, left }` object to match Veem's
  /// documented schema (different from input padding).
  Map<String, dynamic> toJson() {
    return {
      'height': ?height,
      'minWidth': ?minWidth,
      if (padding case final padding?) ...{
        'padding': {
          'top': padding.top,
          'right': padding.right,
          'bottom': padding.bottom,
          'left': padding.left,
        },
      },
      'textTransform': ?textTransform?.wireValue,
      if (backgroundColor case final backgroundColor?)
        'backgroundColor': colorToHex(backgroundColor),
      if (color case final color?) 'color': colorToHex(color),
      'fontFamily': ?fontFamily,
      'fontSize': ?fontSize,
      if (weight case final weight?) 'weight': fontWeightToInt(weight),
      'borderRadius': ?borderRadius,
      'border': ?border?.toJson(),
      'hover': ?hover?.toJson(),
      'disabled': ?disabled?.toJson(),
    };
  }
}

/// Button border styling.
@immutable
class VeemBorder {
  /// Construct a border.
  const VeemBorder({this.color, this.width, this.style});

  /// Border color.
  final Color? color;

  /// Border width in CSS pixels.
  final double? width;

  /// Border style (e.g. solid, dashed).
  final VeemBorderStyle? style;

  /// JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      if (color case final color?) 'color': colorToHex(color),
      'width': ?width,
      'style': ?style?.wireValue,
    };
  }
}

/// Button styling for a single state (hover, disabled).
@immutable
class VeemButtonStateStyle {
  /// Construct a state style.
  const VeemButtonStateStyle({this.backgroundColor, this.color});

  /// Background color in this state.
  final Color? backgroundColor;

  /// Text color in this state.
  final Color? color;

  /// JSON serialization.
  Map<String, dynamic> toJson() {
    return {
      if (backgroundColor case final backgroundColor?)
        'backgroundColor': colorToHex(backgroundColor),
      if (color case final color?) 'color': colorToHex(color),
    };
  }
}

/// CSS `text-transform` values supported by Veem.
enum VeemTextTransform {
  /// `none` — no transformation.
  none,

  /// `capitalize` — first letter of each word capitalized.
  capitalize,

  /// `uppercase` — all letters uppercase.
  uppercase,

  /// `lowercase` — all letters lowercase.
  lowercase;

  /// CSS string the Web SDK expects.
  String get wireValue => name;
}

/// CSS `border-style` values supported by Veem.
enum VeemBorderStyle {
  /// `none`.
  none,

  /// `solid`.
  solid,

  /// `dashed`.
  dashed,

  /// `dotted`.
  dotted;

  /// CSS string the Web SDK expects.
  String get wireValue => name;
}

/// Convert a [Color] to a 6-digit hex string (`#RRGGBB`). Alpha is
/// dropped — Veem's documented style schema uses 6-digit hex.
///
/// Exposed for tests; not part of the SDK's public API.
@visibleForTesting
String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Convert a Flutter [FontWeight] to its numeric CSS weight (100-900).
///
/// Exposed for tests; not part of the SDK's public API.
@visibleForTesting
int fontWeightToInt(FontWeight w) => w.value;
