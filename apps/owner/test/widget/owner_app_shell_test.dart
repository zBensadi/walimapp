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

      // Verify full dashboard title in workspace (F-05)
      expect(find.text('Tableau de bord'), findsOneWidget);

      // Verify no RenderFlex errors were recorded
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all 5 destinations on compact 360x800 with 1.3x text scale in Arabic (RTL) with 0 overflows (F-03)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await localeController.setUiLanguage(SupportedAppLanguage.ar);

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

      // 1. Dashboard Destination: verify full title and zero overflows
      expect(find.text('لوحة التحكم'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Calendar Destination
      shellController.selectDestination(OwnerNavDestination.calendar);
      await tester.pumpAndSettle();
      expect(find.text('تقويم الحجوزات'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Venues Destination
      shellController.selectDestination(OwnerNavDestination.venues);
      await tester.pumpAndSettle();
      expect(find.text('الأماكن والقاعات'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4. Finance Destination
      shellController.selectDestination(OwnerNavDestination.finance);
      await tester.pumpAndSettle();
      expect(find.text('السجل المالي'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 5. Settings Destination (including 3-option language cards & diagnostics)
      shellController.selectDestination(OwnerNavDestination.settings);
      await tester.pumpAndSettle();
      expect(find.text('الإعدادات'), findsWidgets);
      expect(find.text('تفضيلات اللغة'), findsOneWidget);
      expect(find.text('العربية'), findsWidgets);
      expect(find.text('Français'), findsWidgets);
      expect(find.text('English'), findsWidgets);
      expect(find.text('تشخيصات التطبيق'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders all 5 destinations on compact 360x800 with 1.3x text scale in French (LTR) with 0 overflows (F-03)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await localeController.setUiLanguage(SupportedAppLanguage.fr);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 1. Dashboard
      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 2. Calendar
      shellController.selectDestination(OwnerNavDestination.calendar);
      await tester.pumpAndSettle();
      expect(find.text('Calendrier des réservations'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 3. Venues
      shellController.selectDestination(OwnerNavDestination.venues);
      await tester.pumpAndSettle();
      expect(find.text('Lieux et salles'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 4. Finance
      shellController.selectDestination(OwnerNavDestination.finance);
      await tester.pumpAndSettle();
      expect(find.text('Registre financier'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // 5. Settings
      shellController.selectDestination(OwnerNavDestination.settings);
      await tester.pumpAndSettle();
      expect(find.text('Paramètres'), findsWidgets);
      expect(find.text('Préférences linguistiques'), findsOneWidget);
      expect(find.text('Diagnostics de l\'application'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on typical smartphone 390x844 with 0 overflows', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Tableau de bord'), findsOneWidget);
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

    testWidgets('navigates using tester.tap on compact NavigationBar destinations (F-03)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(shellController.currentDestination, OwnerNavDestination.dashboard);

      // Tap Calendar destination (index 1) in bottom NavigationBar
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.calendar);
      expect(find.text('Calendrier des réservations'), findsWidgets);

      // Tap Venues destination (index 2) in bottom NavigationBar
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.venues);
      expect(find.text('Lieux et salles'), findsWidgets);

      // Tap Finance destination (index 3) in bottom NavigationBar
      await tester.tap(find.byType(NavigationDestination).at(3));
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.finance);
      expect(find.text('Registre financier'), findsWidgets);

      // Tap Settings destination (index 4) in bottom NavigationBar
      await tester.tap(find.byType(NavigationDestination).at(4));
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.settings);
      expect(find.text('Paramètres'), findsWidgets);

      // Tap Home/Dashboard destination (index 0) in bottom NavigationBar
      await tester.tap(find.byType(NavigationDestination).at(0));
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.dashboard);
      expect(find.text('Tableau de bord'), findsOneWidget);
    });

    testWidgets('tester.tap on Settings language chips switches UI language and document language interactively (F-03)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Tap Settings destination (index 4) in NavigationBar
      await tester.tap(find.byType(NavigationDestination).at(4));
      await tester.pumpAndSettle();
      expect(shellController.currentDestination, OwnerNavDestination.settings);

      // Initially French
      expect(localeController.uiLanguage, SupportedAppLanguage.fr);
      expect(localeController.defaultDocumentLanguage, SupportedAppLanguage.fr);

      // Tap the Arabic chip in the UI language selector (first instance of 'العربية')
      await tester.tap(find.text('العربية').first);
      await tester.pumpAndSettle();

      // UI language must be Arabic, RTL layout must be applied, document language remains French
      expect(localeController.uiLanguage, SupportedAppLanguage.ar);
      expect(localeController.defaultDocumentLanguage, SupportedAppLanguage.fr);
      expect(find.text('تفضيلات اللغة'), findsOneWidget);
      expect(find.text('تشخيصات التطبيق'), findsOneWidget);

      // Verify Directionality is now RTL
      final directionality = tester.widget<Directionality>(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byType(Directionality),
        ).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);

      // Tap the English chip in the Document language selector (last instance of 'English')
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();

      // UI language stays Arabic, Document language becomes English
      expect(localeController.uiLanguage, SupportedAppLanguage.ar);
      expect(localeController.defaultDocumentLanguage, SupportedAppLanguage.en);
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
      await localeController.setUiLanguage(SupportedAppLanguage.ar);
      await tester.pumpAndSettle();

      // Verify UI translated to Arabic and RTL layout applied
      expect(localeController.uiLanguage, SupportedAppLanguage.ar);
      expect(localeController.defaultDocumentLanguage, SupportedAppLanguage.fr); // unchanged!
      expect(find.text('لوحة التحكم'), findsNothing); // we are in settings
      expect(find.text('الإعدادات'), findsWidgets);

      // Switch Document language to English
      await localeController.setDefaultDocumentLanguage(SupportedAppLanguage.en);
      await tester.pumpAndSettle();

      expect(localeController.uiLanguage, SupportedAppLanguage.ar); // unchanged!
      expect(localeController.defaultDocumentLanguage, SupportedAppLanguage.en);
    });
  });
}
