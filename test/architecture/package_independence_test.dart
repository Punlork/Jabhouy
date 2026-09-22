// The packages exist to break a cycle: the app barrel exports the router,
// the router imports every feature, so a widget or a service reached
// through the app barrel drags the whole feature graph behind it. That
// only holds while no package imports the app.
//
// Their pubspecs do not list `jabhouy`, which looks like enough and is
// not: workspace members share one `package_config`, so a
// `package:jabhouy/...` import inside a package resolves and the analyzer
// stays quiet. The same softness `logic_layer_test.dart` was written for.
//
// `jabhouy_core` and `jabhouy_sync` are also covered by `dart test`, which
// fails the moment they touch Flutter. `jabhouy_ui` and `jabhouy_net` are
// Flutter packages, so nothing fails on their own.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every feature is a folder under `lib/`, so one prefix covers them all.
const _banned = 'package:jabhouy/';

const _packages = [
  'jabhouy_core',
  'jabhouy_net',
  'jabhouy_sync',
  'jabhouy_ui',
];

final _importPattern = RegExp(
  r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""",
  multiLine: true,
);

void main() {
  for (final package in _packages) {
    test('$package imports nothing from the app package', () {
      final files = Directory('packages/$package/lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      expect(
        files,
        isNotEmpty,
        reason: 'no $package sources found — has the layout changed?',
      );

      final violations = <String>[];

      for (final file in files) {
        for (final match
            in _importPattern.allMatches(file.readAsStringSync())) {
          final uri = match.group(1)!;
          if (uri.startsWith(_banned)) {
            violations.add('${file.path}\n    imports $uri');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            '$package must not depend on the app. What it needs from the '
            'app arrives as a port — see UiStrings and ImageUploader.'
            '\n\n${violations.join('\n\n')}',
      );
    });
  }
}
