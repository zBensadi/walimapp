import '../../domain/locale/supported_app_language.dart';

/// Cross-cutting utility enforcing canonical Western Arabic numerals (`0-9`).
///
/// Per Constitution Principle IV and FR-010, all numbers, dates, and whole-DZD
/// monetary amounts across all three languages (`ar`, `fr`, `en`) MUST use
/// Western Arabic digits `0-9`. This formatter normalizes Eastern Arabic-Indic
/// and Persian numeral code points to ASCII `0-9`.
class WesternNumeralFormatter {
  const WesternNumeralFormatter._();

  static const Map<String, String> _easternToWestern = {
    '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
    '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
    '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
    '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
  };

  /// Normalizes any Eastern Arabic-Indic or Persian numerals in [input] to ASCII `0-9`.
  static String normalizeWesternNumerals(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      buffer.write(_easternToWestern[char] ?? char);
    }
    return buffer.toString();
  }

  /// Formats an integer using thousands grouping with ASCII Western digits `0-9`.
  ///
  /// For English: comma grouping (e.g. `1,250,000`).
  /// For French and Arabic: non-breaking space grouping (e.g. `1 250 000`).
  static String formatInteger(
    int value, {
    SupportedAppLanguage language = SupportedAppLanguage.fr,
  }) {
    final isNegative = value < 0;
    final absString = value.abs().toString();
    final buffer = StringBuffer();
    final separator = language == SupportedAppLanguage.en ? ',' : ' ';

    for (var i = 0; i < absString.length; i++) {
      if (i > 0 && (absString.length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(absString[i]);
    }

    final formatted = buffer.toString();
    return isNegative ? '-$formatted' : formatted;
  }

  /// Formats an integer whole Algerian Dinar ([amountDzd]) with its currency symbol.
  ///
  /// Guaranteed to use Western Arabic numerals `0-9`.
  /// - Arabic (`ar`): `"1 250 000 د.ج"`
  /// - French (`fr`): `"1 250 000 DZD"`
  /// - English (`en`): `"1,250,000 DZD"`
  static String formatCurrencyDzd(
    int amountDzd, {
    SupportedAppLanguage language = SupportedAppLanguage.fr,
  }) {
    final formattedDigits = formatInteger(amountDzd, language: language);
    return switch (language) {
      SupportedAppLanguage.ar => '$formattedDigits د.ج',
      SupportedAppLanguage.fr => '$formattedDigits DZD',
      SupportedAppLanguage.en => '$formattedDigits DZD',
    };
  }

  /// Formats a [DateTime] as an ISO-8601 date (`YYYY-MM-DD`) with Western digits `0-9`.
  static String formatIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
