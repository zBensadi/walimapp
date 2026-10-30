import 'package:flutter_test/flutter_test.dart';
import 'package:owner/core/formatting/western_numeral_formatter.dart';
import 'package:owner/domain/locale/supported_app_language.dart';

void main() {
  group('WesternNumeralFormatter', () {
    test('normalizes Eastern Arabic-Indic digits to ASCII 0-9', () {
      const eastern = '٠١٢٣٤٥٦٧٨٩';
      expect(WesternNumeralFormatter.normalizeWesternNumerals(eastern), '0123456789');
    });

    test('normalizes Persian/Extended Arabic-Indic digits to ASCII 0-9', () {
      const persian = '۰۱۲۳۴۵۶۷۸۹';
      expect(WesternNumeralFormatter.normalizeWesternNumerals(persian), '0123456789');
    });

    test('leaves existing ASCII digits and non-digit characters unchanged', () {
      const mixed = 'Hello 1234 Alger 16000!';
      expect(WesternNumeralFormatter.normalizeWesternNumerals(mixed), mixed);
    });

    test('formats integers with Western Arabic digits across all locales', () {
      const sample = 1500000;

      final ar = WesternNumeralFormatter.formatInteger(
        sample,
        language: SupportedAppLanguage.ar,
      );
      final fr = WesternNumeralFormatter.formatInteger(
        sample,
        language: SupportedAppLanguage.fr,
      );
      final en = WesternNumeralFormatter.formatInteger(
        sample,
        language: SupportedAppLanguage.en,
      );

      // Verify no Eastern Arabic digits present in any output
      expect(ar.contains(RegExp(r'[٠-٩۰-۹]')), isFalse);
      expect(fr.contains(RegExp(r'[٠-٩۰-۹]')), isFalse);
      expect(en.contains(RegExp(r'[٠-٩۰-۹]')), isFalse);

      expect(ar, '1 500 000');
      expect(fr, '1 500 000');
      expect(en, '1,500,000');
    });

    test('formats negative integers properly', () {
      final neg = WesternNumeralFormatter.formatInteger(-2500);
      expect(neg, '-2 500');
    });

    test('formats currency in integer whole-DZD with Western numerals', () {
      const amount = 350000;

      final ar = WesternNumeralFormatter.formatCurrencyDzd(
        amount,
        language: SupportedAppLanguage.ar,
      );
      final fr = WesternNumeralFormatter.formatCurrencyDzd(
        amount,
        language: SupportedAppLanguage.fr,
      );
      final en = WesternNumeralFormatter.formatCurrencyDzd(
        amount,
        language: SupportedAppLanguage.en,
      );

      expect(ar, '350 000 د.ج');
      expect(fr, '350 000 DZD');
      expect(en, '350,000 DZD');

      expect(ar.contains(RegExp(r'[٠-٩۰-۹]')), isFalse);
    });

    test('formats ISO dates with Western numerals YYYY-MM-DD', () {
      final date = DateTime(2026, 10, 30);
      final formatted = WesternNumeralFormatter.formatIsoDate(date);
      expect(formatted, '2026-10-30');
      expect(formatted.contains(RegExp(r'[٠-٩۰-۹]')), isFalse);
    });
  });
}
