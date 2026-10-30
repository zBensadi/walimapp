import 'package:flutter/material.dart';

import '../../application/app_locale_controller.dart';
import '../../application/owner_shell_controller.dart';
import '../../domain/navigation/owner_nav_destination.dart';
import '../../l10n/app_localizations.dart';
import '../screens/dashboard_screen.dart';
import '../screens/module_placeholder_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/owner_theme.dart';
import 'adaptive_layout_size.dart';

/// Responsive application shell adapting between bottom navigation bar and navigation rail.
///
/// Complies with FR-004, FR-005, FR-006, and FR-008:
/// - Compact (< 600dp): Bottom NavigationBar with concise labels and clamped text scaling
/// - Medium (600..1023dp): Leading-edge compact NavigationRail
/// - Expanded (>= 1024dp): Leading-edge extended NavigationRail with constrained workspace
class OwnerAdaptiveShell extends StatelessWidget {
  const OwnerAdaptiveShell({
    super.key,
    required this.localeController,
    required this.shellController,
  });

  final AppLocaleController localeController;
  final OwnerShellController shellController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: shellController,
      builder: (context, _) {
        final currentDestination = shellController.currentDestination;

        return LayoutBuilder(
          builder: (context, constraints) {
            final layoutSize = AdaptiveLayoutSize.fromWidth(constraints.maxWidth);

            return Scaffold(
              appBar: AppBar(
                title: Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: OwnerTheme.primaryBurgundy,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    color: OwnerTheme.cardOutline.withAlpha(120),
                    height: 1,
                  ),
                ),
              ),
              body: layoutSize.usesBottomNavigation
                  ? _buildWorkspace(currentDestination)
                  : Row(
                      children: [
                        _buildNavigationRail(
                          context,
                          l10n,
                          currentDestination,
                          isExtended: layoutSize.isExpanded,
                        ),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: OwnerTheme.cardOutline,
                        ),
                        Expanded(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: layoutSize.isExpanded ? 1200 : double.infinity,
                              ),
                              child: _buildWorkspace(currentDestination),
                            ),
                          ),
                        ),
                      ],
                    ),
              bottomNavigationBar: layoutSize.usesBottomNavigation
                  ? _buildBottomNavigationBar(context, l10n, currentDestination)
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildWorkspace(OwnerNavDestination destination) {
    return switch (destination) {
      OwnerNavDestination.dashboard => DashboardScreen(
          localeController: localeController,
          shellController: shellController,
        ),
      OwnerNavDestination.calendar => const ModulePlaceholderScreen(
          destination: OwnerNavDestination.calendar,
        ),
      OwnerNavDestination.venues => const ModulePlaceholderScreen(
          destination: OwnerNavDestination.venues,
        ),
      OwnerNavDestination.finance => const ModulePlaceholderScreen(
          destination: OwnerNavDestination.finance,
        ),
      OwnerNavDestination.settings => SettingsScreen(
          localeController: localeController,
        ),
    };
  }

  Widget _buildBottomNavigationBar(
    BuildContext context,
    AppLocalizations l10n,
    OwnerNavDestination currentDestination,
  ) {
    // Clamping text scale ensures 5 tabs fit cleanly down to 360dp without layout overflow
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: NavigationBar(
        selectedIndex: currentDestination.index,
        onDestinationSelected: shellController.selectIndex,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboardNav,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.calendarNav,
          ),
          NavigationDestination(
            icon: const Icon(Icons.domain_outlined),
            selectedIcon: const Icon(Icons.domain),
            label: l10n.venuesNav,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.financeNav,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsNav,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    AppLocalizations l10n,
    OwnerNavDestination currentDestination, {
    required bool isExtended,
  }) {
    return NavigationRail(
      selectedIndex: currentDestination.index,
      onDestinationSelected: shellController.selectIndex,
      extended: isExtended,
      minWidth: 72,
      minExtendedWidth: 220,
      labelType: isExtended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard),
          label: Text(isExtended ? l10n.dashboardTitle : l10n.dashboardNav),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.calendar_today_outlined),
          selectedIcon: const Icon(Icons.calendar_today),
          label: Text(isExtended ? l10n.calendarTitle : l10n.calendarNav),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.domain_outlined),
          selectedIcon: const Icon(Icons.domain),
          label: Text(isExtended ? l10n.venuesTitle : l10n.venuesNav),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet),
          label: Text(isExtended ? l10n.financeTitle : l10n.financeNav),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: Text(isExtended ? l10n.settingsTitle : l10n.settingsNav),
        ),
      ],
    );
  }
}
