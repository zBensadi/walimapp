/// Pure-Dart domain model for supported application languages.
///
/// This file MUST NOT import Flutter UI packages (e.g. `package:flutter` or `dart:ui`).
library;

enum SupportedAppLanguage {
  ar(languageCode: 'ar', nativeName: 'العربية'),
  fr(languageCode: 'fr', nativeName: 'Français'),
  en(languageCode: 'en', nativeName: 'English');

  const SupportedAppLanguage({
    required this.languageCode,
    required this.nativeName,
  });

  final String languageCode;
  final String nativeName;

  /// Whether this language requires Right-to-Left (RTL) reading and layout direction.
  ///
  /// Mapped to Flutter's [TextDirection] in the presentation layer.
  bool get isRtl => this == SupportedAppLanguage.ar;

  /// Attempts to parse a raw language tag or locale string (e.g., 'fr', 'fr-DZ', 'ar_DZ').
  ///
  /// Normalizes by trimming, lowercasing, and extracting the primary language subtag.
  /// Returns `null` if the input is null, empty, or unsupported.
  static SupportedAppLanguage? tryFromCode(String? rawCode) {
    if (rawCode == null) return null;
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return null;

    final primarySubtag = trimmed.toLowerCase().split(RegExp(r'[-_]')).first;

    for (final language in SupportedAppLanguage.values) {
      if (language.languageCode == primarySubtag) {
        return language;
      }
    }
    return null;
  }

  /// Resolves the initial language deterministically.
  ///
  /// 1. Uses [storedCode] if valid.
  /// 2. Otherwise uses [osLanguageCode] if valid.
  /// 3. Otherwise defaults deterministically to French ([SupportedAppLanguage.fr]).
  static SupportedAppLanguage resolveInitial({
    String? storedCode,
    String? osLanguageCode,
  }) {
    final fromStored = tryFromCode(storedCode);
    if (fromStored != null) {
      return fromStored;
    }

    final fromOs = tryFromCode(osLanguageCode);
    if (fromOs != null) {
      return fromOs;
    }

    return SupportedAppLanguage.fr;
  }
}
