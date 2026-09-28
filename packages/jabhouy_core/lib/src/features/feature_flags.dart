/// A feature that can be switched off without deleting its code.
///
/// Adding one is three edits: a value here, a case in
/// [BuildTimeFeatureFlags.isEnabled] (the compiler refuses to build until
/// it exists), and a key in every `config/features/<flavor>.json`.
enum Feature {
  /// Bank-notification capture: the Income tab, the main/sub device role,
  /// notification diagnostics, and the Android notification listener.
  income,

  /// Saves return after the local write, and lists read only from Drift
  /// while the sync engine pushes and pulls in the background.
  /// docs/OFFLINE_SYNC.md.
  backgroundSync,
}

/// Answers whether a [Feature] is on.
///
/// Everything asks this interface, never `bool.fromEnvironment` directly,
/// so moving a flag to a runtime source such as Remote Config is a new
/// implementation registered in DI, not a hunt through call sites.
// ignore: one_member_abstracts — the seam is the point, not the member count.
abstract interface class FeatureFlags {
  bool isEnabled(Feature feature);
}

/// Flags fixed when the app is built, from `--dart-define-from-file`.
///
/// A missing define reads as `false`: a build that forgot its config file
/// hides unfinished work instead of shipping it.
final class BuildTimeFeatureFlags implements FeatureFlags {
  const BuildTimeFeatureFlags();

  @override
  bool isEnabled(Feature feature) => switch (feature) {
        // `bool.fromEnvironment` only works as a `const` with a literal
        // key, which is why each feature needs its own case.
        Feature.income => const bool.fromEnvironment('FEATURE_INCOME'),
        Feature.backgroundSync =>
          const bool.fromEnvironment('FEATURE_BACKGROUND_SYNC'),
      };
}

/// Flags given as a set, for tests and for previewing a combination.
final class FixedFeatureFlags implements FeatureFlags {
  const FixedFeatureFlags(this.enabled);

  /// Every feature on, which is what development builds ship.
  FixedFeatureFlags.all() : enabled = Feature.values.toSet();

  final Set<Feature> enabled;

  @override
  bool isEnabled(Feature feature) => enabled.contains(feature);
}
