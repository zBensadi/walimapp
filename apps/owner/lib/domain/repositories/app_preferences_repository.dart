import '../locale/app_locale_preference.dart';

/// Pure-Dart contract for persisting and restoring owner application preferences.
///
/// This file MUST NOT import Flutter UI packages.
abstract interface class AppPreferencesRepository {
  /// Loads saved locale preferences from persistent storage.
  ///
  /// If storage is missing, unreadable, or corrupted, implementations must fall
  /// back gracefully to initial preferences resolved against [osLanguageCode].
  Future<AppLocalePreference> loadPreferences({
    required String osLanguageCode,
  });

  /// Saves the given [preferences] to persistent storage.
  Future<void> savePreferences(AppLocalePreference preferences);
}
