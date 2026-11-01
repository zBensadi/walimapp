import 'package:flutter/material.dart';

import '../../application/app_locale_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/owner_platform_environment.dart';
import '../theme/owner_theme.dart';
import '../widgets/language_selector_card.dart';

/// Settings screen providing independent UI and document language selectors
/// and simple runtime environment diagnostics.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.localeController,
  });

  final AppLocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final env = OwnerPlatformEnvironment.current;

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final currentPref = localeController.currentPreference;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(OwnerTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settingsTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: OwnerTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: OwnerTheme.spacingMedium),

              // Language Preferences Section (F-07)
              Text(
                l10n.settingsLanguageSection,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: OwnerTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: OwnerTheme.spacingSmall),

              // UI Language Selector (language_pref)
              LanguageSelectorCard(
                title: l10n.uiLanguageLabel,
                description: l10n.settingsUiLanguageDesc,
                selectedLanguage: currentPref.uiLanguage,
                onLanguageSelected: (lang) {
                  localeController.setUiLanguage(lang);
                },
              ),
              const SizedBox(height: OwnerTheme.spacingMedium),

              // Document Language Selector (default_doc_lang)
              LanguageSelectorCard(
                title: l10n.documentLanguageLabel,
                description: l10n.settingsDocLanguageDesc,
                selectedLanguage: currentPref.defaultDocumentLanguage,
                onLanguageSelected: (lang) {
                  localeController.setDefaultDocumentLanguage(lang);
                },
              ),
              const SizedBox(height: OwnerTheme.spacingLarge),

              // Simple Build Diagnostics (no edition/license checks)
              Text(
                l10n.settingsDiagnosticsSection,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: OwnerTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: OwnerTheme.spacingSmall),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(OwnerTheme.spacingMedium),
                  child: Column(
                    children: [
                      _DiagnosticRow(
                        label: l10n.platformLabel,
                        value: env.platformName,
                      ),
                      const Divider(height: OwnerTheme.spacingLarge),
                      _DiagnosticRow(
                        label: l10n.buildModeLabel,
                        value: env.buildModeName,
                      ),
                      const Divider(height: OwnerTheme.spacingLarge),
                      _DiagnosticRow(
                        label: l10n.appVersionLabel,
                        value: env.appVersion,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: OwnerTheme.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: OwnerTheme.spacingSmall),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: OwnerTheme.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
