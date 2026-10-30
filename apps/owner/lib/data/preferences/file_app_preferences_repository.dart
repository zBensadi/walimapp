import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/locale/app_locale_preference.dart';
import '../../domain/repositories/app_preferences_repository.dart';

/// File-backed persistent implementation of [AppPreferencesRepository].
///
/// Stores `owner_preferences.json` atomically in the application support directory.
/// Gracefully handles missing directories, corrupted JSON, and read/write I/O failures
/// by falling back to deterministic defaults without crashing the application.
class FileAppPreferencesRepository implements AppPreferencesRepository {
  FileAppPreferencesRepository({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directoryProvider;
  static const String preferencesFileName = 'owner_preferences.json';

  Future<File> _getPreferencesFile() async {
    final dir = await _directoryProvider();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, preferencesFileName));
  }

  @override
  Future<AppLocalePreference> loadPreferences({
    required String osLanguageCode,
  }) async {
    try {
      final file = await _getPreferencesFile();
      if (!await file.exists()) {
        return AppLocalePreference.initial(osLanguageCode: osLanguageCode);
      }

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        return AppLocalePreference.initial(osLanguageCode: osLanguageCode);
      }

      final dynamic decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return AppLocalePreference.initial(osLanguageCode: osLanguageCode);
      }

      return AppLocalePreference.fromJson(
        decoded,
        osLanguageCode: osLanguageCode,
      );
    } catch (e, stack) {
      debugPrint('Warning: Failed to load preferences from disk, using fallback: $e\n$stack');
      return AppLocalePreference.initial(osLanguageCode: osLanguageCode);
    }
  }

  @override
  Future<void> savePreferences(AppLocalePreference preferences) async {
    try {
      final dir = await _directoryProvider();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final targetFile = File(p.join(dir.path, preferencesFileName));
      final tmpFile = File(p.join(dir.path, '$preferencesFileName.tmp'));

      final jsonString = jsonEncode(preferences.toJson());
      await tmpFile.writeAsString(jsonString, flush: true);

      // Atomic rename
      try {
        await tmpFile.rename(targetFile.path);
      } catch (_) {
        // Fallback for filesystems where atomic rename across boundaries fails
        await targetFile.writeAsString(jsonString, flush: true);
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
      }
    } catch (e, stack) {
      debugPrint('Warning: Failed to save preferences to disk: $e\n$stack');
      // Graceful error handling: callers are not crashed when storage writes fail
    }
  }
}
