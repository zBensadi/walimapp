import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:owner/application/app_locale_controller.dart';
import 'package:owner/data/preferences/file_app_preferences_repository.dart';
import 'package:owner/data/preferences/in_memory_app_preferences_repository.dart';
import 'package:owner/domain/locale/app_locale_preference.dart';
import 'package:owner/domain/locale/supported_app_language.dart';

void main() {
  group('SupportedAppLanguage', () {
    test('normalizes locale tags and subtags', () {
      expect(SupportedAppLanguage.tryFromCode('ar'), SupportedAppLanguage.ar);
      expect(SupportedAppLanguage.tryFromCode('ar-DZ'), SupportedAppLanguage.ar);
      expect(SupportedAppLanguage.tryFromCode('ar_DZ'), SupportedAppLanguage.ar);
      expect(SupportedAppLanguage.tryFromCode('fr'), SupportedAppLanguage.fr);
      expect(SupportedAppLanguage.tryFromCode('fr-FR'), SupportedAppLanguage.fr);
      expect(SupportedAppLanguage.tryFromCode('en'), SupportedAppLanguage.en);
      expect(SupportedAppLanguage.tryFromCode('en-US'), SupportedAppLanguage.en);

      expect(SupportedAppLanguage.tryFromCode('de'), isNull);
      expect(SupportedAppLanguage.tryFromCode(''), isNull);
      expect(SupportedAppLanguage.tryFromCode(null), isNull);
    });

    test('directionality indicator is pure Dart and accurate', () {
      expect(SupportedAppLanguage.ar.isRtl, isTrue);
      expect(SupportedAppLanguage.fr.isRtl, isFalse);
      expect(SupportedAppLanguage.en.isRtl, isFalse);
    });

    test('deterministic initial resolution priority: stored -> OS -> fr fallback', () {
      // 1. Stored valid
      expect(
        SupportedAppLanguage.resolveInitial(storedCode: 'ar', osLanguageCode: 'en'),
        SupportedAppLanguage.ar,
      );

      // 2. Stored invalid, OS valid
      expect(
        SupportedAppLanguage.resolveInitial(storedCode: 'de', osLanguageCode: 'ar'),
        SupportedAppLanguage.ar,
      );

      // 3. Stored missing, OS valid
      expect(
        SupportedAppLanguage.resolveInitial(storedCode: null, osLanguageCode: 'en'),
        SupportedAppLanguage.en,
      );

      // 4. Stored invalid, OS unsupported -> deterministic 'fr' default
      expect(
        SupportedAppLanguage.resolveInitial(storedCode: 'xyz', osLanguageCode: 'de'),
        SupportedAppLanguage.fr,
      );

      // 5. Stored missing, OS missing -> deterministic 'fr' default
      expect(
        SupportedAppLanguage.resolveInitial(storedCode: null, osLanguageCode: null),
        SupportedAppLanguage.fr,
      );
    });
  });

  group('AppLocalePreference', () {
    test('independent copyWith methods preserve other field', () {
      const initial = AppLocalePreference(
        uiLanguage: SupportedAppLanguage.ar,
        defaultDocumentLanguage: SupportedAppLanguage.fr,
      );

      final updatedUi = initial.copyWithUiLanguage(SupportedAppLanguage.en);
      expect(updatedUi.uiLanguage, SupportedAppLanguage.en);
      expect(updatedUi.defaultDocumentLanguage, SupportedAppLanguage.fr);

      final updatedDoc = initial.copyWithDefaultDocumentLanguage(SupportedAppLanguage.ar);
      expect(updatedDoc.uiLanguage, SupportedAppLanguage.ar);
      expect(updatedDoc.defaultDocumentLanguage, SupportedAppLanguage.ar);
    });

    test('serialization conforms to contract schema with no additional properties', () {
      const pref = AppLocalePreference(
        uiLanguage: SupportedAppLanguage.ar,
        defaultDocumentLanguage: SupportedAppLanguage.fr,
      );

      final json = pref.toJson();
      // Required properties per owner-preferences.schema.json
      expect(json.containsKey('schema_version'), isTrue);
      expect(json.containsKey('language_pref'), isTrue);
      expect(json.containsKey('default_doc_lang'), isTrue);

      // Value constraints
      expect(json['schema_version'], 1);
      expect(['ar', 'fr', 'en'].contains(json['language_pref']), isTrue);
      expect(['ar', 'fr', 'en'].contains(json['default_doc_lang']), isTrue);

      // Strict additionalProperties: false check
      const allowedKeys = {'schema_version', 'language_pref', 'default_doc_lang'};
      expect(json.keys.toSet().difference(allowedKeys), isEmpty);
    });

    test('independent per-field corruption recovery in fromJson', () {
      // UI valid ('ar'), doc corrupted ('invalid')
      final json1 = {
        'schema_version': 1,
        'language_pref': 'ar',
        'default_doc_lang': 'corrupted_code',
      };
      final pref1 = AppLocalePreference.fromJson(json1, osLanguageCode: 'en');
      expect(pref1.uiLanguage, SupportedAppLanguage.ar);
      expect(pref1.defaultDocumentLanguage, SupportedAppLanguage.en); // fell back to OS

      // UI corrupted ('unknown'), doc valid ('fr')
      final json2 = {
        'schema_version': 1,
        'language_pref': 'unknown',
        'default_doc_lang': 'fr',
      };
      final pref2 = AppLocalePreference.fromJson(json2, osLanguageCode: 'de');
      expect(pref2.uiLanguage, SupportedAppLanguage.fr); // fell back to deterministic 'fr'
      expect(pref2.defaultDocumentLanguage, SupportedAppLanguage.fr);
    });
  });

  group('FileAppPreferencesRepository', () {
    late Directory tempDir;
    late FileAppPreferencesRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('walimapp_pref_test_');
      repository = FileAppPreferencesRepository(
        directoryProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saves and reloads preferences atomically', () async {
      const pref = AppLocalePreference(
        uiLanguage: SupportedAppLanguage.ar,
        defaultDocumentLanguage: SupportedAppLanguage.fr,
      );

      await repository.savePreferences(pref);
      final loaded = await repository.loadPreferences(osLanguageCode: 'en');

      expect(loaded.uiLanguage, SupportedAppLanguage.ar);
      expect(loaded.defaultDocumentLanguage, SupportedAppLanguage.fr);
    });

    test('falls back gracefully on empty or corrupted file', () async {
      final file = File('${tempDir.path}/${FileAppPreferencesRepository.preferencesFileName}');
      await file.writeAsString('{ invalid_json: ');

      final loaded = await repository.loadPreferences(osLanguageCode: 'en');
      expect(loaded.uiLanguage, SupportedAppLanguage.en);
      expect(loaded.defaultDocumentLanguage, SupportedAppLanguage.en);
    });

    test('falls back gracefully when directory provider throws read exception', () async {
      final failingRepo = FileAppPreferencesRepository(
        directoryProvider: () async => throw const FileSystemException('Storage access denied'),
      );

      final loaded = await failingRepo.loadPreferences(osLanguageCode: 'ar');
      expect(loaded.uiLanguage, SupportedAppLanguage.ar);
      expect(loaded.defaultDocumentLanguage, SupportedAppLanguage.ar);
    });

    test('does not throw exception when save fails due to file system error', () async {
      final failingRepo = FileAppPreferencesRepository(
        directoryProvider: () async => throw const FileSystemException('Disk write failure'),
      );

      const pref = AppLocalePreference(
        uiLanguage: SupportedAppLanguage.ar,
        defaultDocumentLanguage: SupportedAppLanguage.en,
      );

      // Must complete without throwing unhandled exception
      await expectLater(failingRepo.savePreferences(pref), completes);
    });

    test('handles rapid consecutive writes concurrently and preserves latest state (F-02)', () async {
      // Dispatch multiple saves concurrently without awaiting individually
      final futures = <Future<void>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(
          repository.savePreferences(
            AppLocalePreference(
              uiLanguage: i.isEven ? SupportedAppLanguage.ar : SupportedAppLanguage.fr,
              defaultDocumentLanguage: SupportedAppLanguage.en,
            ),
          ),
        );
      }
      // Final write is unambiguously English UI and Arabic Doc
      futures.add(
        repository.savePreferences(
          const AppLocalePreference(
            uiLanguage: SupportedAppLanguage.en,
            defaultDocumentLanguage: SupportedAppLanguage.ar,
          ),
        ),
      );

      await Future.wait(futures);

      final loaded = await repository.loadPreferences(osLanguageCode: 'fr');
      expect(loaded.uiLanguage, SupportedAppLanguage.en);
      expect(loaded.defaultDocumentLanguage, SupportedAppLanguage.ar);
    });
  });

  group('AppLocaleController', () {
    test('updates in-memory state immediately and notifies listeners', () async {
      final repo = InMemoryAppPreferencesRepository(
        initialPreferences: const AppLocalePreference(
          uiLanguage: SupportedAppLanguage.fr,
          defaultDocumentLanguage: SupportedAppLanguage.fr,
        ),
      );

      final controller = await AppLocaleController.create(
        repository: repo,
        osLanguageCode: 'fr',
      );

      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      final future1 = controller.setUiLanguage(SupportedAppLanguage.ar);
      expect(controller.uiLanguage, SupportedAppLanguage.ar);
      expect(controller.isRtl, isTrue);
      expect(notificationCount, 1);
      await future1;

      final future2 = controller.setDefaultDocumentLanguage(SupportedAppLanguage.en);
      expect(controller.defaultDocumentLanguage, SupportedAppLanguage.en);
      expect(notificationCount, 2);
      await future2;

      // Verify independence
      expect(controller.uiLanguage, SupportedAppLanguage.ar);
      expect(controller.defaultDocumentLanguage, SupportedAppLanguage.en);
    });

    test('preserves active in-memory state and does not revert on write failure', () async {
      final repo = InMemoryAppPreferencesRepository(
        initialPreferences: const AppLocalePreference(
          uiLanguage: SupportedAppLanguage.en,
          defaultDocumentLanguage: SupportedAppLanguage.en,
        ),
        shouldFailOnWrite: true, // Simulate persistent write error
      );

      final controller = await AppLocaleController.create(
        repository: repo,
        osLanguageCode: 'en',
      );

      // Changing UI language while save fails
      final future1 = controller.setUiLanguage(SupportedAppLanguage.ar);

      // In-memory state MUST remain updated (not reverted) and not crash
      expect(controller.uiLanguage, SupportedAppLanguage.ar);
      expect(controller.isRtl, isTrue);
      await future1;

      final future2 = controller.setDefaultDocumentLanguage(SupportedAppLanguage.fr);
      expect(controller.defaultDocumentLanguage, SupportedAppLanguage.fr);
      await future2;
    });

    test('gracefully handles repository read errors on initialization', () async {
      final repo = InMemoryAppPreferencesRepository(shouldFailOnRead: true);

      final controller = await AppLocaleController.create(
        repository: repo,
        osLanguageCode: 'ar',
      );

      expect(controller.uiLanguage, SupportedAppLanguage.ar);
      expect(controller.defaultDocumentLanguage, SupportedAppLanguage.ar);
    });

    test('falls back deterministically when repository read exceeds loadTimeout', () async {
      final stallingRepo = FileAppPreferencesRepository(
        directoryProvider: () => Completer<Directory>().future,
      );

      final controller = await AppLocaleController.create(
        repository: stallingRepo,
        osLanguageCode: 'ar',
        loadTimeout: const Duration(milliseconds: 50),
      );

      expect(controller.uiLanguage, SupportedAppLanguage.ar);
      expect(controller.defaultDocumentLanguage, SupportedAppLanguage.ar);
    });

    test('repairs corrupted on-disk preferences when active in-memory language is selected (F-04)', () async {
      final tempDir = await Directory.systemTemp.createTemp('walimapp_repair_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final fileRepo = FileAppPreferencesRepository(
        directoryProvider: () async => tempDir,
      );

      // Seed file with corrupted language code 'de'
      final file = File('${tempDir.path}/${FileAppPreferencesRepository.preferencesFileName}');
      await file.writeAsString(
        '{"schema_version": 1, "language_pref": "de", "default_doc_lang": "fr"}',
      );

      // Load with OS locale 'fr' -> in-memory resolves uiLanguage to 'fr'
      final controller = await AppLocaleController.create(
        repository: fileRepo,
        osLanguageCode: 'fr',
      );

      expect(controller.uiLanguage, SupportedAppLanguage.fr);

      var notified = false;
      controller.addListener(() => notified = true);

      // User selects 'Français' (same language as fallback) in Settings
      await controller.setUiLanguage(SupportedAppLanguage.fr);

      // No unnecessary notification, but disk is repaired
      expect(notified, isFalse);

      final reloaded = await fileRepo.loadPreferences(osLanguageCode: 'en');
      expect(reloaded.uiLanguage, SupportedAppLanguage.fr);
      expect(reloaded.defaultDocumentLanguage, SupportedAppLanguage.fr);

      // JSON inspection to confirm corrupted 'de' was overwritten with 'fr'
      final rawContent = await file.readAsString();
      final decoded = jsonDecode(rawContent) as Map<String, dynamic>;
      expect(decoded['language_pref'], 'fr');
      expect(decoded['default_doc_lang'], 'fr');
    });

    test('rapid consecutive updates to both preferences persist latest values without race (F-02)', () async {
      final tempDir = await Directory.systemTemp.createTemp('walimapp_rapid_test_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final fileRepo = FileAppPreferencesRepository(
        directoryProvider: () async => tempDir,
      );

      final controller = await AppLocaleController.create(
        repository: fileRepo,
        osLanguageCode: 'fr',
      );

      // Fire both updates consecutively without artificial delay
      final future1 = controller.setUiLanguage(SupportedAppLanguage.ar);
      final future2 = controller.setDefaultDocumentLanguage(SupportedAppLanguage.en);

      // Immediate in-memory state is updated
      expect(controller.uiLanguage, SupportedAppLanguage.ar);
      expect(controller.defaultDocumentLanguage, SupportedAppLanguage.en);

      // Both persistence operations complete successfully
      await Future.wait([future1, future2]);

      final reloaded = await fileRepo.loadPreferences(osLanguageCode: 'fr');
      expect(reloaded.uiLanguage, SupportedAppLanguage.ar);
      expect(reloaded.defaultDocumentLanguage, SupportedAppLanguage.en);
    });
  });
}
