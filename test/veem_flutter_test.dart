import 'package:flutter_test/flutter_test.dart';
import 'package:veem_flutter/veem_flutter.dart';

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
        style: {
          'button': {'color': '#fff'},
        },
      );

      final json = config.toJson();
      expect(json['configuration']['style'], {
        'button': {'color': '#fff'},
      });
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
}
