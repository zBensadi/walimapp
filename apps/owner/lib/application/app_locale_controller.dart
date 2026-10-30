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
  /// If the repository throws an error on read, gracefully falls back to initial
  /// preferences without crashing.
  static Future<AppLocaleController> create({
    required AppPreferencesRepository repository,
    required String osLanguageCode,
  }) async {
    AppLocalePreference preference;
    try {
      preference = await repository.loadPreferences(
        osLanguageCode: osLanguageCode,
      );
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
  /// Guaranteed not to revert the active in-memory selection or crash if persistence fails.
  void setUiLanguage(SupportedAppLanguage newLanguage) {
    if (_currentPreference.uiLanguage == newLanguage) return;

    _currentPreference = _currentPreference.copyWithUiLanguage(newLanguage);
    notifyListeners();

    _persistCurrentPreferences();
  }

  /// Sets the default document language, updating in-memory state immediately and persisting asynchronously.
  ///
  /// Guaranteed not to revert the active in-memory selection or crash if persistence fails.
  void setDefaultDocumentLanguage(SupportedAppLanguage newLanguage) {
    if (_currentPreference.defaultDocumentLanguage == newLanguage) return;

    _currentPreference =
        _currentPreference.copyWithDefaultDocumentLanguage(newLanguage);
    notifyListeners();

    _persistCurrentPreferences();
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
