import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veem_flutter/veem_flutter.dart';
import 'package:veem_flutter/src/style/veem_style.dart'
    show colorToHex, fontWeightToInt;

void main() {
  group('Veem.initialize', () {
    test('throws notInitialized before init', () {
      expect(
        () => Veem.config,
        throwsA(
          isA<VeemError>().having(
            (e) => e.code,
            'code',
            VeemErrorCode.notInitialized,
          ),
        ),
      );
    });

    test('isInitialized is false before init', () {
      expect(Veem.isInitialized, isFalse);
    });

    test('isInitialized is true after init', () async {
      await Veem.initialize(
        const VeemConfig(
          environment: VeemEnvironment.sandbox,
          clientId: 'test-client',
        ),
      );
      expect(Veem.isInitialized, isTrue);
      expect(Veem.config.environment, VeemEnvironment.sandbox);
      expect(Veem.config.clientId, 'test-client');
    });
  });

  group('VeemEnvironment.wireValue', () {
    test('sandbox -> "sandbox"', () {
      expect(VeemEnvironment.sandbox.wireValue, 'sandbox');
    });

    test('production -> "production"', () {
      expect(VeemEnvironment.production.wireValue, 'production');
    });
  });

  group('CardPluginConfig.toJson', () {
    test('emits required fields', () {
      const config = CardPluginConfig(
        accountId: 391558,
        sessionSecret: 'secret123',
        referenceId: 'ref_abc',
      );

      final json = config.toJson();
      expect(json['referenceId'], 'ref_abc');
      expect(json['configuration']['accountId'], 391558);
      expect(json['configuration']['sessionSecret'], 'secret123');
      expect(json['configuration']['paymentOptions'], [
        {'type': 'Card'},
      ]);
    });

    test('includes preset when provided', () {
      const config = CardPluginConfig(
        accountId: 1,
        sessionSecret: 's',
        referenceId: 'r',
        preset: CardPreset(amount: 500, currencyCode: 'USD'),
      );

      final json = config.toJson();
      expect(json['preset'], {'amount': 500, 'currencyCode': 'USD'});
    });

    test('includes headerText in paymentOptions when provided', () {
      const config = CardPluginConfig(
        accountId: 1,
        sessionSecret: 's',
        referenceId: 'r',
        headerText: 'Pay with card',
      );

      final json = config.toJson();
      expect(json['configuration']['paymentOptions'], [
        {'type': 'Card', 'header': 'Pay with card'},
      ]);
    });

    test('includes style when provided', () {
      const config = CardPluginConfig(
        accountId: 1,
        sessionSecret: 's',
        referenceId: 'r',
        style: VeemStyle(button: VeemButtonStyle(color: Color(0xFFFFFFFF))),
      );

      final json = config.toJson();
      final style = (json['configuration'] as Map)['style'] as Map;
      expect(style['button'], {'color': '#FFFFFF'});
    });

    test('does not leak clientId — that is attached by the JS bridge', () {
      const config = CardPluginConfig(
        accountId: 1,
        sessionSecret: 's',
        referenceId: 'r',
      );

      final json = config.toJson();
      expect(json['configuration'].containsKey('clientId'), isFalse);
    });
  });

  group('UserInputs.fromJson', () {
    test('parses full payload from Web SDK docs', () {
      final json = <String, dynamic>{
        'paymentMethod': {
          'type': 'CREDIT',
          'nameOnCard': 'Firstname Lastname',
          'fundingMethod': {'type': 'Card', 'id': 123},
          'displayName': 'Visa ****1234',
          'address': {
            'street': '123 Main St.',
            'city': 'San Francisco',
            'stateProvince': 'CA',
            'countryCode': 'US',
            'postalCode': '94111',
          },
        },
      };

      final inputs = UserInputs.fromJson(json);
      expect(inputs.paymentMethod.type, 'CREDIT');
      expect(inputs.paymentMethod.nameOnCard, 'Firstname Lastname');
      expect(inputs.paymentMethod.fundingMethod.type, 'Card');
      expect(inputs.paymentMethod.fundingMethod.id, 123);
      expect(inputs.paymentMethod.displayName, 'Visa ****1234');
      expect(inputs.paymentMethod.address?.city, 'San Francisco');
      expect(inputs.paymentMethod.address?.countryCode, 'US');
    });

    test('handles missing optional fields gracefully', () {
      final inputs = UserInputs.fromJson({
        'paymentMethod': {
          'type': 'CREDIT',
          'fundingMethod': {'type': 'Card', 'id': 99},
        },
      });

      expect(inputs.paymentMethod.nameOnCard, isNull);
      expect(inputs.paymentMethod.displayName, isNull);
      expect(inputs.paymentMethod.address, isNull);
      expect(inputs.paymentMethod.fundingMethod.id, 99);
    });

    test('exposes raw payload for forward compatibility', () {
      final raw = <String, dynamic>{
        'paymentMethod': {
          'type': 'CREDIT',
          'fundingMethod': {'type': 'Card', 'id': 1},
          'futureField': 'something Veem added later',
        },
      };

      final inputs = UserInputs.fromJson(raw);
      expect(inputs.raw, raw);
    });
  });

  group('BankPluginConfig.toJson', () {
    test('emits required fields with Bank paymentOption type', () {
      const config = BankPluginConfig(
        accountId: 391558,
        sessionSecret: 'secret123',
        referenceId: 'ref_abc',
      );

      final json = config.toJson();
      expect(json['referenceId'], 'ref_abc');
      expect(json['configuration']['accountId'], 391558);
      expect(json['configuration']['sessionSecret'], 'secret123');
      expect(json['configuration']['paymentOptions'], [
        {'type': 'Bank'},
      ]);
    });

    test('includes preset when provided', () {
      const config = BankPluginConfig(
        accountId: 1,
        sessionSecret: 's',
        referenceId: 'r',
        preset: BankPreset(amount: 500, currencyCode: 'USD'),
      );

      final json = config.toJson();
      expect(json['preset'], {'amount': 500, 'currencyCode': 'USD'});
    });

    test('includes headerText in paymentOptions when provided', () {
      const config = BankPluginConfig(
        accountId: 1,
        sessionSecret: 's',
        referenceId: 'r',
        headerText: 'Link bank account',
      );

      final json = config.toJson();
      expect(json['configuration']['paymentOptions'], [
        {'type': 'Bank', 'header': 'Link bank account'},
      ]);
    });

    test('includes style when provided', () {
      const config = BankPluginConfig(
        accountId: 1,
        sessionSecret: 's',
        referenceId: 'r',
        style: VeemStyle(button: VeemButtonStyle(color: Color(0xFFFFFFFF))),
      );

      final json = config.toJson();
      final style = (json['configuration'] as Map)['style'] as Map;
      expect(style['button'], {'color': '#FFFFFF'});
    });

    test('does not leak clientId — that is attached by the JS bridge', () {
      const config = BankPluginConfig(
        accountId: 1,
        sessionSecret: 's',
        referenceId: 'r',
      );

      final json = config.toJson();
      expect(json['configuration'].containsKey('clientId'), isFalse);
    });
  });

  group('BankUserInputs.fromJson', () {
    test('parses full payload from Web SDK docs', () {
      final json = <String, dynamic>{
        'paymentMethod': {
          'type': 'BANK',
          'name': 'Firstname Lastname',
          'fundingMethod': {'type': 'bank', 'id': 123},
          'isoCountryCode': 'US',
          'currencyCode': 'USD',
          'bankName': 'Bank of America',
          'routingNumber': 121000358,
          'bankAccountNumber': '******1234',
        },
      };

      final inputs = BankUserInputs.fromJson(json);
      expect(inputs.paymentMethod.type, 'BANK');
      expect(inputs.paymentMethod.name, 'Firstname Lastname');
      expect(inputs.paymentMethod.bankName, 'Bank of America');
      expect(inputs.paymentMethod.routingNumber, 121000358);
      expect(inputs.paymentMethod.bankAccountNumber, '******1234');
      expect(inputs.paymentMethod.isoCountryCode, 'US');
      expect(inputs.paymentMethod.currencyCode, 'USD');
      expect(inputs.paymentMethod.fundingMethod.type, 'bank');
      expect(inputs.paymentMethod.fundingMethod.id, 123);
    });

    test('handles missing optional fields gracefully', () {
      final inputs = BankUserInputs.fromJson({
        'paymentMethod': {
          'type': 'BANK',
          'fundingMethod': {'type': 'bank', 'id': 99},
        },
      });

      expect(inputs.paymentMethod.name, isNull);
      expect(inputs.paymentMethod.bankName, isNull);
      expect(inputs.paymentMethod.routingNumber, isNull);
      expect(inputs.paymentMethod.bankAccountNumber, isNull);
      expect(inputs.paymentMethod.isoCountryCode, isNull);
      expect(inputs.paymentMethod.currencyCode, isNull);
      expect(inputs.paymentMethod.fundingMethod.id, 99);
    });

    test('routingNumber parses from string as well as int', () {
      final inputs = BankUserInputs.fromJson({
        'paymentMethod': {
          'type': 'BANK',
          'routingNumber': '121000358',
          'fundingMethod': {'type': 'bank', 'id': 1},
        },
      });
      expect(inputs.paymentMethod.routingNumber, 121000358);
    });

    test('exposes raw payload for forward compatibility', () {
      final raw = <String, dynamic>{
        'paymentMethod': {
          'type': 'BANK',
          'fundingMethod': {'type': 'bank', 'id': 1},
          'futureField': 'something Veem added later',
        },
      };

      final inputs = BankUserInputs.fromJson(raw);
      expect(inputs.raw, raw);
    });
  });

  group('VeemStyle conversion helpers', () {
    test('colorToHex drops alpha and uppercases', () {
      expect(colorToHex(const Color(0xFF1A1A1A)), '#1A1A1A');
      expect(colorToHex(const Color(0x801A1A1A)), '#1A1A1A');
      expect(colorToHex(const Color(0xFFFFFFFF)), '#FFFFFF');
      expect(colorToHex(const Color(0xFF000000)), '#000000');
    });

    test('fontWeightToInt maps Flutter weights to CSS numeric weights', () {
      expect(fontWeightToInt(FontWeight.w100), 100);
      expect(fontWeightToInt(FontWeight.w400), 400);
      expect(fontWeightToInt(FontWeight.w700), 700);
      expect(fontWeightToInt(FontWeight.w900), 900);
    });
  });

  group('VeemStyle.toJson', () {
    test('serializes typography with nested error sub-style', () {
      const style = VeemStyle(
        typography: VeemTypography(
          fontFamily: 'Roboto',
          color: Color(0xFF1A1A1A),
          weight: FontWeight.w400,
          fontSize: 14,
          error: VeemTypography(color: Color(0xFFB6353B), fontSize: 12),
        ),
      );

      final json = style.toJson();
      expect(json['typography'], {
        'fontFamily': 'Roboto',
        'color': '#1A1A1A',
        'weight': 400,
        'fontSize': 14.0,
        'error': {'color': '#B6353B', 'fontSize': 12.0},
      });
    });

    test('input padding emits FLAT keys (Veem schema quirk)', () {
      const style = VeemStyle(
        input: VeemInputStyle(padding: EdgeInsets.fromLTRB(16, 8, 16, 8)),
      );

      final input = style.toJson()['input'] as Map<String, dynamic>;
      expect(input['paddingTop'], 8);
      expect(input['paddingRight'], 16);
      expect(input['paddingBottom'], 8);
      expect(input['paddingLeft'], 16);
      expect(input.containsKey('padding'), isFalse);
    });

    test('button padding emits NESTED object (Veem schema quirk)', () {
      const style = VeemStyle(
        button: VeemButtonStyle(padding: EdgeInsets.fromLTRB(24, 10, 24, 10)),
      );

      final button = style.toJson()['button'] as Map<String, dynamic>;
      expect(button['padding'], {
        'top': 10.0,
        'right': 24.0,
        'bottom': 10.0,
        'left': 24.0,
      });
    });

    test('button border + hover + disabled states serialize', () {
      const style = VeemStyle(
        button: VeemButtonStyle(
          backgroundColor: Color(0xFF1A1A1A),
          color: Color(0xFFFFFFFF),
          borderRadius: 4,
          border: VeemBorder(
            color: Color(0xFF1A1A1A),
            width: 1,
            style: VeemBorderStyle.solid,
          ),
          hover: VeemButtonStateStyle(
            backgroundColor: Color(0xFF333333),
            color: Color(0xFFFFFFFF),
          ),
          disabled: VeemButtonStateStyle(
            backgroundColor: Color(0xFFE0E0E0),
            color: Color(0xFFB0B7BF),
          ),
        ),
      );

      final button = style.toJson()['button'] as Map<String, dynamic>;
      expect(button['border'], {
        'color': '#1A1A1A',
        'width': 1.0,
        'style': 'solid',
      });
      expect(button['hover'], {
        'backgroundColor': '#333333',
        'color': '#FFFFFF',
      });
      expect(button['disabled'], {
        'backgroundColor': '#E0E0E0',
        'color': '#B0B7BF',
      });
    });

    test('textTransform enum serializes to CSS string', () {
      const style = VeemStyle(
        button: VeemButtonStyle(textTransform: VeemTextTransform.capitalize),
      );
      expect((style.toJson()['button'] as Map)['textTransform'], 'capitalize');
    });

    test('omits all unset fields (no nulls in output)', () {
      const style = VeemStyle();
      expect(style.toJson(), <String, dynamic>{});

      const partial = VeemStyle(
        button: VeemButtonStyle(color: Color(0xFFFFFFFF)),
      );
      final json = partial.toJson();
      expect(json.keys, ['button']);
      expect(json['button'], {'color': '#FFFFFF'});
    });

    test('extra fields are merged in and win on collision', () {
      const style = VeemStyle(
        button: VeemButtonStyle(color: Color(0xFFFFFFFF)),
        extra: {
          'futureKey': {'foo': 'bar'},
          'button': {'overriddenByExtra': true},
        },
      );

      final json = style.toJson();
      expect(json['futureKey'], {'foo': 'bar'});
      // extra spread runs last → button gets overwritten
      expect(json['button'], {'overriddenByExtra': true});
    });
  });

  group('VeemStyle.fromTheme', () {
    test('produces a non-empty style from default ThemeData', () {
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0076F7)),
        useMaterial3: true,
      );

      final style = VeemStyle.fromTheme(theme);
      final json = style.toJson();

      expect(json.containsKey('typography'), isTrue);
      expect(json.containsKey('header'), isTrue);
      expect(json.containsKey('input'), isTrue);
      expect(json.containsKey('button'), isTrue);

      // Button background should match the primary color from the scheme.
      final buttonBg = (json['button'] as Map)['backgroundColor'] as String;
      expect(buttonBg.startsWith('#'), isTrue);
      expect(buttonBg.length, 7);
    });
  });
}
