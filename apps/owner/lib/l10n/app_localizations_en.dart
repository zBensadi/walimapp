// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WalimApp Owner';

  @override
  String get dashboardNav => 'Home';

  @override
  String get calendarNav => 'Calendar';

  @override
  String get venuesNav => 'Venues';

  @override
  String get financeNav => 'Finance';

  @override
  String get settingsNav => 'Settings';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get calendarTitle => 'Calendar & Bookings';

  @override
  String get venuesTitle => 'Venues & Halls';

  @override
  String get financeTitle => 'Financial Ledger';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get dashboardWelcome => 'Welcome to WalimApp';

  @override
  String get dashboardSubtitle => 'Algeria-first venue management foundation';

  @override
  String get environmentStatus => 'Environment';

  @override
  String get uiLanguageLabel => 'Interface Language';

  @override
  String get documentLanguageLabel => 'Default Document Language';

  @override
  String get sampleAmountLabel => 'Sample Amount';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get goToSettings => 'Settings';

  @override
  String get viewCalendar => 'Calendar';

  @override
  String get placeholderUpcoming => 'Coming Soon in Next Phase';

  @override
  String get calendarPlaceholderDesc =>
      'Hall availability, scheduling, and reservation management will be available here.';

  @override
  String get venuesPlaceholderDesc =>
      'Venue profiles, hall configuration, pricing tiers, and capacity settings will be configured here.';

  @override
  String get financePlaceholderDesc =>
      'Immutable whole-DZD payment ledger, installments, receipts, and revenue summaries will appear here.';

  @override
  String get settingsLanguageSection => 'Language Preferences';

  @override
  String get settingsUiLanguageDesc =>
      'Choose the language used for menus, buttons, and views.';

  @override
  String get settingsDocLanguageDesc =>
      'Choose the default language for future contracts and receipts.';

  @override
  String get settingsDiagnosticsSection => 'Application Diagnostics';

  @override
  String get platformLabel => 'Platform';

  @override
  String get buildModeLabel => 'Build Mode';

  @override
  String get appVersionLabel => 'Version';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';
}
