// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'WalimApp Propriétaire';

  @override
  String get dashboardNav => 'Accueil';

  @override
  String get calendarNav => 'Calendrier';

  @override
  String get venuesNav => 'Salles';

  @override
  String get financeNav => 'Finances';

  @override
  String get settingsNav => 'Paramètres';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get calendarTitle => 'Calendrier des réservations';

  @override
  String get venuesTitle => 'Lieux et salles';

  @override
  String get financeTitle => 'Registre financier';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get dashboardWelcome => 'Bienvenue sur WalimApp';

  @override
  String get dashboardSubtitle =>
      'Socle de gestion de salles de fêtes en Algérie';

  @override
  String get environmentStatus => 'Environnement';

  @override
  String get uiLanguageLabel => 'Langue de l\'interface';

  @override
  String get documentLanguageLabel => 'Langue par défaut des documents';

  @override
  String get sampleAmountLabel => 'Exemple de montant';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get goToSettings => 'Paramètres';

  @override
  String get viewCalendar => 'Calendrier';

  @override
  String get placeholderUpcoming => 'Disponible dans la prochaine phase';

  @override
  String get calendarPlaceholderDesc =>
      'La disponibilité des salles, la planification et la gestion des réservations seront disponibles ici.';

  @override
  String get venuesPlaceholderDesc =>
      'La configuration des salles, les tarifs et la gestion des capacités seront configurés ici.';

  @override
  String get financePlaceholderDesc =>
      'Le registre des paiements en DZD, les acomptes, les reçus et les bilans apparaîtront ici.';

  @override
  String get settingsLanguageSection => 'Préférences linguistiques';

  @override
  String get settingsUiLanguageDesc =>
      'Choisissez la langue utilisée pour les menus, boutons et affichages.';

  @override
  String get settingsDocLanguageDesc =>
      'Choisissez la langue par défaut pour les futurs contrats et reçus.';

  @override
  String get settingsDiagnosticsSection => 'Diagnostics de l\'application';

  @override
  String get platformLabel => 'Plateforme';

  @override
  String get buildModeLabel => 'Mode de compilation';

  @override
  String get appVersionLabel => 'Version';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageEnglish => 'English';
}
