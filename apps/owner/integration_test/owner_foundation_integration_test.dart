import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:owner/application/app_locale_controller.dart';
import 'package:owner/application/owner_shell_controller.dart';
import 'package:owner/core/formatting/western_numeral_formatter.dart';
import 'package:owner/data/preferences/file_app_preferences_repository.dart';
import 'package:owner/domain/locale/supported_app_language.dart';
import 'package:owner/domain/navigation/owner_nav_destination.dart';
import 'package:owner/presentation/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'WalimApp Owner Foundation End-to-End Runtime Verification on Host Device',
    (WidgetTester tester) async {
      final repository = FileAppPreferencesRepository();
      final shellController = OwnerShellController();

      // Step 1: Initialize controller with real disk-backed storage
      final localeController = await AppLocaleController.create(
        repository: repository,
        osLanguageCode: 'fr',
      );

      await tester.pumpWidget(
        WalimAppOwnerApp(
          localeController: localeController,
          shellController: shellController,
        ),
      );
      await tester.pumpAndSettle();

      // Step 2: Verify initial launch on Dashboard
      expect(shellController.currentDestination, OwnerNavDestination.dashboard);

      // Step 3: Switch UI language to Arabic (ar RTL)
      await localeController.setUiLanguage(SupportedAppLanguage.ar);
      await tester.pumpAndSettle();

      expect(localeController.uiLanguage, SupportedAppLanguage.ar);
      expect(localeController.isRtl, isTrue);

      // Verify Western numerals in Arabic UI
      final sampleDzd = WesternNumeralFormatter.formatCurrencyDzd(
        150000,
        language: SupportedAppLanguage.ar,
      );
      expect(sampleDzd, '150 000 د.ج');
      expect(sampleDzd.contains(RegExp(r'[٠-٩۰-۹]')), isFalse);

      // Step 4: Navigate to Settings and set Document Language to English
      shellController.selectDestination(OwnerNavDestination.settings);
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.settings);

      await localeController.setDefaultDocumentLanguage(SupportedAppLanguage.en);
      await tester.pumpAndSettle();

      expect(localeController.uiLanguage, SupportedAppLanguage.ar);
      expect(localeController.defaultDocumentLanguage, SupportedAppLanguage.en);

      // Step 5: Verify independent persistence to disk
      final reloadedFromDisk = await repository.loadPreferences(osLanguageCode: 'fr');
      expect(reloadedFromDisk.uiLanguage, SupportedAppLanguage.ar);
      expect(reloadedFromDisk.defaultDocumentLanguage, SupportedAppLanguage.en);

      // Step 6: Navigate through all 5 destinations to verify zero layout errors
      for (final destination in OwnerNavDestination.values) {
        shellController.selectDestination(destination);
        await tester.pumpAndSettle();
        expect(shellController.currentDestination, destination);
      }

      // ignore: avoid_print
      print(
        'FOUNDATION_RUNTIME_REPORT: { '
        '"status": "PASS", '
        '"uiLanguage": "${localeController.uiLanguage.languageCode}", '
        '"defaultDocumentLanguage": "${localeController.defaultDocumentLanguage.languageCode}", '
        '"isRtl": ${localeController.isRtl}, '
        '"persistedToDisk": true, '
        '"destinationsTested": 5 '
        '}',
      );
    },
  );
}
