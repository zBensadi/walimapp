import 'package:flutter/material.dart';

import '../application/app_locale_controller.dart';
import '../application/owner_shell_controller.dart';
import '../l10n/app_localizations.dart';
import 'shell/owner_adaptive_shell.dart';
import 'theme/owner_theme.dart';

/// Root application widget for the WalimApp Owner application.
///
/// Configures MaterialApp with dynamic locale, trilingual AppLocalizations delegates,
/// responsive Directionality (RTL for Arabic, LTR for French/English), and OwnerTheme.
class WalimAppOwnerApp extends StatefulWidget {
  const WalimAppOwnerApp({
    super.key,
    required this.localeController,
    this.shellController,
  });

  final AppLocaleController localeController;
  final OwnerShellController? shellController;

  @override
  State<WalimAppOwnerApp> createState() => _WalimAppOwnerAppState();
}

class _WalimAppOwnerAppState extends State<WalimAppOwnerApp> {
  late final OwnerShellController _shellController;

  @override
  void initState() {
    super.initState();
    _shellController = widget.shellController ?? OwnerShellController();
  }

  @override
  void dispose() {
    if (widget.shellController == null) {
      _shellController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.localeController,
      builder: (context, _) {
        final currentUiLanguage = widget.localeController.uiLanguage;
        final isRtl = widget.localeController.isRtl;

        return MaterialApp(
          title: 'WalimApp Owner',
          debugShowCheckedModeBanner: false,
          theme: OwnerTheme.lightTheme(),
          locale: Locale(currentUiLanguage.languageCode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: OwnerAdaptiveShell(
            localeController: widget.localeController,
            shellController: _shellController,
          ),
        );
      },
    );
  }
}
