import 'package:flutter/material.dart';

import '../../application/app_locale_controller.dart';
import '../../application/owner_shell_controller.dart';
import '../../core/formatting/western_numeral_formatter.dart';
import '../../domain/navigation/owner_nav_destination.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/owner_platform_environment.dart';
import '../theme/owner_theme.dart';

/// Foundational Dashboard/Home screen.
///
/// Displays welcoming overview, build/environment status, active language summary,
/// Western numeral formatted sample amount, and quick navigation actions per FR-004.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.localeController,
    required this.shellController,
  });

  final AppLocaleController localeController;
  final OwnerShellController shellController;

  static const int _sampleAmountDzd = 150000;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final env = OwnerPlatformEnvironment.current;

    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final currentPref = localeController.currentPreference;
        final formattedSampleAmount = WesternNumeralFormatter.formatCurrencyDzd(
          _sampleAmountDzd,
          language: currentPref.uiLanguage,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(OwnerTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                color: OwnerTheme.primaryBurgundy,
                child: Padding(
                  padding: const EdgeInsets.all(OwnerTheme.spacingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.dashboardWelcome,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: OwnerTheme.spacingSmall),
                      Text(
                        l10n.dashboardSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withAlpha(220),
                            ),
                      ),
                      const SizedBox(height: OwnerTheme.spacingMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OwnerTheme.spacingMedium,
                          vertical: OwnerTheme.spacingXSmall,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(OwnerTheme.radiusSmall),
                        ),
                        child: Text(
                          '${l10n.environmentStatus}: ${env.summary}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: OwnerTheme.spacingMedium),

              // Active Configuration Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(OwnerTheme.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SummaryRow(
                        label: l10n.uiLanguageLabel,
                        value: currentPref.uiLanguage.nativeName,
                      ),
                      const Divider(height: OwnerTheme.spacingLarge),
                      _SummaryRow(
                        label: l10n.documentLanguageLabel,
                        value: currentPref.defaultDocumentLanguage.nativeName,
                      ),
                      const Divider(height: OwnerTheme.spacingLarge),
                      _SummaryRow(
                        label: l10n.sampleAmountLabel,
                        value: formattedSampleAmount,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: OwnerTheme.spacingMedium),

              // Quick Actions
              Text(
                l10n.quickActions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: OwnerTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: OwnerTheme.spacingSmall),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.viewCalendar,
                      onTap: () {
                        shellController.selectDestination(
                          OwnerNavDestination.calendar,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: OwnerTheme.spacingMedium),
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.settings_outlined,
                      label: l10n.goToSettings,
                      onTap: () {
                        shellController.selectDestination(
                          OwnerNavDestination.settings,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: OwnerTheme.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OwnerTheme.radiusMedium),
      child: Container(
        height: OwnerTheme.minTouchTarget,
        decoration: BoxDecoration(
          color: OwnerTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(OwnerTheme.radiusMedium),
          border: Border.all(color: OwnerTheme.cardOutline),
        ),
        padding: const EdgeInsets.symmetric(horizontal: OwnerTheme.spacingSmall),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: OwnerTheme.primaryBurgundy),
            const SizedBox(width: OwnerTheme.spacingSmall),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: OwnerTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
