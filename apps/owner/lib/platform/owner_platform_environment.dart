import 'package:flutter/foundation.dart';

/// Value object holding simple runtime environment diagnostics.
///
/// Contains strictly NO licensing, subscription, or Local vs Connect edition data.
class OwnerBuildEnvironmentInfo {
  const OwnerBuildEnvironmentInfo({
    required this.platformName,
    required this.buildModeName,
    required this.appVersion,
  });

  final String platformName;
  final String buildModeName;
  final String appVersion;

  String get summary => '$platformName • $buildModeName (v$appVersion)';
}

/// Thin platform adapter providing simple runtime diagnostics.
class OwnerPlatformEnvironment {
  const OwnerPlatformEnvironment._();

  static const String appVersion = '1.0.0+1';

  /// Resolves the current build and host platform environment.
  static OwnerBuildEnvironmentInfo get current {
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.fuchsia => 'Fuchsia',
    };

    final buildMode = kReleaseMode
        ? 'Release'
        : kProfileMode
            ? 'Profile'
            : 'Debug';

    return OwnerBuildEnvironmentInfo(
      platformName: platform,
      buildModeName: buildMode,
      appVersion: appVersion,
    );
  }
}
