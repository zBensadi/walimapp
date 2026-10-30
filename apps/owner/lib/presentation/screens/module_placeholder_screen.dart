import 'package:flutter/material.dart';

import '../../domain/navigation/owner_nav_destination.dart';
import '../../l10n/app_localizations.dart';
import '../theme/owner_theme.dart';

/// Reusable structured placeholder screen for future domain modules.
///
/// Used for Calendar, Venues & Halls, and Finance destinations per FR-004.
class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({
    super.key,
    required this.destination,
  });

  final OwnerNavDestination destination;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final (String title, String description, IconData icon) = switch (destination) {
      OwnerNavDestination.calendar => (
          l10n.calendarTitle,
          l10n.calendarPlaceholderDesc,
          Icons.calendar_month_outlined,
        ),
      OwnerNavDestination.venues => (
          l10n.venuesTitle,
          l10n.venuesPlaceholderDesc,
          Icons.domain_outlined,
        ),
      OwnerNavDestination.finance => (
          l10n.financeTitle,
          l10n.financePlaceholderDesc,
          Icons.account_balance_wallet_outlined,
        ),
      _ => (
          destination.id,
          '',
          Icons.dashboard_outlined,
        ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(OwnerTheme.spacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: OwnerTheme.textPrimary,
                ),
          ),
          const SizedBox(height: OwnerTheme.spacingLarge),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(OwnerTheme.spacingXLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: OwnerTheme.primaryBurgundy.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: OwnerTheme.primaryBurgundy,
                    ),
                  ),
                  const SizedBox(height: OwnerTheme.spacingMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OwnerTheme.spacingMedium,
                      vertical: OwnerTheme.spacingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: OwnerTheme.accentGold.withAlpha(30),
                      borderRadius: BorderRadius.circular(OwnerTheme.radiusSmall),
                      border: Border.all(color: OwnerTheme.accentGold),
                    ),
                    child: Text(
                      l10n.placeholderUpcoming,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: OwnerTheme.primaryBurgundy,
                      ),
                    ),
                  ),
                  const SizedBox(height: OwnerTheme.spacingMedium),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: OwnerTheme.textSecondary,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
