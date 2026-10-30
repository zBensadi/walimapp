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

    test('serialization conforms to contract schema', () {
      const pref = AppLocalePreference(
        uiLanguage: SupportedAppLanguage.ar,
        defaultDocumentLanguage: SupportedAppLanguage.fr,
      );

      final json = pref.toJson();
      expect(json['schema_version'], 1);
      expect(json['language_pref'], 'ar');
      expect(json['default_doc_lang'], 'fr');
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

      controller.setUiLanguage(SupportedAppLanguage.ar);
      expect(controller.uiLanguage, SupportedAppLanguage.ar);
      expect(controller.isRtl, isTrue);
      expect(notificationCount, 1);

      controller.setDefaultDocumentLanguage(SupportedAppLanguage.en);
      expect(controller.defaultDocumentLanguage, SupportedAppLanguage.en);
      expect(notificationCount, 2);

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
      controller.setUiLanguage(SupportedAppLanguage.ar);

      // In-memory state MUST remain updated (not reverted) and not crash
      expect(controller.uiLanguage, SupportedAppLanguage.ar);
      expect(controller.isRtl, isTrue);

      controller.setDefaultDocumentLanguage(SupportedAppLanguage.fr);
      expect(controller.defaultDocumentLanguage, SupportedAppLanguage.fr);
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
  });
}
