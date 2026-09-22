// `jabhouy_ui` exists to break a cycle: the app barrel exports the router,
// the router imports every feature, so a widget reached through the app
// barrel drags the whole feature graph behind it. That only holds while the
// package imports nothing from the app.
//
// Its pubspec does not list `jabhouy`, which looks like enough and is not:
// workspace members share one `package_config`, so a `package:jabhouy/...`
// import inside the package resolves and the analyzer stays quiet. The same
// softness `logic_layer_test.dart` was written for.
//
// `jabhouy_core` and `jabhouy_sync` do not need this file — they fail under
// `dart test` the moment they touch Flutter. `jabhouy_ui` is a Flutter
// package, so nothing fails on its own.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the package may not reach, however indirectly.
///
/// Every feature is a folder under `lib/`, so one prefix covers them all.
const _banned = {'package:jabhouy/'};

final _importPattern = RegExp(
  r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""",
  multiLine: true,
);

void main() {
  test('jabhouy_ui imports nothing from the app package', () {
    final files = Directory('packages/jabhouy_ui/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    expect(
      files,
      isNotEmpty,
      reason: 'no jabhouy_ui sources found — has the layout changed?',
    );

    final violations = <String>[];

    for (final file in files) {
      for (final match in _importPattern.allMatches(file.readAsStringSync())) {
        final uri = match.group(1)!;
        if (_banned.any(uri.startsWith)) {
          violations.add('${file.path}\n    imports $uri');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'jabhouy_ui must not depend on the app. What it needs from the '
          'app arrives as a port — see UiStrings.\n\n${violations.join('\n\n')}',
    );
  });
}
