import '../../domain/locale/app_locale_preference.dart';
import '../../domain/repositories/app_preferences_repository.dart';

/// In-memory implementation of [AppPreferencesRepository] for unit/widget tests.
///
/// Supports simulating read/write failures to test system resilience.
class InMemoryAppPreferencesRepository implements AppPreferencesRepository {
  InMemoryAppPreferencesRepository({
    AppLocalePreference? initialPreferences,
    this.shouldFailOnRead = false,
    this.shouldFailOnWrite = false,
  }) : _preferences = initialPreferences;

  AppLocalePreference? _preferences;
  bool shouldFailOnRead;
  bool shouldFailOnWrite;

  @override
  Future<AppLocalePreference> loadPreferences({
    required String osLanguageCode,
  }) async {
    if (shouldFailOnRead) {
      throw StateError('Simulated in-memory preference storage read failure');
    }
    return _preferences ??
        AppLocalePreference.initial(osLanguageCode: osLanguageCode);
  }

  @override
  Future<void> savePreferences(AppLocalePreference preferences) async {
    if (shouldFailOnWrite) {
      throw StateError('Simulated in-memory preference storage write failure');
    }
    _preferences = preferences;
  }

  /// Direct inspection helper for tests.
  AppLocalePreference? get currentStoredPreferences => _preferences;
}
