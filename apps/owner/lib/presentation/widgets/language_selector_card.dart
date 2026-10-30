import 'package:flutter/material.dart';

import '../../domain/locale/supported_app_language.dart';
import '../theme/owner_theme.dart';

/// Reusable trilingual language selector card component.
///
/// Used for both UI language (`language_pref`) and default document language
/// (`default_doc_lang`) selection in Settings.
class LanguageSelectorCard extends StatelessWidget {
  const LanguageSelectorCard({
    super.key,
    required this.title,
    required this.description,
    required this.selectedLanguage,
    required this.onLanguageSelected,
  });

  final String title;
  final String description;
  final SupportedAppLanguage selectedLanguage;
  final ValueChanged<SupportedAppLanguage> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(OwnerTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: OwnerTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: OwnerTheme.spacingXSmall),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: OwnerTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: OwnerTheme.spacingMedium),
            Wrap(
              spacing: OwnerTheme.spacingSmall,
              runSpacing: OwnerTheme.spacingSmall,
              children: SupportedAppLanguage.values.map((lang) {
                final isSelected = lang == selectedLanguage;
                return _LanguageChip(
                  language: lang,
                  isSelected: isSelected,
                  onTap: () => onLanguageSelected(lang),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final SupportedAppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OwnerTheme.radiusMedium),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: OwnerTheme.minTouchTarget,
          minWidth: 100,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: OwnerTheme.spacingMedium,
          vertical: OwnerTheme.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? OwnerTheme.primaryBurgundy
              : OwnerTheme.surfaceWarmLight,
          borderRadius: BorderRadius.circular(OwnerTheme.radiusMedium),
          border: Border.all(
            color: isSelected
                ? OwnerTheme.primaryBurgundy
                : OwnerTheme.cardOutline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          language.nativeName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : OwnerTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
