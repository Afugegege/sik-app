import 'package:flutter_test/flutter_test.dart';
import 'package:sik_app/services/quantity_scrubber_helper.dart';

void main() {
  group('QuantityScrubberHelper Tests', () {
    test('Steps ml quantities accurately', () {
      final inc = QuantityScrubberHelper.stepQuantity(
        currentQuantity: '500 ml',
        currentStatus: 'Have',
        increment: true,
      );
      expect(inc.quantityDisplay, '550 ml');
      expect(inc.status, 'Have');

      final dec = QuantityScrubberHelper.stepQuantity(
        currentQuantity: '500 ml',
        currentStatus: 'Have',
        increment: false,
      );
      expect(dec.quantityDisplay, '450 ml');
      expect(dec.status, 'Have');
    });

    test('Steps discrete items and updates pluralization', () {
      final dec = QuantityScrubberHelper.stepQuantity(
        currentQuantity: '2 packs',
        currentStatus: 'Have',
        increment: false,
      );
      expect(dec.quantityDisplay, '1 pack');
      expect(dec.status, 'Have');

      final inc = QuantityScrubberHelper.stepQuantity(
        currentQuantity: '1 pack',
        currentStatus: 'Have',
        increment: true,
      );
      expect(inc.quantityDisplay, '2 packs');
      expect(inc.status, 'Have');
    });

    test('Steps decimal kg quantities cleanly', () {
      final dec = QuantityScrubberHelper.stepQuantity(
        currentQuantity: '1.5 kg',
        currentStatus: 'Have',
        increment: false,
      );
      expect(dec.quantityDisplay, '1.25 kg');

      final inc = QuantityScrubberHelper.stepQuantity(
        currentQuantity: '1.75 kg',
        currentStatus: 'Have',
        increment: true,
      );
      expect(inc.quantityDisplay, '2 kg');
    });

    test('Marks status Missing when quantity reaches 0', () {
      final dec = QuantityScrubberHelper.stepQuantity(
        currentQuantity: '1 can',
        currentStatus: 'Have',
        increment: false,
      );
      expect(dec.quantityDisplay, '0 cans');
      expect(dec.status, 'Missing');
    });

    test('Steps fuzzy qualitative levels correctly', () {
      final dec = QuantityScrubberHelper.stepQuantity(
        currentQuantity: 'Plenty',
        currentStatus: 'Have',
        increment: false,
      );
      expect(dec.quantityDisplay, 'Half');
      expect(dec.status, 'Have');

      final dec2 = QuantityScrubberHelper.stepQuantity(
        currentQuantity: 'A little',
        currentStatus: 'Have',
        increment: false,
      );
      expect(dec2.quantityDisplay, 'Running low');
      expect(dec2.status, 'Running low');

      final dec3 = QuantityScrubberHelper.stepQuantity(
        currentQuantity: 'Almost empty',
        currentStatus: 'Running low',
        increment: false,
      );
      expect(dec3.quantityDisplay, 'Empty');
      expect(dec3.status, 'Missing');
    });

    test('Handles empty/null quantity initialization', () {
      final inc = QuantityScrubberHelper.stepQuantity(
        currentQuantity: null,
        currentStatus: 'Have',
        increment: true,
      );
      expect(inc.quantityDisplay, '1 piece');
      expect(inc.status, 'Have');
    });
  });
}
