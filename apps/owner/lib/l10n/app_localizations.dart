import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// Title of the application
  ///
  /// In en, this message translates to:
  /// **'WalimApp Owner'**
  String get appTitle;

  /// No description provided for @dashboardNav.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get dashboardNav;

  /// No description provided for @calendarNav.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarNav;

  /// No description provided for @venuesNav.
  ///
  /// In en, this message translates to:
  /// **'Venues'**
  String get venuesNav;

  /// No description provided for @financeNav.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeNav;

  /// No description provided for @settingsNav.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsNav;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar & Bookings'**
  String get calendarTitle;

  /// No description provided for @venuesTitle.
  ///
  /// In en, this message translates to:
  /// **'Venues & Halls'**
  String get venuesTitle;

  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Ledger'**
  String get financeTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to WalimApp'**
  String get dashboardWelcome;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Algeria-first venue management foundation'**
  String get dashboardSubtitle;

  /// No description provided for @environmentStatus.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environmentStatus;

  /// No description provided for @uiLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Interface Language'**
  String get uiLanguageLabel;

  /// No description provided for @documentLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Document Language'**
  String get documentLanguageLabel;

  /// No description provided for @sampleAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Sample Amount'**
  String get sampleAmountLabel;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get goToSettings;

  /// No description provided for @viewCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get viewCalendar;

  /// No description provided for @placeholderUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon in Next Phase'**
  String get placeholderUpcoming;

  /// No description provided for @calendarPlaceholderDesc.
  ///
  /// In en, this message translates to:
  /// **'Hall availability, scheduling, and reservation management will be available here.'**
  String get calendarPlaceholderDesc;

  /// No description provided for @venuesPlaceholderDesc.
  ///
  /// In en, this message translates to:
  /// **'Venue profiles, hall configuration, pricing tiers, and capacity settings will be configured here.'**
  String get venuesPlaceholderDesc;

  /// No description provided for @financePlaceholderDesc.
  ///
  /// In en, this message translates to:
  /// **'Immutable whole-DZD payment ledger, installments, receipts, and revenue summaries will appear here.'**
  String get financePlaceholderDesc;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language Preferences'**
  String get settingsLanguageSection;

  /// No description provided for @settingsUiLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used for menus, buttons, and views.'**
  String get settingsUiLanguageDesc;

  /// No description provided for @settingsDocLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the default language for future contracts and receipts.'**
  String get settingsDocLanguageDesc;

  /// No description provided for @settingsDiagnosticsSection.
  ///
  /// In en, this message translates to:
  /// **'Application Diagnostics'**
  String get settingsDiagnosticsSection;

  /// No description provided for @platformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platformLabel;

  /// No description provided for @buildModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Build Mode'**
  String get buildModeLabel;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersionLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
