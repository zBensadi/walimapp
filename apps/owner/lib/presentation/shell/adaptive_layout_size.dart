/// Viewport breakpoint classification for responsive navigation and layout chrome.
///
/// Follows standard Material 3 window size classes and FR-005:
/// - Compact (< 600dp): Phone layout with bottom NavigationBar
/// - Medium (600..1023dp): Tablet / medium desktop layout with NavigationRail
/// - Expanded (>= 1024dp): Large desktop monitor layout with extended NavigationRail
enum AdaptiveLayoutSize {
  compact,
  medium,
  expanded;

  /// Classifies layout size based on logical width in dp.
  static AdaptiveLayoutSize fromWidth(double widthDp) {
    if (widthDp < 600) {
      return AdaptiveLayoutSize.compact;
    }
    if (widthDp < 1024) {
      return AdaptiveLayoutSize.medium;
    }
    return AdaptiveLayoutSize.expanded;
  }

  bool get isCompact => this == AdaptiveLayoutSize.compact;
  bool get isMedium => this == AdaptiveLayoutSize.medium;
  bool get isExpanded => this == AdaptiveLayoutSize.expanded;

  bool get usesBottomNavigation => isCompact;
  bool get usesNavigationRail => !isCompact;
}
