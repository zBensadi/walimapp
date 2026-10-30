import 'supported_app_language.dart';

/// Pure-Dart domain value object representing the user's independent locale preferences.
///
/// Manages both the UI language ([uiLanguage], stored as `'language_pref'`)
/// and the default document language ([defaultDocumentLanguage], stored as `'default_doc_lang'`).
///
/// This file MUST NOT import Flutter UI packages.
class AppLocalePreference {
  const AppLocalePreference({
    required this.uiLanguage,
    required this.defaultDocumentLanguage,
  });

  /// Factory creating an initial preference when no stored preferences exist.
  factory AppLocalePreference.initial({required String osLanguageCode}) {
    final initial = SupportedAppLanguage.resolveInitial(
      osLanguageCode: osLanguageCode,
    );
    return AppLocalePreference(
      uiLanguage: initial,
      defaultDocumentLanguage: initial,
    );
  }

  /// Deserializes preferences from JSON with independent per-field fallback.
  ///
  /// If one field is corrupted, missing, or unrecognized, it falls back
  /// independently to the OS language (or French) without affecting the other field.
  factory AppLocalePreference.fromJson(
    Map<String, dynamic> json, {
    required String osLanguageCode,
  }) {
    final rawUi = json['language_pref'];
    final rawDoc = json['default_doc_lang'];

    final ui = SupportedAppLanguage.resolveInitial(
      storedCode: rawUi is String ? rawUi : null,
      osLanguageCode: osLanguageCode,
    );

    final doc = SupportedAppLanguage.resolveInitial(
      storedCode: rawDoc is String ? rawDoc : null,
      osLanguageCode: osLanguageCode,
    );

    return AppLocalePreference(
      uiLanguage: ui,
      defaultDocumentLanguage: doc,
    );
  }

  /// The active user interface language (controls UI labels, directionality, and layout).
  final SupportedAppLanguage uiLanguage;

  /// The default language for future generated PDF contracts and payment receipts.
  final SupportedAppLanguage defaultDocumentLanguage;

  /// Returns a copy with a new UI language, leaving [defaultDocumentLanguage] unchanged.
  AppLocalePreference copyWithUiLanguage(SupportedAppLanguage newUiLanguage) {
    return AppLocalePreference(
      uiLanguage: newUiLanguage,
      defaultDocumentLanguage: defaultDocumentLanguage,
    );
  }

  /// Returns a copy with a new default document language, leaving [uiLanguage] unchanged.
  AppLocalePreference copyWithDefaultDocumentLanguage(
    SupportedAppLanguage newDocLanguage,
  ) {
    return AppLocalePreference(
      uiLanguage: uiLanguage,
      defaultDocumentLanguage: newDocLanguage,
    );
  }

  /// Serializes to a JSON map conforming to `contracts/owner-preferences.schema.json`.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema_version': 1,
      'language_pref': uiLanguage.languageCode,
      'default_doc_lang': defaultDocumentLanguage.languageCode,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLocalePreference &&
          runtimeType == other.runtimeType &&
          uiLanguage == other.uiLanguage &&
          defaultDocumentLanguage == other.defaultDocumentLanguage;

  @override
  int get hashCode => Object.hash(uiLanguage, defaultDocumentLanguage);

  @override
  String toString() =>
      'AppLocalePreference(ui: ${uiLanguage.languageCode}, doc: ${defaultDocumentLanguage.languageCode})';
}
