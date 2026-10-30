import 'package:flutter/foundation.dart';

import '../domain/navigation/owner_nav_destination.dart';

/// State management controller for the owner navigation shell.
///
/// Preserves the currently selected [OwnerNavDestination] across layout resizing,
/// device rotation, and runtime language changes per FR-006.
class OwnerShellController extends ChangeNotifier {
  OwnerShellController({
    OwnerNavDestination initialDestination = OwnerNavDestination.dashboard,
  }) : _currentDestination = initialDestination;

  OwnerNavDestination _currentDestination;

  OwnerNavDestination get currentDestination => _currentDestination;

  /// Selects a new destination, notifying listeners if changed.
  void selectDestination(OwnerNavDestination destination) {
    if (_currentDestination == destination) return;
    _currentDestination = destination;
    notifyListeners();
  }

  /// Selects a destination by its index (0..4).
  void selectIndex(int index) {
    selectDestination(OwnerNavDestination.fromIndex(index));
  }
}
