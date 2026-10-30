/// Pure-Dart domain enum representing top-level navigation destinations.
///
/// This file MUST NOT import Flutter UI packages (e.g. `package:flutter` or `dart:ui`).
library;

enum OwnerNavDestination {
  dashboard(id: 'dashboard'),
  calendar(id: 'calendar'),
  venues(id: 'venues'),
  finance(id: 'finance'),
  settings(id: 'settings');

  const OwnerNavDestination({
    required this.id,
  });

  final String id;

  /// Looks up destination by integer index (0..4), defaulting to [dashboard] if out of range.
  static OwnerNavDestination fromIndex(int index) {
    if (index >= 0 && index < OwnerNavDestination.values.length) {
      return OwnerNavDestination.values[index];
    }
    return OwnerNavDestination.dashboard;
  }

  /// Looks up destination by ID string, returning null if unmatched.
  static OwnerNavDestination? tryFromId(String? id) {
    if (id == null) return null;
    for (final dest in OwnerNavDestination.values) {
      if (dest.id == id) {
        return dest;
      }
    }
    return null;
  }
}
