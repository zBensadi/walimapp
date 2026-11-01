import 'package:flutter/foundation.dart';

import '../domain/locale/app_locale_preference.dart';
import '../domain/locale/supported_app_language.dart';
import '../domain/repositories/app_preferences_repository.dart';

/// State management controller for owner application locale preferences.
///
/// Implements immediate in-memory state updates, non-reverting runtime transitions,
/// and asynchronous local persistence with resilient error handling per FR-009.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController({
    required this.repository,
    required AppLocalePreference initialPreference,
  }) : _currentPreference = initialPreference;

  final AppPreferencesRepository repository;
  AppLocalePreference _currentPreference;

  /// Creates and initializes the controller, loading saved preferences from storage.
  ///
  /// If the repository throws an error or exceeds [loadTimeout] on read,
  /// gracefully falls back to initial preferences without crashing or blocking startup.
  static Future<AppLocaleController> create({
    required AppPreferencesRepository repository,
    required String osLanguageCode,
    Duration? loadTimeout,
  }) async {
    AppLocalePreference preference;
    try {
      final loadFuture = repository.loadPreferences(
        osLanguageCode: osLanguageCode,
      );
      preference = loadTimeout != null
          ? await loadFuture.timeout(loadTimeout)
          : await loadFuture;
    } catch (e, stack) {
      debugPrint('Warning: AppLocaleController fallback during initialization: $e\n$stack');
      preference = AppLocalePreference.initial(osLanguageCode: osLanguageCode);
    }

    return AppLocaleController(
      repository: repository,
      initialPreference: preference,
    );
  }

  /// The active locale preferences.
  AppLocalePreference get currentPreference => _currentPreference;

  /// The active user interface language (controls UI labels and layout direction).
  SupportedAppLanguage get uiLanguage => _currentPreference.uiLanguage;

  /// The default language for generated documents (contracts and receipts).
  SupportedAppLanguage get defaultDocumentLanguage =>
      _currentPreference.defaultDocumentLanguage;

  /// Whether the active UI language requires Right-to-Left layout.
  bool get isRtl => _currentPreference.uiLanguage.isRtl;

  /// Sets the active UI language, updating in-memory state immediately and persisting asynchronously.
  ///
  /// Returns a [Future] completing when local persistence finishes.
  /// Guaranteed not to revert the active in-memory selection or crash if persistence fails.
  Future<void> setUiLanguage(SupportedAppLanguage newLanguage) {
    final changed = _currentPreference.uiLanguage != newLanguage;
    if (changed) {
      _currentPreference = _currentPreference.copyWithUiLanguage(newLanguage);
      notifyListeners();
    }

    return _persistCurrentPreferences();
  }

  /// Sets the default document language, updating in-memory state immediately and persisting asynchronously.
  ///
  /// Returns a [Future] completing when local persistence finishes.
  /// Guaranteed not to revert the active in-memory selection or crash if persistence fails.
  Future<void> setDefaultDocumentLanguage(SupportedAppLanguage newLanguage) {
    final changed = _currentPreference.defaultDocumentLanguage != newLanguage;
    if (changed) {
      _currentPreference =
          _currentPreference.copyWithDefaultDocumentLanguage(newLanguage);
      notifyListeners();
    }

    return _persistCurrentPreferences();
  }

  Future<void> _persistCurrentPreferences() async {
    try {
      await repository.savePreferences(_currentPreference);
    } catch (e, stack) {
      debugPrint('Warning: Asynchronous preference persistence failed: $e\n$stack');
      // In-memory state is preserved; we do NOT crash or revert the selection
    }
  }
}
