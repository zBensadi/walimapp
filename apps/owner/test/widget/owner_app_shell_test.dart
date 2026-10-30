import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner/application/app_locale_controller.dart';
import 'package:owner/application/owner_shell_controller.dart';
import 'package:owner/data/preferences/in_memory_app_preferences_repository.dart';
import 'package:owner/domain/locale/app_locale_preference.dart';
import 'package:owner/domain/locale/supported_app_language.dart';
import 'package:owner/domain/navigation/owner_nav_destination.dart';
import 'package:owner/presentation/app.dart';

void main() {
  late InMemoryAppPreferencesRepository repo;
  late AppLocaleController localeController;
  late OwnerShellController shellController;

  setUp(() {
    repo = InMemoryAppPreferencesRepository(
      initialPreferences: const AppLocalePreference(
        uiLanguage: SupportedAppLanguage.fr,
        defaultDocumentLanguage: SupportedAppLanguage.fr,
      ),
    );
    localeController = AppLocaleController(
      repository: repo,
      initialPreference: const AppLocalePreference(
        uiLanguage: SupportedAppLanguage.fr,
        defaultDocumentLanguage: SupportedAppLanguage.fr,
      ),
    );
    shellController = OwnerShellController();
  });

  Widget buildTestApp() {
    return WalimAppOwnerApp(
      localeController: localeController,
      shellController: shellController,
    );
  }

  group('Owner App Shell Responsive & Overflow Tests', () {
    testWidgets('renders on compact 360x800 with 1.0x text scale with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify bottom NavigationBar is present
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Verify no RenderFlex errors were recorded
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on compact 360x800 with 1.3x text scale in Arabic (RTL) with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      localeController.setUiLanguage(SupportedAppLanguage.ar);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Verify RTL directionality
      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('renders on compact 360x800 with 1.3x text scale in French (LTR) with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      localeController.setUiLanguage(SupportedAppLanguage.fr);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on typical smartphone 390x844 with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on medium tablet 768x1024 with NavigationRail with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on desktop expanded 1280x800 with extended NavigationRail with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.extended, isTrue);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Owner App Navigation & State Preservation Tests', () {
    testWidgets('navigates through all 5 destinations without error', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Starts on Dashboard
      expect(shellController.currentDestination, OwnerNavDestination.dashboard);

      // Select Calendar
      shellController.selectDestination(OwnerNavDestination.calendar);
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.calendar);
      expect(find.text('Calendrier des réservations'), findsWidgets);

      // Select Venues
      shellController.selectDestination(OwnerNavDestination.venues);
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.venues);
      expect(find.text('Lieux et salles'), findsWidgets);

      // Select Finance
      shellController.selectDestination(OwnerNavDestination.finance);
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.finance);
      expect(find.text('Registre financier'), findsWidgets);

      // Select Settings
      shellController.selectDestination(OwnerNavDestination.settings);
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.settings);
      expect(find.text('Paramètres'), findsWidgets);

      expect(tester.takeException(), isNull);
    });

    testWidgets('preserves active destination across viewport resizing', (tester) async {
      // Start in compact width
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Navigate to Venues
      shellController.selectDestination(OwnerNavDestination.venues);
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.venues);

      // Resize window to desktop
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pumpAndSettle();

      // Verify destination is preserved
      expect(shellController.currentDestination, OwnerNavDestination.venues);
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('independent language switching updates UI immediately without altering document language', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Go to Settings
      shellController.selectDestination(OwnerNavDestination.settings);
      await tester.pumpAndSettle();

      // Switch UI language to Arabic
      localeController.setUiLanguage(SupportedAppLanguage.ar);
      await tester.pumpAndSettle();

      // Verify UI translated to Arabic and RTL layout applied
      expect(localeController.uiLanguage, SupportedAppLanguage.ar);
      expect(localeController.defaultDocumentLanguage, SupportedAppLanguage.fr); // unchanged!
      expect(find.text('لوحة التحكم'), findsNothing); // we are in settings
      expect(find.text('الإعدادات'), findsWidgets);

      // Switch Document language to English
      localeController.setDefaultDocumentLanguage(SupportedAppLanguage.en);
      await tester.pumpAndSettle();

      expect(localeController.uiLanguage, SupportedAppLanguage.ar); // unchanged!
      expect(localeController.defaultDocumentLanguage, SupportedAppLanguage.en);
    });
  });
}
