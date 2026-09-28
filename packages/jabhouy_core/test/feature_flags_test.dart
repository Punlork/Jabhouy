// Runs under `dart test` with no defines, which is exactly the case the
// default exists for: a build that forgot its config file.
import 'package:jabhouy_core/jabhouy_core.dart';
import 'package:test/test.dart';

void main() {
  test('a build without defines ships every feature off', () {
    const flags = BuildTimeFeatureFlags();

    for (final feature in Feature.values) {
      expect(flags.isEnabled(feature), isFalse, reason: feature.name);
    }
  });

  test('fixed flags answer from their set', () {
    const flags = FixedFeatureFlags({Feature.income});

    expect(flags.isEnabled(Feature.income), isTrue);
    expect(const FixedFeatureFlags({}).isEnabled(Feature.income), isFalse);
    expect(FixedFeatureFlags.all().isEnabled(Feature.income), isTrue);
  });
}
