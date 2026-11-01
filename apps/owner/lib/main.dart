import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'application/app_locale_controller.dart';
import 'data/preferences/file_app_preferences_repository.dart';
import 'data/preferences/in_memory_app_preferences_repository.dart';
import 'domain/repositories/app_preferences_repository.dart';
import 'presentation/app.dart';

/// Production entrypoint for the WalimApp Owner Application.
///
/// Initializes localization preferences with resilient storage failure handling
/// and launches the responsive adaptive application shell.
///
/// Note: The standalone SQLite encryption PoT runner remains accessible via
/// `lib/main_pot.dart` (run with `flutter run -t lib/main_pot.dart`).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final osLanguageCode = PlatformDispatcher.instance.locale.languageCode;

  AppPreferencesRepository repository;
  try {
    repository = FileAppPreferencesRepository();
  } catch (e, stack) {
    debugPrint('Warning: Storage unavailable at startup, using in-memory preferences: $e\n$stack');
    repository = InMemoryAppPreferencesRepository();
  }

  final localeController = await AppLocaleController.create(
    repository: repository,
    osLanguageCode: osLanguageCode,
    loadTimeout: const Duration(seconds: 2),
  );

  runApp(
    WalimAppOwnerApp(
      localeController: localeController,
    ),
  );
}
